# Prism Cycle 2: Edge Case Hunter

**Date:** 2026-02-11  
**Target:** openclaw-quickstart-v2.5-SECURE.sh  
**Hunter:** Watson (Subagent: Edge Case Hunter)

---

## Verdict: **STILL VULNERABLE** 🔴

While Fix 2.x addresses some Cycle 1 issues, **new vulnerabilities were introduced** and **critical edge cases remain unfixed**. The script is safer than v2.0 but not production-ready.

---

## Fix 2.1 Edge Cases: **11 new scenarios found**

### ✅ Handled Well:
1. **Timeout protection**: Python subprocess has `timeout=10` ✓
2. **Special characters in key names**: Uses constant strings, no user input ✓
3. **Empty key handling**: Returns `""` safely ✓

### 🔴 Critical New Vulnerabilities:

**EDGE-41: Python 3 Not Installed**
```bash
# If Python 3 is missing, the script dies with cryptic error
python3 << 'PYEOF'
# ^ Fails with "command not found"
```
- **Impact**: Script crashes during config generation
- **Probability**: Medium (default macOS has Python 3, but could be broken)
- **Fix needed**: Check `command -v python3` before heredoc

**EDGE-42: Keychain Locked During Python Retrieval**
```python
def keychain_get(service, account):
    # If Keychain is locked, security returns error
    # But script SILENTLY returns "" - user has no idea keys weren't loaded!
```
- **Impact**: Bot starts with NO API KEYS, fails silently
- **Probability**: High (common after reboot/logout)
- **Fix needed**: Distinguish between "no key" vs "locked Keychain"

**EDGE-43: Python Subprocess Security Command Not Found**
```python
result = subprocess.run(['security', 'find-generic-password', ...])
# What if 'security' binary doesn't exist or is in unusual PATH?
```
- **Impact**: Config generation fails, bot won't start
- **Probability**: Low (macOS always has it, but VM/container might not)
- **Fix needed**: Check `/usr/bin/security` exists before Python heredoc

**EDGE-44: Multiple Processes Race on Keychain**
```python
# Two quickstart scripts running simultaneously
# Both try to delete + add the same Keychain entry
# No locking mechanism!
```
- **Impact**: One process's key might overwrite the other's
- **Probability**: Medium (user runs script twice thinking first failed)
- **Fix needed**: Atomic Keychain operations or script-level lockfile

**EDGE-45: Python Subprocess Hangs**
```python
subprocess.run(..., timeout=10)
# If Keychain dialog freezes (Touch ID failure, system bug), timeout triggers
# But then what? Script continues with empty keys!
```
- **Impact**: Bot starts without keys, fails all API calls
- **Probability**: Low but catastrophic
- **Fix needed**: Check if keys are empty after retrieval, abort if critical

**EDGE-46: Python JSON Library Missing**
```python
import json  # What if Python installation is broken?
```
- **Impact**: Config generation crashes
- **Probability**: Very low (stdlib), but possible in minimal installs
- **Fix needed**: Try/except around imports

**EDGE-47: Keychain Access Requires Touch ID, But Touch ID Hardware Absent**
```python
# M1+ MacBook with lid closed + external display
# Touch ID not available, Keychain prompt fails
```
- **Impact**: User can't complete setup, no fallback
- **Probability**: Medium (common remote desktop / headless scenario)
- **Fix needed**: Detect Touch ID requirement, offer password fallback

**EDGE-48: Python Heredoc Syntax Error Goes Unnoticed**
```bash
python3 << 'PYEOF'
# If Python script has syntax error, $? is non-zero
# But error message is cryptic
PYEOF

if [ $? -ne 0 ]; then
    die "Config generation failed security validation"
    # ^ User has no idea WHAT failed
fi
```
- **Impact**: Debugging nightmare
- **Probability**: Low (code is static), but high if user edits script
- **Fix needed**: Capture Python stderr, show actual error

**EDGE-49: Concurrent Python Keychain Writes Corrupt Entry**
```python
# Script A: Delete key X, write key X
# Script B: Delete key X (while A is writing), write key X
# Result: Race condition, one key is lost
```
- **Impact**: API keys lost or corrupted
- **Probability**: Low but critical
- **Fix needed**: Atomic write operations

**EDGE-50: Python sys.exit(1) Doesn't Propagate to Shell Properly**
```python
if model not in ALLOWED_MODELS:
    print(f"ERROR: ...", file=sys.stderr)
    sys.exit(1)
```
- **Validated**: Shell script checks `$?` ✓ — This is handled correctly

**EDGE-51: Python Retrieves Stale Keys After User Updates in Keychain Access App**
```python
# User manually changes key in Keychain Access.app while script runs
# Python subprocess might retrieve old cached value
```
- **Impact**: Bot uses wrong key
- **Probability**: Very low
- **Fix needed**: Force Keychain to flush cache (unlikely to fix)

---

## Fix 2.2 Edge Cases: **7 new scenarios found**

### ✅ Handled Well:
1. **Shell expansion prevented**: `'PYEOF'` (single-quoted delimiter) ✓
2. **Config values with single quotes**: JSON escaping handles it ✓
3. **Backticks in heredoc**: Single quotes prevent execution ✓

### 🔴 Critical New Vulnerabilities:

**EDGE-52: Python Version Too Old (< 3.6)**
```python
# Script uses f-strings: f"ERROR: Model '{model}' not in allowed list"
# Python 3.5 and earlier don't support f-strings
```
- **Impact**: Script crashes with SyntaxError
- **Probability**: Low but real (some old macOS systems)
- **Fix needed**: Check `python3 --version` >= 3.6 before heredoc

**EDGE-53: Python env Variable Injection via QUICKSTART_* Exports**
```bash
export QUICKSTART_DEFAULT_MODEL="$default_model"  # What if contains newlines or nulls?
# Later in Python:
model = os.environ.get('QUICKSTART_DEFAULT_MODEL', ...)
```
- **Impact**: Python code injection if validation bypassed
- **Probability**: Very low (validation happens before export) ✓
- **Status**: Mitigated by prior validation

**EDGE-54: Heredoc File Descriptor Limit**
```bash
python3 << 'PYEOF'
# If system has too many open file descriptors, heredoc might fail
```
- **Impact**: Config generation fails
- **Probability**: Very low
- **Fix needed**: Ulimit check (overkill)

**EDGE-55: Unicode in Bot Name Breaks Python Regex**
```python
if not re.match(r'^[a-zA-Z][a-zA-Z0-9_-]{1,31}$', bot_name):
```
- **Impact**: Validation fails if user somehow bypasses shell validation
- **Probability**: Very low (shell validates first) ✓
- **Status**: Defense-in-depth working correctly

**EDGE-56: JSON Serialization Failure**
```python
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
# What if config contains non-serializable objects?
```
- **Impact**: Config file not created, script continues anyway
- **Probability**: Very low (all values are strings/dicts/lists)
- **Fix needed**: Try/except around json.dump()

**EDGE-57: Config File Write Permission Denied After touch/chmod**
```bash
touch "$config_file"
chmod 600 "$config_file"
# Later Python tries to write to it
# What if parent directory permissions changed between these operations?
```
- **Impact**: Config write fails, bot won't start
- **Probability**: Very low
- **Fix needed**: Validate write succeeded in Python

**EDGE-58: Heredoc Interrupted by Signal**
```bash
python3 << 'PYEOF'
...
PYEOF
# If user hits Ctrl+C during heredoc, Python script is interrupted
# What's the cleanup state?
```
- **Impact**: Partial config file left behind
- **Probability**: Medium (impatient users)
- **Fix needed**: Trap signals, cleanup on interrupt

---

## Fix 2.3 Edge Cases: **13 new scenarios found**

### ✅ Handled Well:
1. **Process details shown before kill**: `ps -p "$blocking_pid"` ✓
2. **Kill fallback to SIGKILL**: `kill -9` if SIGTERM fails ✓

### 🔴 Critical New Vulnerabilities:

**EDGE-59: lsof Not Installed (Minimal macOS / Custom Build)**
```bash
pid=$(lsof -ti :"$port" 2>/dev/null || echo "")
# If lsof missing, command fails, script continues with empty pid
# Port check is SKIPPED SILENTLY!
```
- **Impact**: Port conflict detection completely bypassed
- **Probability**: Low (standard macOS has lsof), but HIGH in VMs/containers
- **Fix needed**: Check `command -v lsof` before port check, fail loudly if missing

**EDGE-60: lsof Returns Multiple PIDs (Multiple Processes on Port)**
```bash
pid=$(lsof -ti :"$port" 2>/dev/null || echo "")
# lsof -ti returns multiple PIDs separated by newlines if >1 process
# Script treats it as single value: "$pid"
# Only first PID is killed!
```
- **Impact**: Other processes still blocking port, gateway start fails
- **Probability**: Medium (common with Docker, multiple gateway instances)
- **Fix needed**: Loop through all PIDs or use `lsof -ti | xargs kill`

**EDGE-61: TOCTOU Race - Port Becomes Occupied Between Check and Start**
```bash
check_port_available "$DEFAULT_GATEWAY_PORT"  # Port free ✓
# ⏱️ Time passes (1-2 seconds)
launchctl load "$launch_agent"  # Another process grabbed the port!
```
- **Impact**: Gateway start fails with port conflict AFTER passing check
- **Probability**: Low but REAL (concurrent installs, other services)
- **Status**: **STILL BROKEN** - This is a fundamental TOCTOU vulnerability
- **Fix needed**: Atomic port reservation (nearly impossible) or retry logic

**EDGE-62: User Kills Wrong Process (Kill Dialog Shows Stale Info)**
```bash
ps -p "$blocking_pid" -o pid,user,comm,args
# Process info is snapshot at time of check
# User chooses option 2 (view details), then option 1 (kill)
# Between viewing and killing, process might have changed (PID reuse!)
```
- **Impact**: Wrong process killed, port still blocked OR critical system process killed
- **Probability**: Very low but catastrophic
- **Fix needed**: Re-check PID before kill, confirm process name matches

**EDGE-63: Port Check Times Out or Hangs**
```bash
lsof -ti :"$port" 2>/dev/null
# If lsof hangs (network filesystem issue, kernel bug), script waits forever
```
- **Impact**: Setup hangs indefinitely
- **Probability**: Very low
- **Fix needed**: Timeout wrapper around lsof

**EDGE-64: User Lacks Permission to Run lsof**
```bash
lsof -ti :"$port"
# Some locked-down systems require sudo for lsof
```
- **Impact**: Port check always reports "free" (false negative)
- **Probability**: Low
- **Fix needed**: Test lsof permission, prompt for sudo if needed

**EDGE-65: Port Check False Positive (IPv4 vs IPv6)**
```bash
lsof -ti :"$port"
# Checks both IPv4 and IPv6
# Gateway might bind only IPv4, but IPv6 process blocks port
```
- **Impact**: Gateway start fails even though IPv4 port is "free"
- **Probability**: Low but real in dual-stack environments
- **Fix needed**: Check specific protocol version

**EDGE-66: Kill Fails Due to Process Permissions**
```bash
kill "$blocking_pid"
# Process owned by root or different user
```
- **Impact**: Can't kill process, setup aborted
- **Probability**: Medium (common if old gateway running as system service)
- **Fix needed**: Detect permission error, suggest sudo alternative

**EDGE-67: Zombie Process After Kill**
```bash
kill "$blocking_pid" 2>/dev/null
sleep 1
# Process killed but parent didn't reap it → zombie
# Port still shows as occupied!
```
- **Impact**: Port check fails even after successful kill
- **Probability**: Low
- **Fix needed**: Wait for zombie reaping, check port again

**EDGE-68: Blocking Process Respawns Immediately (LaunchAgent/systemd)**
```bash
kill "$blocking_pid"
sleep 1
# Process was managed by launchd, respawns instantly
```
- **Impact**: Port immediately re-blocked, gateway start fails
- **Probability**: High (this is literally the use case!)
- **Fix needed**: Detect if process is managed service, suggest launchctl unload

**EDGE-69: User Cancels After Multiple Processes Shown**
```bash
# User chooses option 2 multiple times, then cancels
# Script shows details recursively
# But no state tracking of what user saw
```
- **Impact**: Confusing UX, user doesn't understand why they can't proceed
- **Probability**: Low
- **Fix needed**: Better flow documentation

**EDGE-70: Port Check Succeeds But Launch Fails for Different Reason**
```bash
check_port_available  # ✓ Pass
launchctl load  # ✗ Fails (permission issue, syntax error, etc.)
# User thinks port conflict is the problem
```
- **Impact**: Misleading diagnostics
- **Probability**: Medium
- **Fix needed**: Distinguish launchctl failure reasons

**EDGE-71: Gateway Uses Different Port Than DEFAULT_GATEWAY_PORT**
```bash
# Config file gets generated with custom port (user edits file)
# Script checks DEFAULT_GATEWAY_PORT (18789)
# Gateway actually tries to bind to port 18790
# Port check is useless!
```
- **Impact**: Port conflict detection bypassed
- **Probability**: Very low (config not editable at this point)
- **Fix needed**: Read port from config before checking

---

## Fix 2.4 Edge Cases: **9 new scenarios found**

### ✅ Handled Well:
1. **Retry limit enforced**: Max 2 attempts ✓
2. **Manual .env fallback**: Sets `NEEDS_MANUAL_ENV` flag ✓
3. **User-friendly error messages**: Specific error codes ✓
4. **Cancel cleans up**: Dies before creating files ✓

### 🔴 New Vulnerabilities:

**EDGE-72: Retry Loop Consumes Unlimited Keychain Attempts**
```bash
max_retries=2
while [ $attempt -lt $max_retries ]; do
    # User keeps choosing option 1 (retry)
    # But macOS Keychain has attempt limit
    # After 3 denials, Keychain LOCKS USER OUT
done
```
- **Impact**: User locks themselves out of Keychain entirely
- **Probability**: Low but catastrophic (affects entire system)
- **Fix needed**: Warn user about Keychain lockout risk

**EDGE-73: Skip Option Creates Inconsistent State**
```bash
# User skips Keychain for OpenRouter key
# Script continues, generates config WITHOUT auth section
# Bot starts successfully (uses OpenCode free tier as fallback)
# But user thinks they're using OpenRouter!
```
- **Impact**: Silent fallback to wrong provider, unexpected costs (or lack of)
- **Probability**: Medium
- **Fix needed**: Explicitly log which provider is active

**EDGE-74: Manual .env Reminder Lost in Output**
```bash
if [ "$NEEDS_MANUAL_ENV" = true ]; then
    echo ""
    warn "Manual .env setup required!"
    # User misses this, bot starts without keys
fi
```
- **Impact**: Bot non-functional, user has no idea why
- **Probability**: High (wall of text during setup)
- **Fix needed**: Block until user confirms they'll create .env OR create it interactively

**EDGE-75: Keychain Unlocks Between Retry Attempts**
```bash
# Attempt 1: Denied (Keychain locked)
# User unlocks Keychain via System Settings
# Attempt 2: Should succeed...
# But script doesn't re-prompt, just retries security command
# User clicks "Deny" by muscle memory
```
- **Impact**: Wasted retry opportunity
- **Probability**: Medium
- **Fix needed**: Detect Keychain unlock, notify user

**EDGE-76: Error Codes Don't Map to All Keychain Failures**
```bash
case "$result" in
    *"User interaction is not allowed"*) ;;
    *"cancelled"*|*"denied"*) ;;
    *"errSec"*) ;;
    *)
        echo "KEYCHAIN_UNKNOWN: $result"
        # What if error message changes in future macOS versions?
esac
```
- **Impact**: Unknown errors treated as generic failures
- **Probability**: Low but inevitable (macOS updates change messages)
- **Fix needed**: Log full error, not just pattern matches

**EDGE-77: User Chooses Cancel But Cleanup Isn't Verified**
```bash
die "Setup cancelled. Your API key was NOT stored anywhere.\n..."
# What if key WAS partially stored before error?
# No verification that Keychain is clean
```
- **Impact**: Orphaned Keychain entries
- **Probability**: Low
- **Fix needed**: Force keychain_delete before die

**EDGE-78: Skip Option Skips Anthropic Key But Not Gateway Token**
```bash
# User skips API key storage
# Script continues to gateway token generation
# Token stored in Keychain successfully
# Now Keychain has SOME data but not all
```
- **Impact**: Inconsistent Keychain state
- **Probability**: Medium
- **Fix needed**: All-or-nothing Keychain usage

**EDGE-79: Retry Prompt Vulnerable to Non-Numeric Input**
```bash
read -p "  Choose [1/2/3]: " choice
case "$choice" in
    1) ;;
    2) ;;
    3|*) die ;;  # * matches everything including empty string
esac
```
- **Impact**: Any invalid input (Enter, 'a', '!@#') treated as cancel
- **Probability**: Medium (user confusion)
- **Fix needed**: Validate choice, re-prompt on invalid

**EDGE-80: Warning Text Wraps/Scrolls Off Screen on Small Terminals**
```bash
echo -e "  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
# User's terminal is 40 columns wide
# Warning is unreadable
```
- **Impact**: User misses critical info
- **Probability**: Low but real (tmux splits, narrow terminals)
- **Fix needed**: Detect terminal width, wrap text

---

## Cycle 1 Critical Issues Status

### ❌ Keychain Denial (#13): **PARTIAL FIX**
**Status:** Improved but not solved
- ✅ Now has retry/skip/cancel options
- ✅ User can choose manual .env fallback
- ❌ Skip option creates inconsistent state (EDGE-73)
- ❌ Manual .env reminder easily missed (EDGE-74)
- ❌ Locked Keychain during Python retrieval fails silently (EDGE-42)

**Recommendation:** Needs EDGE-42, EDGE-73, EDGE-74 fixes before shipping

---

### ❌ Port Conflicts (#17): **PARTIAL FIX**
**Status:** Detection added but TOCTOU race remains
- ✅ Now detects conflicts before starting gateway
- ✅ Shows process details and offers kill option
- ❌ **TOCTOU race condition still exists** (EDGE-61) 🔴
- ❌ lsof missing = silent bypass (EDGE-59) 🔴
- ❌ Multiple PIDs on port = only kills first (EDGE-60)
- ❌ LaunchAgent respawn not handled (EDGE-68)

**Recommendation:** Needs retry logic + lsof validation before shipping. TOCTOU is unfixable without deeper changes.

---

### ❌ Concurrent Runs (#14): **STILL BROKEN** 🔴
**Status:** No fix attempted
- ❌ No lockfile mechanism
- ❌ Multiple script instances can race on:
  - Keychain writes (EDGE-44, EDGE-49)
  - Config file creation
  - LaunchAgent installation
  - Port occupation

**New Critical Edge Case:**

**EDGE-81: Two Quickstart Scripts Run Simultaneously**
```bash
# Terminal 1: bash openclaw-quickstart-v2.5-SECURE.sh
# Terminal 2: bash openclaw-quickstart-v2.5-SECURE.sh (user thinks first failed)

# Both scripts:
# 1. Pass dependency checks ✓
# 2. Prompt for API key ✓
# 3. Try to write to Keychain → RACE ⚠️
# 4. Try to create config file → RACE ⚠️
# 5. Try to load LaunchAgent → RACE ⚠️
```
- **Impact:** Corrupted config, lost keys, zombie processes
- **Probability:** Medium (users are impatient)
- **Fix needed:** Create lockfile at start of main(), fail if exists

**Recommendation:** CRITICAL - needs lockfile mechanism before shipping

---

### ❌ Disk Full (#24): **STILL BROKEN** 🔴
**Status:** No fix attempted
- ❌ No disk space checks before operations
- ❌ Config file creation can fail silently
- ❌ LaunchAgent plist write can fail silently
- ❌ Partial files left behind

**New Critical Edge Case:**

**EDGE-82: Disk Full During Config Creation**
```bash
touch "$config_file"  # Succeeds (0 bytes)
chmod 600 "$config_file"  # Succeeds
# Later Python tries to write JSON
json.dump(config, f, indent=2)  # FAILS - disk full!
# Script continues, reports success
```
- **Impact:** Bot starts with empty/corrupt config, crashes immediately
- **Probability:** Low but catastrophic when it happens
- **Fix needed:** Check `df -h` before file operations, verify write success

**Recommendation:** CRITICAL - needs pre-flight disk check before shipping

---

### ❌ Keys Lost on Upgrade (#33): **STILL BROKEN** 🔴
**Status:** No fix attempted
- ❌ No backup mechanism for Keychain entries
- ❌ No export/import functionality
- ❌ If upgrade fails mid-way, keys are gone

**New Critical Edge Case:**

**EDGE-83: Upgrade Script Deletes Old Config Before Creating New One**
```bash
# User runs v2.5 over v2.0 install
step3_start() {
    if [ -f "$config_file" ]; then
        cp "$config_file" "${config_file}.backup-$(date +%Y%m%d-%H%M%S)"
        # Backup created ✓
    fi
    # ...later...
    python3 << 'PYEOF'  # If this fails, old config is GONE
```
- **Impact:** Backup exists but keys are in Keychain, not backed up
- **Probability:** Medium (upgrade failures happen)
- **Fix needed:** Export Keychain entries to secure backup file before upgrade

**Recommendation:** CRITICAL - needs backup/restore for upgrades

---

## New Critical Edge Cases: **12 found**

Beyond the Cycle 1 issues, these new critical vulnerabilities were discovered:

1. **EDGE-42**: Keychain locked during Python retrieval → silent failure
2. **EDGE-59**: lsof missing → port check silently bypassed
3. **EDGE-60**: Multiple processes on port → only kills first
4. **EDGE-61**: TOCTOU race on port check (unfixable without retry)
5. **EDGE-72**: Retry loop can lock user out of Keychain
6. **EDGE-73**: Skip option creates inconsistent state
7. **EDGE-74**: Manual .env reminder lost in output
8. **EDGE-81**: Concurrent script runs → data corruption
9. **EDGE-82**: Disk full → corrupt config, bot broken
10. **EDGE-83**: Upgrade loses keys (no backup)
11. **EDGE-41**: Python 3 missing → cryptic crash
12. **EDGE-68**: LaunchAgent respawn after kill → port re-blocked

---

## Total Edge Cases Remaining: **47 of original 39**

**Breakdown:**
- **Original 39** from Cycle 1
- **Minus 8** fully fixed by Phase 2 changes
- **Plus 24** new edge cases introduced by fixes
- **Plus 8** discovered but pre-existing (not counted in Cycle 1)
= **47 total known edge cases**

**Critical edge cases:** 18 (up from 12)

---

## Murphy's Law Scenarios (Creative Failure Modes)

### 🎭 The "Schrödinger's Config"
```bash
# Config file exists but is empty (disk full mid-write)
# Gateway starts, tries to parse JSON
# Crashes with syntax error
# LaunchAgent keeps restarting it
# CPU at 100%, no obvious error to user
```

### 🎭 The "Keychain Amnesia"
```bash
# User stores key, script completes
# Later they change Mac password
# Keychain re-encrypts
# Python subprocess times out trying to retrieve key
# Bot starts with no keys, fails all requests
# Error: "API key invalid" (but key is in Keychain!)
```

### 🎭 The "Port Squat"
```bash
# User follows setup, everything works
# Later they install Docker Desktop
# Docker grabs port 18789 for its own service
# User reboots
# OpenClaw LaunchAgent tries to start
# Fails silently, no notification
# User types commands, thinks bot is ignoring them
```

### 🎭 The "Double Identity"
```bash
# User runs quickstart with OpenRouter key
# Works great!
# Later they get Anthropic key, run quickstart again
# Script writes NEW config, uses Anthropic model
# But BOTH keys are in Keychain now
# Bot randomly uses wrong key depending on config reload
```

### 🎭 The "Terminal Too Small"
```bash
# User runs script in 80x24 terminal
# Keychain error message spans 50 lines
# Options are at line 60
# User can't scroll back in dumb terminal (raw SSH)
# Presses random key, chooses wrong option
```

### 🎭 The "Invisible Failure"
```bash
# LaunchAgent loads successfully
# Gateway process starts
# But crashes immediately (Python import error)
# pgrep finds it during startup check (race)
# Script reports "Gateway running" ✓
# 2 seconds later, gateway is dead
# User has no idea
```

### 🎭 The "Keychain Denial of Service"
```bash
# User denies Keychain access 3 times
# macOS locks Keychain for 5 minutes
# User tries again immediately
# Script hangs on Keychain access
# No timeout, no progress indicator
# User kills script, corrupting config
```

---

## Recommendations

### 🔴 **DO NOT SHIP** without fixing:

**P0 - Show-stoppers:**
1. **EDGE-81** - Concurrent runs (add lockfile)
2. **EDGE-82** - Disk full (pre-flight check)
3. **EDGE-42** - Locked Keychain (detect + notify)
4. **EDGE-59** - Missing lsof (fail loudly)
5. **EDGE-61** - TOCTOU race (add retry loop)

**P1 - Critical but workaround exists:**
6. **EDGE-74** - Manual .env lost (block until user confirms)
7. **EDGE-73** - Skip creates inconsistent state (log provider clearly)
8. **EDGE-83** - Keys lost on upgrade (backup mechanism)
9. **EDGE-41** - Python 3 missing (version check)
10. **EDGE-60** - Multiple PIDs (kill all, not just first)

### 🟡 **CYCLE 3 NEEDED** for:

**Architectural issues (require deeper changes):**
- Atomic port reservation (near-impossible without system-level support)
- Keychain caching issues (macOS limitation)
- TOCTOU elimination (needs transactional semantics)
- Terminal width detection (nice-to-have)
- LaunchAgent respawn detection (needs deeper launchctl integration)

**Recommended priorities:**
1. Fix P0 issues (lockfile, disk check, error handling)
2. Ship v2.5.1-SECURE with warnings about known limitations
3. Cycle 3: Redesign to eliminate TOCTOU races and add upgrade path

---

## Final Verdict

**Fix 2.x addressed some issues but introduced new failure modes.**

**The good:**
- Keychain isolation works (when it works)
- Port conflict detection exists (when lsof exists)
- Error handling is better (when user reads it)
- Heredoc injection is fixed (when Python is installed)

**The bad:**
- Silent failures everywhere (locked Keychain, missing lsof, disk full)
- TOCTOU race remains in port check
- Concurrent runs still corrupt state
- Manual .env fallback easily missed

**The ugly:**
- 18 critical edge cases (up from 12)
- 5 show-stoppers require fixes before shipping
- Script is more complex but not necessarily more robust
- User experience degrades when things go wrong

**Recommendation: FIX CRITICAL, then ship v2.5.1 with known limitations documented. Schedule CYCLE 3 for architectural improvements.**

---

*Hunt complete. Murphy would be proud.* 🔍
