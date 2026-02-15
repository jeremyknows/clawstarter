# Phase 1.2: Command Injection Prevention

## Summary

**Status:** ✅ COMPLETE  
**Test Results:** 58/58 tests passed  
**Security Level:** Critical vulnerability patched

---

## Vulnerabilities Identified

### 1. Bot Name Injection (CRITICAL)
**Location:** Lines 209-211, 398-416 in original script

**Vulnerable Code:**
```bash
# User input collected without validation
custom_name=$(prompt "Bot name" "$bot_name")
bot_name="$custom_name"

# Later interpolated directly into heredoc WITHOUT quoting
cat > "$workspace_dir/AGENTS.md" << AGENTSEOF
# ${QUICKSTART_BOT_NAME}
You are ${QUICKSTART_BOT_NAME}, a helpful AI assistant.
...
AGENTSEOF
```

**Attack Vector:**
```bash
# Input: watson'; rm -rf /tmp/test; echo 'pwned
# Results in:
# ${QUICKSTART_BOT_NAME}
watson'; rm -rf /tmp/test; echo 'pwned
```

### 2. Model Selection Injection (HIGH)
**Location:** Lines 326-393 (Python heredoc)

**Vulnerable Pattern:**
- Model name passed as `sys.argv[1]` to Python
- No allowlist validation
- Arbitrary model strings accepted

**Attack Vector:**
```bash
# Input: sonnet"; import os; os.system("touch /tmp/pwned"); "
# Could be exploited if model name is ever interpolated
```

### 3. Menu Selection Injection (MEDIUM)
**Location:** Lines 224-232, 261-272

**Vulnerable Pattern:**
```bash
use_case_input=$(prompt "Choose (e.g., 1 or 1,2,3)" "4")
# Pattern matching without validation
[[ "$use_case_input" == *"1"* ]] && has_content=true
```

**Attack Vector:**
```bash
# Input: 1;rm -rf /
# While not directly dangerous here, violates input validation principles
```

### 4. Unquoted Heredocs (CRITICAL)
**Location:** Lines 398-416

**Vulnerable Code:**
```bash
cat > "$workspace_dir/AGENTS.md" << AGENTSEOF
# ${QUICKSTART_BOT_NAME}
...
AGENTSEOF
```

**Issue:** Unquoted heredoc marker (`AGENTSEOF`) allows shell expansion. Variables, command substitutions, and arithmetic expansions are processed.

---

## Fixes Applied

### 1. Input Validation Functions

Added comprehensive validation functions with defense in depth:

```bash
# Bot name: alphanumeric + hyphens/underscores only
validate_bot_name() {
    # Length check: 2-32 characters
    # Regex: ^[a-zA-Z][a-zA-Z0-9_-]*$
    # Blocklist: All shell metacharacters
}

# Model: strict allowlist
validate_model() {
    # Only accepts models from ALLOWED_MODELS array
}

# Menu selection: numeric only
validate_menu_selection() {
    # Regex: ^[0-9,]+$
    # Range validation against max value
}

# API key: no shell metacharacters
validate_api_key() {
    # Blocks: ' " ` $ ; | & > < ( ) { } [ ] \
}

# Security level: strict allowlist
validate_security_level() {
    # Only: low, medium, high
}
```

### 2. Strict Allowlists

```bash
readonly -a ALLOWED_MODELS=(
    "opencode/kimi-k2.5-free"
    "opencode/glm-4.7-free"
    "openrouter/moonshotai/kimi-k2.5"
    "openrouter/anthropic/claude-sonnet-4-5"
    "openrouter/anthropic/claude-opus-4"
    "openrouter/openai/gpt-4o"
    "openrouter/google/gemini-pro"
    "anthropic/claude-sonnet-4-5"
    "anthropic/claude-opus-4"
)

readonly -a ALLOWED_SECURITY_LEVELS=("low" "medium" "high")
readonly -a ALLOWED_PERSONALITIES=("casual" "professional" "direct")
```

### 3. Safe Heredoc Generation

**Before:**
```bash
cat > "$workspace_dir/AGENTS.md" << AGENTSEOF
# ${QUICKSTART_BOT_NAME}
You are ${QUICKSTART_BOT_NAME}...
AGENTSEOF
```

**After:**
```bash
# Template with placeholders
cat > "$workspace_dir/AGENTS.md.template" << 'AGENTSTEMPLATE'
# __BOT_NAME__
You are __BOT_NAME__...
AGENTSTEMPLATE

# Safe substitution with validated inputs
sed -e "s/__BOT_NAME__/${QUICKSTART_BOT_NAME}/g" \
    -e "s/__PERSONALITY__/${QUICKSTART_PERSONALITY}/g" \
    "$workspace_dir/AGENTS.md.template" > "$workspace_dir/AGENTS.md"
```

### 4. Python-Side Validation (Defense in Depth)

```python
# Double-validate in Python before config generation
ALLOWED_MODELS = [...]
ALLOWED_SECURITY_LEVELS = ["low", "medium", "high"]

if model not in ALLOWED_MODELS:
    sys.exit(1)

if not re.match(r'^[a-zA-Z][a-zA-Z0-9_-]{1,31}$', bot_name):
    sys.exit(1)

dangerous_chars = set("'\"`$;|&><(){}[]\\")
if any(c in dangerous_chars for c in openrouter_key):
    sys.exit(1)
```

### 5. Validated Prompts

```bash
# New helper that loops until valid input
prompt_validated() {
    local validator="$3"
    while true; do
        read -r response
        result=$($validator "$response")
        if [ "$result" = "OK" ]; then
            echo "$response"
            return 0
        else
            warn "$result"
        fi
    done
}

# Usage
bot_name=$(prompt_validated "Bot name" "$default" validate_bot_name)
```

---

## Test Results

### Injection Attempts (All Blocked) ✅

| Input | Type | Status |
|-------|------|--------|
| `watson'; rm -rf /tmp/test; echo 'pwned` | Shell injection | BLOCKED |
| `$(whoami)` | Command substitution | BLOCKED |
| `` `cat /etc/passwd` `` | Backtick execution | BLOCKED |
| `watson\|cat /etc/passwd` | Pipe injection | BLOCKED |
| `watson&whoami` | Background execution | BLOCKED |
| `watson>/tmp/pwned` | Redirect injection | BLOCKED |
| `watson${IFS}id` | Variable expansion | BLOCKED |
| `sonnet"; import os; os.system("id"); "` | Python injection | BLOCKED |

### Valid Inputs (All Allowed) ✅

| Input | Type | Status |
|-------|------|--------|
| `Watson` | Simple name | ALLOWED |
| `My-Bot` | Hyphenated name | ALLOWED |
| `Watson_AI` | Underscore name | ALLOWED |
| `Bot123` | Alphanumeric | ALLOWED |
| `1,2,3` | Multi-select | ALLOWED |
| `sk-or-abc123def456` | Valid API key | ALLOWED |

### Full Test Suite

```
━━━ TEST RESULTS ━━━
Passed: 58
Failed: 0

✓ ALL TESTS PASSED
```

---

## Acceptance Criteria Checklist

- [x] All injection attempts fail safely
- [x] Clear error message for invalid input
- [x] Alphanumeric validation on bot names
- [x] Strict allowlist for model selection
- [x] No use of `eval` or unescaped interpolation
- [x] Quoted heredocs where user input is involved
- [x] Defense in depth (validation in both shell and Python)
- [x] Test suite with 58 test cases

---

## Files Delivered

1. **`phase1-2-injection-prevention.sh`** - Security-hardened script (39.6 KB)
2. **`phase1-2-test-injection.sh`** - Comprehensive test suite (11.4 KB)
3. **`phase1-2-injection-prevention.md`** - This documentation

---

## Recommendations

1. **Deploy the fixed script** as `openclaw-quickstart-v2.sh`
2. **Run the test suite** after any future modifications
3. **Consider adding** a fuzzing step to CI/CD for edge cases
4. **Monitor** for new input vectors if script functionality expands
