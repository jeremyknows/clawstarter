# Edge Case Analysis: openclaw-quickstart-v2.sh

**Version Analyzed:** 2.3.0  
**Analysis Date:** 2026-02-11  
**Analyst Role:** Chaos Engineer / Edge Case Specialist

---

## Environment Assumptions

### Hard Dependencies (Assumed to Exist)
- ✅ **macOS** — Checked (line 113)
- ❌ **curl** — NOT checked, but used extensively (lines 162, 585)
- ❌ **Python 3** — NOT checked, but critical for config generation (line 556)
- ❌ **bash** — Assumed 4.0+ (`set -euo pipefail`)
- ❌ **launchctl** — Assumed present (lines 611-613)
- ❌ **Internet connection** — Never validated before use

### Soft Assumptions
- User has sudo access (Homebrew may prompt)
- `/tmp/` is writable (line 623)
- `$HOME` is set and writable
- User is interactive (uses `read` prompts)
- Terminal supports ANSI color codes
- Port 18789 is available
- User's shell sources Homebrew paths (lines 126-128)

### Critical Missing Checks
1. **No disk space validation** — Could fail mid-install
2. **No write permission checks** on `~/.openclaw/` before operations
3. **No Python version check** — Script uses Python 3 syntax
4. **No curl/wget availability** before attempting downloads

---

## Failure Modes

### 1. **Homebrew Installation Failure**
**Lines:** 122-128

**What can go wrong:**
- Homebrew install requires user interaction (password prompt)
- Script continues in `set -e` mode, dies on failure
- User on Apple Silicon vs Intel — path differs (`/opt/homebrew` vs `/usr/local`)
- Corporate networks block `raw.githubusercontent.com`
- Homebrew install script itself fails (upstream issue)

**Current handling:** Dies with `die "Homebrew installation failed"` — no cleanup, no retry.

**Missing:**
- No check if user has admin rights before attempting
- No alternative (e.g., "Install Homebrew manually and re-run")
- `eval "$(/opt/homebrew/bin/brew shellenv)"` only affects current script, NOT user's shell

---

### 2. **Node.js Version Conflict**
**Lines:** 133-149

**What can go wrong:**
- User has Node 18 via `nvm` (not via Homebrew)
- Script installs `node@22` via Homebrew → now two Nodes
- `brew link` fails if another Node is already linked
- PATH precedence issues — script sees v22, but user's shell sees v18
- `npm` might belong to different Node version

**Current handling:**
- Tries `brew link --overwrite` (line 145)
- Ignores link errors (`|| true`)
- Exports PATH only for script session

**Missing:**
- No warning about conflicting Node installations
- No check for `nvm`, `fnm`, `asdf` (version managers that shadow Homebrew)

---

### 3. **OpenClaw Install Failure**
**Lines:** 152-160

**What can go wrong:**
- `https://openclaw.ai/install.sh` returns 404 or 500
- Install script has bug
- Installer requires confirmation but script assumes non-interactive
- `$HOME/.openclaw/bin` not added to user's permanent PATH

**Current handling:** Dies with `die "OpenClaw installation failed"`

**Missing:**
- No retry mechanism
- PATH export only affects current session — user must manually add to `.zshrc`/`.bashrc`

---

### 4. **API Key Validation**
**Lines:** 287-294

**What can go wrong:**
- User pastes key with trailing whitespace → fails silently
- User pastes multi-line string by accident
- Key format detection is regex-based — could misidentify
- No actual API validation (doesn't test if key works)

**Current handling:** Basic string prefix matching

**Missing:**
- No `.strip()` or whitespace normalization
- No actual HTTP test to validate key
- Assumes `sk-or-*` = OpenRouter, but doesn't verify

---

### 5. **Network Dependency Hell**
**Lines:** Multiple (122, 162, 208, 585, etc.)

**What can go wrong:**
- Internet drops mid-install (Homebrew download, npm packages, OpenClaw script)
- DNS fails → `curl` hangs
- Firewall blocks GitHub/Homebrew/OpenRouter
- VPN interferes with localhost (dashboard won't open)
- Proxy required but not configured

**Current handling:** Fails with generic error

**Missing:**
- No pre-flight network check
- No timeout on `curl` commands
- No detection of proxy environment
- No retry logic

---

### 6. **Port Conflict**
**Lines:** 18, 611 (LaunchAgent config)

**What can go wrong:**
- Port 18789 already in use (another service, old OpenClaw instance)
- Gateway fails to bind, but LaunchAgent marks it as "running"
- `pgrep -f "openclaw"` (line 615) matches unrelated process

**Current handling:** None — assumes port is free

**Missing:**
- No `lsof -i :18789` check before starting
- No graceful port selection fallback
- `pgrep` is too broad (matches any process with "openclaw" in cmdline)

---

### 7. **Python Inline Script Failure**
**Lines:** 556-604

**What can go wrong:**
- Python 2 installed instead of Python 3 (`python3` command missing)
- Python missing `json` or `secrets` modules (very rare, but possible in minimal installs)
- Python subprocess inherits wrong environment variables
- Script writes config but Python crashes before printing token → user loses token
- File write fails due to permissions

**Current handling:** Wrapped in `set -e`, will die on Python error

**Missing:**
- No check for `python3` binary existence
- Token is printed to stdout (could be missed if user scrolls up)
- No config validation after Python writes it

---

### 8. **Skill Pack Re-Installation**
**Lines:** 441-577

**What can go wrong:**
- User runs script twice → duplicate content appended to `AGENTS.md`
- Check for `QUALITY_PACK_INSTALLED` (line 475) fails if file has different encoding
- `grep -q` returns 1 (not found) but script continues → duplicate sections
- `cat >> AGENTS.md` appends even if pack is "skipped"

**Current handling:** Grep-based duplicate detection (lines 475, 502, 526, 550)

**Issues:**
- Fragile comment-based detection (`<!-- PACK_INSTALLED -->`)
- If AGENTS.md is overwritten by template (line 585), pack markers disappear
- No idempotency guarantee

---

### 9. **LaunchAgent Conflicts**
**Lines:** 606-613

**What can go wrong:**
- Old `ai.openclaw.gateway.plist` exists with different config
- `launchctl load` fails if agent already loaded (handles with `|| true`)
- Agent starts but crashes immediately → `pgrep` check (line 615) races with startup
- Log file `/tmp/openclaw/gateway.log` directory doesn't exist

**Current handling:**
- Unloads before loading (line 612)
- 2-second sleep (line 614)

**Missing:**
- No `/tmp/openclaw/` directory creation
- No check if unload succeeded
- 2-second sleep is arbitrary — slow systems might need more

---

### 10. **Ctrl+C / SIGTERM During Execution**

**What can go wrong:**
- User presses Ctrl+C during Homebrew install → partial Homebrew state
- Interrupted during config write → corrupted JSON
- Interrupted during LaunchAgent creation → broken plist
- Interrupted during skill pack append → truncated AGENTS.md

**Current handling:** **NONE** — `set -e` doesn't catch signals

**Missing:**
- No trap handlers for `SIGINT`, `SIGTERM`
- No rollback/cleanup logic
- No "resume from step N" capability

---

## Partial State Issues

### If Script Exits at Various Points:

| Exit Point | State Left Behind | Can Re-Run? | Recovery Path |
|------------|-------------------|-------------|---------------|
| **Before step1_install** | Clean | ✅ Yes | Just re-run |
| **During Homebrew install** | Partial Homebrew | ⚠️ Maybe | Run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` manually |
| **During Node install** | Homebrew installed, no Node | ✅ Yes | Re-run (skips Homebrew) |
| **During OpenClaw install** | Homebrew + Node | ✅ Yes | Re-run (skips deps) |
| **After step2_configure** | No config written yet | ✅ Yes | Re-run |
| **During config write (Python)** | **CORRUPTED CONFIG** | ❌ No | Must delete `~/.openclaw/openclaw.json` manually |
| **During AGENTS.md write** | Partial template | ⚠️ Maybe | Delete `~/.openclaw/workspace/AGENTS.md`, re-run |
| **During skill pack append** | Duplicate content | ❌ No | Must manually edit AGENTS.md |
| **After LaunchAgent load** | Gateway running, partial config | ⚠️ Maybe | Must `launchctl unload`, delete config, re-run |

**Critical Issue:** No atomic operations — config/AGENTS.md can be left in broken state.

---

## Compatibility Matrix

### macOS Versions

| macOS Version | Expected Behavior | Issues |
|---------------|-------------------|--------|
| **Ventura (13.x)** | ✅ Should work | Homebrew paths vary by chip |
| **Sonoma (14.x)** | ✅ Should work | Current target |
| **Sequoia (15.x)** | ⚠️ Untested | May have launchctl changes |
| **Monterey (12.x)** | ⚠️ May work | Older bash, potential compat issues |
| **Big Sur (11.x)** | ❌ Likely fails | Homebrew path differences, older system Python |

**Missing:** No macOS version check (`sw_vers -productVersion`)

### Chip Types

| Chip | Homebrew Path | Script Handling |
|------|---------------|-----------------|
| **Apple Silicon (M1/M2/M3)** | `/opt/homebrew` | ✅ Detected (line 126) |
| **Intel** | `/usr/local` | ⚠️ Assumes Homebrew auto-paths |

**Issue:** Script only explicitly handles Apple Silicon path. Intel Macs rely on Homebrew's default PATH setup.

### Existing Software Conflicts

| Software | Conflict Type | Script Behavior |
|----------|---------------|-----------------|
| **nvm** | Node version manager | ⚠️ Installs duplicate Node, PATH collision |
| **fnm** | Node version manager | ⚠️ Same as nvm |
| **Docker Desktop** | Port conflicts possible | ❌ No check |
| **Another OpenClaw install** | Config overwrite, port conflict | ⚠️ Backs up config (line 542), but no port check |
| **Python 2 as default** | `python3` command missing | ❌ Script dies |

---

## Recovery Paths

### Scenario: Script Fails Mid-Install

**Can user re-run?** Depends on failure point (see Partial State table)

**Best practice for idempotency:**
1. ✅ Check if dependency already installed before installing
2. ❌ No cleanup of partial state (config, AGENTS.md, LaunchAgent)
3. ❌ No "resume from checkpoint" logic

### Scenario: Gateway Won't Start

**Current diagnostic:** "Check: tail /tmp/openclaw/gateway.log" (line 617)

**Missing:**
- No automatic log tail on failure
- No common error explanations (port in use, missing config, etc.)
- User must manually debug

### Scenario: Script Run Twice

**What happens:**
1. ✅ Config backed up (line 542)
2. ⚠️ Skill packs may duplicate (grep-based detection is fragile)
3. ⚠️ LaunchAgent replaced (old one unloaded)
4. ❌ No warning "OpenClaw already configured, are you sure?"

**Recovery:** Manual — delete duplicates from AGENTS.md, restore config from backup

---

## Missing Validations

### Pre-Flight Checks (Should Happen Before Prompting User)
1. ❌ **Internet connectivity** — `ping -c 1 8.8.8.8` or `curl -Is https://google.com`
2. ❌ **Disk space** — `df -h ~` (need at least 1GB for Node + deps)
3. ❌ **macOS version** — `sw_vers -productVersion` (warn if < 13.0)
4. ❌ **Required binaries** — `command -v curl python3`
5. ❌ **Port availability** — `lsof -i :18789`
6. ❌ **Admin rights** (for Homebrew) — `groups | grep -q admin`

### Input Validation
1. ⚠️ API key trimming (whitespace handling)
2. ❌ Bot name sanitization (what if user inputs emoji, slashes, etc.?)
3. ❌ Use case selection validation (script accepts invalid input, e.g., "99")
4. ❌ Setup type choice validation (same issue)

### Post-Install Validation
1. ❌ Config JSON syntax check (`python3 -m json.tool`)
2. ❌ Gateway health check (HTTP GET to `http://127.0.0.1:18789/health`)
3. ❌ Workspace file structure validation

---

## Stress Test Scenarios

### 10 Ways This Could Fail in the Wild

1. **Corporate Mac with MDM restrictions**
   - Homebrew install blocked by security policy
   - LaunchAgents disabled
   - Firewall blocks localhost ports
   - **Result:** Script fails at step 1 or step 3, user stuck

2. **User on slow/metered connection**
   - Homebrew download times out
   - Node install hangs for 10 minutes
   - User cancels mid-install (Ctrl+C)
   - **Result:** Partial state, no cleanup

3. **User already has OpenClaw v1 running**
   - Port 18789 occupied
   - Old config in place
   - Gateway process already running
   - **Result:** New gateway fails to start, old one broken

4. **Disk full during install**
   - Homebrew fails mid-download
   - Config write fails
   - Logs fill `/tmp`
   - **Result:** Cryptic error, no clear diagnostic

5. **Python 3 not in PATH**
   - macOS ships with Python 2.7 (older systems)
   - `python3` command doesn't exist
   - **Result:** Script dies with "command not found" at line 556

6. **User pastes API key from 1Password with extra newline**
   - Key stored as `"sk-or-abc123\n"`
   - OpenRouter rejects it (invalid format)
   - **Result:** Bot starts but can't make API calls, confusing error

7. **Network drops during template download**
   - curl (line 585) fails with timeout
   - AGENTS.md is empty or truncated
   - **Result:** Bot has no instructions, behaves erratically

8. **User runs script twice to "fix" an issue**
   - Skill packs appended twice to AGENTS.md (grep detection misses duplicates)
   - Multiple LaunchAgents loaded (actually just one, but confusing)
   - **Result:** Duplicate content, config replaced

9. **VPN interferes with localhost**
   - Dashboard at `127.0.0.1:18789` unreachable
   - Gateway running but inaccessible
   - **Result:** User thinks install failed, actually just network routing issue

10. **User has restrictive umask (e.g., 077)**
    - Config file created with 600 permissions (line 606) — OK
    - AGENTS.md created with no group/other read
    - LaunchAgent can't read config (if running as different user)
    - **Result:** Gateway crashes on startup

---

## Verdict

**Risk Level:** 🔴 **Medium-High Risk**  
**Confidence:** 90%

### Summary

This script is **well-structured** for the happy path but **brittle under stress**. Key issues:

#### 🔴 Critical
1. **No rollback mechanism** — Ctrl+C leaves system in unknown state
2. **No network validation** — Fails mysteriously on corporate/VPN networks
3. **No port conflict detection** — Gateway silently fails if port occupied
4. **No atomic config writes** — Partial JSON = broken system
5. **No Python version check** — Hard fails on older macOS

#### 🟡 High
6. **No disk space check** — Can fail mid-install
7. **No idempotency** — Running twice causes duplicates
8. **Weak input validation** — Accepts malformed data
9. **PATH export only in script** — User must manually add to shell

#### 🟢 Medium
10. **Generic error messages** — Hard to debug for non-technical users
11. **No retry logic** — Transient failures = script abort
12. **Assumption overload** — Assumes curl, python3, launchctl exist

### Recommendations for v2.4.0

**High Priority:**
1. Add pre-flight checklist (internet, disk, ports, binaries)
2. Implement trap handlers for cleanup on Ctrl+C
3. Add `--resume` flag for partial installs
4. Validate Python 3 availability before use
5. Check port 18789 before starting gateway

**Medium Priority:**
6. Atomic config writes (write to temp, validate, rename)
7. Whitespace trimming on API key input
8. Add `--dry-run` mode
9. Better error messages with recovery suggestions
10. Add skill pack removal logic (prevent duplicates)

**Would Be Nice:**
11. Colorized log output to file for debugging
12. `--uninstall` command to clean up
13. Health check endpoint validation
14. Auto-open logs on failure

### Final Thought

This script will work perfectly **80% of the time** (clean Mac, good internet, no existing conflicts). The other **20%** will be confused why it failed and have a partially broken system. Classic installer problem.

**Confidence in verdict:** 90% — I've seen these exact failure modes in production installers.
