# Prism Review: Edge Case Hunter

**Target:** `openclaw-quickstart-v2.4-SECURE.sh`  
**Reviewer:** Edge Case Hunter (Prism Subagent)  
**Date:** 2026-02-11  
**Focus:** Find every weird scenario where this could fail

---

## Verdict: VULNERABLE TO EDGE CASES

**Summary:** Strong security fixes but weak environmental resilience. Real-world deployment will hit multiple failure modes. The script handles malicious input well but handles unexpected environments poorly.

---

## Environment Edge Cases (12 found)

### 🔴 CRITICAL

**1. Keychain is locked**
- **Scenario:** User's Mac just booted, Keychain locked
- **Failure:** `security add-generic-password` prompts for password → blocks script
- **Impact:** Script hangs waiting for GUI password prompt in headless/SSH context
- **Evidence:** Line 134-140, no lock detection or `-T` flag for access control

**2. Keychain access denied (parental controls, MDM)**
- **Scenario:** Corporate Mac with restricted Keychain access
- **Failure:** `security` commands fail, script dies but keys might be partially stored
- **Impact:** Fatal error, no fallback

**3. Internet drops during template download**
- **Scenario:** WiFi flickers during `curl` in `verify_and_download_template()`
- **Failure:** Temp file left with partial data, SHA256 will catch corruption but no retry logic
- **Impact:** User sees "download failed," has to re-run entire script
- **Evidence:** Line 340, single-shot curl with no retry

**4. Disk full**
- **Scenario:** `/Users/username/.openclaw` writes fail mid-operation
- **Failure:** Config file created (touch) but write fails → 0-byte file with 600 perms
- **Impact:** OpenClaw thinks config exists but can't read it
- **Evidence:** Line 882 creates file, line 956 writes data — no space check between

### 🟡 MODERATE

**5. `$HOME` contains spaces (e.g., `/Users/John Doe`)**
- **Scenario:** User with space in username (older Macs allow this)
- **Failure:** `validate_home_path()` rejects it (line 476 requires `/Users/[a-zA-Z0-9_-]+`)
- **Impact:** Script refuses to run even though macOS supports spaces
- **Note:** Validation too strict

**6. `$HOME` is symlink or network mount**
- **Scenario:** `$HOME` points to NFS or SMB share
- **Failure:** LaunchAgent writes to symlink target, but paths in plist might break
- **Impact:** Gateway can't find workspace, fails at runtime
- **Evidence:** No `realpath` normalization

**7. macOS version doesn't support `security` command**
- **Scenario:** Pre-10.7 macOS (extremely old, but theoretically possible)
- **Failure:** Script assumes `security` exists
- **Impact:** Fatal error with cryptic message
- **Evidence:** No `command -v security` check

**8. Python 3 missing or broken**
- **Scenario:** User deleted Python, or Xcode CLI tools not installed
- **Failure:** Step 3 `python3 << PYEOF` silently fails or gives cryptic error
- **Impact:** Config file created but empty or malformed
- **Evidence:** Line 907, no `command -v python3` check

**9. `/tmp` is mounted noexec**
- **Scenario:** Security-hardened Mac with noexec on /tmp
- **Failure:** Temp files in `mktemp` can't execute (if script tries to)
- **Impact:** Likely OK (only data files), but untested
- **Evidence:** Line 336 creates temp file

### 🟢 LOW RISK

**10. `$PATH` doesn't include Homebrew**
- **Scenario:** User installed Homebrew but hasn't reloaded shell
- **Failure:** `brew` command not found after install (line 732)
- **Impact:** Script detects and runs `eval`, should be fine
- **Evidence:** Line 730-733, handled

**11. Multiple Homebrew installations (Intel + ARM)**
- **Scenario:** User has both `/opt/homebrew` and `/usr/local/bin/brew`
- **Failure:** Wrong Node.js version activated
- **Impact:** Version check might pass/fail unpredictably
- **Evidence:** No explicit Homebrew prefix check

**12. `shasum` vs `sha256sum` unavailable**
- **Scenario:** Minimal macOS install, no Xcode CLI tools
- **Failure:** Line 312-313 checks both, but if neither exists → error
- **Impact:** Template verification impossible
- **Evidence:** Error message exists (good) but no graceful fallback

---

## Interaction Edge Cases (11 found)

### 🔴 CRITICAL

**13. User cancels Keychain permission prompt**
- **Scenario:** macOS prompts "openclaw-quickstart wants to access Keychain," user clicks Deny
- **Failure:** `security add-generic-password` fails silently (exit code 1), script continues
- **Impact:** Keys never stored, config references Keychain but retrieval returns empty string
- **Evidence:** Line 135 has `2>/dev/null`, error suppressed
- **Why critical:** OpenClaw starts but can't authenticate to APIs → silent failure

**14. Script run twice simultaneously**
- **Scenario:** User opens two terminal windows, runs script in both
- **Failure:** Race condition on:
  - `$HOME/.openclaw/openclaw.json` (both write at once)
  - LaunchAgent load/unload (line 1135-1136)
  - Keychain writes (duplicate entries attempted)
- **Impact:** Corrupted config file, LaunchAgent loaded twice, undefined behavior
- **Evidence:** No lockfile, no PID check, no atomic writes

**15. User runs as root (`sudo bash script.sh`)**
- **Scenario:** User thinks it needs root (old habit)
- **Failure:** 
  - Creates `~/.openclaw` as root-owned
  - LaunchAgent fails (wrong user)
  - Keychain operations target root's Keychain
- **Impact:** Regular user can't access files, gateway won't start
- **Evidence:** No `[ "$EUID" -eq 0 ]` check

### 🟡 MODERATE

**16. Username with spaces in prompt input**
- **Scenario:** User types bot name "My Bot" with space
- **Failure:** Validation rejects (line 184), forces retry
- **Impact:** User confusion, but handled correctly
- **Note:** This is good validation, not a bug

**17. Port 18789 already in use**
- **Scenario:** Another service uses port 18789
- **Failure:** Gateway starts, binds fail, crashes
- **Impact:** Script reports success but gateway immediately exits
- **Evidence:** No `lsof -i :18789` check, no port availability test

**18. User Ctrl+C during `brew install`**
- **Scenario:** User gets impatient, cancels during Node.js install
- **Failure:** Partial Homebrew install, lock files left behind
- **Impact:** Next run might see `node` but it's broken
- **Evidence:** No trap handlers (`trap cleanup EXIT INT TERM`)

**19. User's shell is not bash/zsh (e.g., fish)**
- **Scenario:** User has non-POSIX shell as default
- **Failure:** `read -r` might behave differently, PATH manipulation might not persist
- **Impact:** Likely OK (script forces `bash` via shebang), but `read` prompt might break
- **Evidence:** Line 199 uses `read -r`, should work in bash but untested in fish

**20. User provides empty API key (presses Enter twice)**
- **Scenario:** Signup flow → user enters blank key → validation passes (line 582 allows empty)
- **Failure:** Empty string stored in Keychain, OpenClaw can't authenticate
- **Impact:** Bot starts but all API calls fail
- **Evidence:** Line 579 `validate_api_key ""` returns OK

### 🟢 LOW RISK

**21. User types `q` or `quit` instead of `N` for confirm()**
- **Scenario:** User expects `quit` to exit
- **Failure:** Treated as No, script aborts that step
- **Impact:** Minor UX issue
- **Evidence:** Line 283 only checks `[yY]`

**22. User's terminal doesn't support ANSI colors**
- **Scenario:** Old terminal or SSH session with `TERM=dumb`
- **Failure:** Color codes print as literal text
- **Impact:** Ugly but functional
- **Evidence:** No `tput` check

**23. User runs during macOS update**
- **Scenario:** System in middle of OS upgrade
- **Failure:** LaunchAgent registration might fail, Homebrew might be locked
- **Impact:** Unpredictable, but rare
- **Evidence:** No system state check

---

## Integration Edge Cases (9 found)

### 🔴 CRITICAL

**24. Keychain store succeeds but config write fails (disk full)**
- **Scenario:** Keychain write @ line 834, disk fills before Python script @ line 907
- **Failure:** Keys stored in Keychain, but `openclaw.json` missing or incomplete
- **Impact:** Inconsistent state — keys present but no config, hard to debug
- **Recovery:** User must manually delete Keychain entries or re-run will have duplicate keys
- **Evidence:** No transaction/rollback mechanism

**25. Template checksum in script is wrong (human error in TEMPLATE_CHECKSUMS)**
- **Scenario:** Maintainer fat-fingers checksum in line 92-99
- **Failure:** Script always rejects valid template download
- **Impact:** Installation impossible, error message blames network/file
- **Evidence:** No checksum-of-checksums or signature validation

**26. Python script passes validation but OpenClaw rejects config**
- **Scenario:** Python generates valid JSON but new OpenClaw version expects different schema
- **Failure:** Config written, gateway starts, immediately crashes with "invalid config"
- **Impact:** User sees "Gateway running" (line 1139) but it's already dead
- **Evidence:** No version compatibility check between script and OpenClaw binary

### 🟡 MODERATE

**27. Plist validates with `plutil` but LaunchAgent refuses to load**
- **Scenario:** `plutil -lint` passes (line 500), but `launchctl load` fails due to:
  - Binary path doesn't exist yet
  - Working directory permissions
  - Label conflict with old agent
- **Failure:** Script reports success but gateway not running
- **Impact:** False positive, hard to debug
- **Evidence:** Line 1135 `launchctl load` exit code not checked

**28. SHA256 verification passes but file encoding wrong**
- **Scenario:** Template downloaded with CRLF line endings instead of LF (Windows-style)
- **Failure:** Checksum matches (content identical), but script breaks on `#!/usr/bin/env`
- **Impact:** Rare, but possible with misconfigured CDN
- **Evidence:** No line-ending normalization

**29. `security find-generic-password` succeeds but returns empty string**
- **Scenario:** Keychain entry exists but access denied by policy
- **Failure:** `keychain_get()` returns "" (line 152), treated as "no key"
- **Impact:** OpenClaw thinks OpenCode free tier, but user expected OpenRouter
- **Evidence:** Line 152 `|| echo ""` masks errors

**30. Template download succeeds but cache write fails (permissions)**
- **Scenario:** `~/.openclaw/cache/templates` owned by root from previous bad run
- **Failure:** Line 352 `cp "$temp_file" "$cache_file"` fails, but destination write succeeds
- **Impact:** Template installed but not cached, re-downloads every time
- **Evidence:** No permission check on cache dir

### 🟢 LOW RISK

**31. Multiple templates selected, wrong one used**
- **Scenario:** User picks "1,2,3" → line 1071 uses first template for AGENTS.md
- **Failure:** Expected content-creator but got its AGENTS.md only
- **Impact:** Documented behavior (line 1094 says "from first"), but surprising
- **Evidence:** Not a bug, but UX confusion

**32. LaunchAgent plist has different settings from old install**
- **Scenario:** User ran script v2.3, now runs v2.4 with different WorkingDirectory
- **Failure:** `launchctl unload` removes old, `load` adds new, but process cache confused
- **Impact:** Might need manual `launchctl remove` or reboot
- **Evidence:** Line 1135, no forced reload

---

## Upgrade Path Edge Cases (7 found)

### 🔴 CRITICAL

**33. User has keys in old `.env` file**
- **Scenario:** Pre-v2.4 OpenClaw stored keys in `~/.openclaw/.env`
- **Failure:** Script never checks `.env`, keys lost, user must re-enter
- **Impact:** User expects upgrade to preserve keys, but they're orphaned
- **Evidence:** No `.env` detection or migration

**34. Old LaunchAgent has different Label**
- **Scenario:** v2.3 used `com.openclaw.gateway`, v2.4 uses `ai.openclaw.gateway`
- **Failure:** Old agent keeps running, new agent also loads → two gateways, port conflict
- **Impact:** Port 18789 taken, new gateway fails, old one still active
- **Evidence:** No cleanup of old labels

**35. Old Keychain entries use different service name**
- **Scenario:** v2.3 used `com.openclaw` service, v2.4 uses `ai.openclaw`
- **Failure:** Keys from old install not found, user must re-enter
- **Impact:** Duplicate keys in Keychain, confusing
- **Evidence:** Line 26-29 hardcoded service name, no backward compat

### 🟡 MODERATE

**36. Backup config exists but not referenced**
- **Scenario:** Line 863 backs up config to `.backup-TIMESTAMP`
- **Failure:** Backup created but user never told where it is or how to restore
- **Impact:** Safety net exists but undiscoverable
- **Evidence:** `info "Backed up..."` but no restore instructions

**37. Old config has `provider` key not in new template**
- **Scenario:** Old config has custom provider settings, backup made, new config overwrites
- **Failure:** Custom settings lost, user must manually merge
- **Impact:** Advanced users lose customizations
- **Evidence:** No config merging, pure overwrite at line 907

**38. Workspace files modified by user**
- **Scenario:** User edited `AGENTS.md`, script re-runs and overwrites with template
- **Failure:** Line 1073 `verify_and_download_template` → overwrites existing file
- **Impact:** User loses custom instructions
- **Evidence:** No `[ -f "$workspace_dir/AGENTS.md" ]` check before download

### 🟢 LOW RISK

**39. Old tmux socket from previous OpenClaw install**
- **Scenario:** `/tmp/openclaw-tmux-sockets/` has stale sockets
- **Failure:** Not directly script's fault, but might confuse new install
- **Impact:** Low — OpenClaw should handle
- **Evidence:** Outside script scope, but no cleanup

---

## Original Issues - Status

From the original edge case review, checking if these were fixed:

### ✅ FIXED
- **Injection attacks** — Fully addressed with input validation and allowlists
- **API key exposure** — Now in Keychain, not environment

### ⚠️ PARTIALLY FIXED
- **Non-idempotent** — Better (backs up config), but still issues:
  - Keychain entries can duplicate (line 135 deletes then adds, but if delete fails?)
  - Template downloads overwrite without checking
  - LaunchAgent load is idempotent, but label conflicts not handled

### ❌ STILL BROKEN
- **No Ctrl+C cleanup** — Still no trap handlers
  - Temp files left behind (line 336 `mktemp`)
  - Partial Keychain writes
  - Partial config writes
  
- **No network validation** — Still no connectivity check before downloads
  - Assumes `curl` will succeed
  - No retry logic
  - No timeout handling

- **Port conflicts unchecked** — Port 18789 never tested for availability
  - Gateway fails at runtime, not during setup
  - Error message is cryptic (check /tmp logs)

---

## Most Likely Real-World Failures

**Top 5 scenarios that WILL happen in production:**

1. **🔴 User cancels Keychain prompt (#13)**  
   **Probability:** HIGH  
   **Impact:** Silent failure, bot starts but can't authenticate  
   **User sees:** "Bot works but won't respond to API calls"  
   **Fix:** Check `security` exit codes, prompt user to retry

2. **🔴 Port 18789 already in use (#17)**  
   **Probability:** MEDIUM-HIGH (previous install, other service)  
   **Impact:** Gateway crashes immediately after "successful" setup  
   **User sees:** "Script says done, but dashboard won't load"  
   **Fix:** Add port availability check with `lsof`

3. **🔴 Script run twice simultaneously (#14)**  
   **Probability:** MEDIUM (impatient user opens two terminals)  
   **Impact:** Corrupted config file, duplicate Keychain entries  
   **User sees:** "Config is gibberish" or "multiple API keys found"  
   **Fix:** Add lockfile (`~/.openclaw/.setup.lock`)

4. **🟡 Internet drops during template download (#3)**  
   **Probability:** MEDIUM (WiFi, VPN flicker)  
   **Impact:** Setup fails, user must re-run entire script (5 min lost)  
   **User sees:** "Download failed, start over"  
   **Fix:** Add retry logic with exponential backoff

5. **🟡 Upgrade from old version, keys lost (#33)**  
   **Probability:** MEDIUM (all v2.3 users upgrading)  
   **Impact:** User must find old `.env` and re-enter keys manually  
   **User sees:** "My API key is gone after upgrade"  
   **Fix:** Add `.env` detection and migration

---

## Recommendation

### Verdict: **SHIP WITH WARNINGS + HOTFIX PLAN**

**Why ship:**
- Security fixes are solid (injection, validation, Keychain)
- Core functionality works for happy path
- Edge cases are... edges (not common path)

**Why NOT ship as-is:**
- #13 (Keychain denial) is nearly guaranteed to hit someone
- #17 (port conflict) will cause confusion for upgrades
- #14 (concurrent runs) is a data corruption risk

### Minimal Viable Fixes (30 min implementation)

Add these **preflight checks** before any mutations:

```bash
# At start of main()
if [ -f "$HOME/.openclaw/.setup.lock" ]; then
    die "Setup already running (lockfile exists). Wait or remove ~/.openclaw/.setup.lock"
fi
trap "rm -f $HOME/.openclaw/.setup.lock" EXIT INT TERM
touch "$HOME/.openclaw/.setup.lock"

# Before step1_install
if ! ping -c1 -W2 google.com &>/dev/null; then
    warn "No internet detected. Download steps may fail."
    confirm "Continue anyway?" || exit 0
fi

# Before step3_start (port check)
if lsof -i :18789 &>/dev/null; then
    warn "Port 18789 already in use. Gateway may fail to start."
    if confirm "Kill existing process?"; then
        lsof -ti :18789 | xargs kill -9 2>/dev/null
    fi
fi

# After keychain_store calls
if ! keychain_exists "$KEYCHAIN_ACCOUNT_OPENROUTER" && [ "$provider" = "openrouter" ]; then
    die "Failed to store OpenRouter key in Keychain. Check access permissions."
fi
```

### Recommended Additions (for v2.5)

1. **Upgrade path:** Detect `.env`, migrate keys to Keychain
2. **Retry logic:** Template downloads with 3 attempts
3. **Root check:** Exit if `$EUID == 0`
4. **Disk space check:** Before creating `~/.openclaw`
5. **Validation:** Check `security` command exists before use

### Critical Gaps

None that prevent shipping, but:
- **Keychain denial** will cause support tickets (add better error message)
- **Port conflicts** need handling (auto-kill or prompt)
- **Documentation:** Add troubleshooting guide for "gateway won't start" and "API calls fail"

---

## Appendix: Testing Checklist

To validate fixes, test these scenarios:

- [ ] Run with Keychain locked (trigger password prompt)
- [ ] Run with port 18789 in use (`nc -l 18789` in another terminal)
- [ ] Run twice simultaneously in separate terminals
- [ ] Run with no internet (`sudo pfctl -d` on macOS)
- [ ] Run as root (`sudo bash script.sh`)
- [ ] Run with `$HOME` containing spaces (create test user)
- [ ] Cancel Keychain prompt when asked for permission
- [ ] Upgrade from v2.3 with existing `.env` file
- [ ] Fill disk to 99% before running (create large file)
- [ ] Run with Python 3 uninstalled

---

**End of Edge Case Hunt**

*Think like a user who hits every weird scenario. ✅ Mission accomplished.*
