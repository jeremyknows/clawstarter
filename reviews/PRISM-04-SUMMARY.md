# PRISM Review #4: Executive Summary

**Review:** Script Hardening (Performance + Reliability)  
**Reviewer:** Watson (Subagent)  
**Date:** 2026-02-15 02:30 EST  
**Status:** ⚠️ **APPROVE WITH CRITICAL FIX REQUIRED**

---

## TL;DR

**The script is EXCELLENT** — best-in-class security, comprehensive error handling, bash 3.2 compatible.

**BUT:** One critical stdin handling bug breaks piped execution (`curl | bash`).

**The fix:** 12 lines of code (pattern already exists in script, just needs copying).

**Timeline:**
- **Apply stdin fix:** 15 minutes
- **Test verification:** 30 minutes
- **Ready for distribution:** 45 minutes total

---

## Critical Issues

### 🔴 BLOCKER: stdin/TTY Handling

**Impact:** Piped execution (`curl https://... | bash`) will fail  
**Root Cause:** `prompt()` and `prompt_validated()` read from stdin without `/dev/tty` fallback  
**Fix Complexity:** LOW (10 lines, proven pattern)  
**Fix Location:** `fixes/stdin-tty-fix.patch`

**Symptom:**
```bash
# This fails:
curl https://example.com/openclaw-quickstart-v2.sh | bash

# User hits Enter → script consumes its own source code as input
# Result: Silent exit or garbage validation errors
```

**The Fix:**
```bash
# Copy this pattern from confirm() to prompt() and prompt_validated():
if [ -t 0 ]; then
    read -r response
else
    read -r response < /dev/tty 2>/dev/null || response=""
fi
```

---

## High Priority Issues

### 🟡 SECURITY: Template Checksums Disabled

**Impact:** MITM attacks on template downloads won't be detected  
**Root Cause:** Checksums disabled citing "bash 3.2 compat" but `shasum -a 256` works on all macOS  
**Fix Complexity:** MEDIUM (50 lines, needs checksum generation)  
**Fix Location:** `fixes/re-enable-checksums.sh`

**Risk:**
- Compromised GitHub account could serve malicious AGENTS.md
- AGENTS.md controls AI agent behavior (high value target)
- HTTPS provides some protection, but checksums add defense-in-depth

**Timeline:** Can ship closed beta without this, MUST fix before public beta

---

## What's Excellent

### ✅ Security Hardening (Best-in-Class)

**Phase 1-3 fixes applied:**
- ✅ Keychain isolation (keys never in environment)
- ✅ Input validation with allowlists
- ✅ Secure file creation (no race conditions)
- ✅ Plist injection protection
- ✅ Port conflict detection
- ✅ Disk space pre-flight check
- ✅ Locked Keychain retry logic

**Security overhead:** <1% (2 seconds in 5-minute install)

---

### ✅ Error Handling (Comprehensive)

**What's handled:**
- Disk full (pre-flight check)
- Network failure (graceful with error messages)
- Keychain locked (retry with timeout)
- Port conflicts (detect + offer to kill)
- Homebrew/Node failures (clear error messages)

**What's NOT handled:**
- `/dev/tty` unavailable (minor edge case)
- LaunchAgent startup edge cases (partial handling)

---

### ✅ Bash 3.2 Compatibility (Verified)

**Status:** Fully compatible, no blockers

**Identified patterns:**
- `[[ ... ]] && command` — Works in bash 3.2 (style issue, not bug)
- `read -ra` — Works (could be more explicit)
- `((x++)) || true` — Correct pattern for `set -e`

**No associative arrays, bash 4+ features, or incompatible syntax used.**

---

### ✅ Performance (Excellent)

**Runtime:** ~5 minutes (well-optimized)

**Breakdown:**
- Node.js install: 2-3 min (60%)
- User input: 1-2 min (30%)
- Everything else: <30s (10%)

**Security overhead:** <1%

**Optimization potential:** ~1-2 min (if Node.js binary caching added)

**Verdict:** No performance fixes needed — script is already fast

---

## Deliverables Created

### 1. Main Review Document
**Location:** `reviews/prism-04-script-hardening.md` (40 KB)

**Contents:**
- Complete bash 3.2 compatibility analysis
- stdin/TTY bug deep-dive
- Edge case catalog (disk full, network, Keychain, etc.)
- Test matrix (6 OS configs × 4 execution methods)
- Performance analysis
- Recommendations

---

### 2. Critical Fix: stdin/TTY Patch
**Location:** `fixes/stdin-tty-fix.patch` (executable)

**What it does:**
- Adds `/dev/tty` fallback to `prompt()` and `prompt_validated()`
- Creates backup before modification
- Verifies syntax after applying
- Provides rollback instructions

**Apply with:**
```bash
cd ~/.openclaw/apps/clawstarter
bash fixes/stdin-tty-fix.patch
```

---

### 3. Verification Test Suite
**Location:** `fixes/test-stdin-fix.sh` (executable)

**Tests:**
- Syntax validation
- Verify `prompt()` has fix
- Verify `prompt_validated()` has fix
- Check for unprotected `read` statements
- Manual test instructions

**Run with:**
```bash
bash fixes/test-stdin-fix.sh
```

---

### 4. Checksum Re-enablement Script
**Location:** `fixes/re-enable-checksums.sh` (executable)

**What it does:**
- Generates bash 3.2 compatible checksum lookup function
- Creates case statement (no associative arrays)
- Generates actual checksums for templates
- Provides integration instructions

**Run with:**
```bash
bash fixes/re-enable-checksums.sh
```

---

### 5. Bash 3.2 Compatibility Checklist
**Location:** `fixes/bash32-compat-checklist.md`

**Contents:**
- Compatible features (what's safe)
- Use-with-caution patterns (style issues)
- Incompatible features (what to avoid)
- Verification steps
- Common gotchas

---

## Test Plan Summary

### Minimum Critical Path (15 minutes)

```bash
# 1. Syntax check
bash -n openclaw-quickstart-v2.sh

# 2. Direct execution
bash openclaw-quickstart-v2.sh

# 3. Piped execution (CRITICAL)
cat openclaw-quickstart-v2.sh | bash

# 4. Input validation
echo -e "'; rm -rf\n\n\n" | bash openclaw-quickstart-v2.sh

# 5. Keychain isolation
ps e | grep openclaw | grep -i "sk-"  # Should be empty
```

---

### Full Test Matrix (70 minutes)

**OS Coverage:**
- macOS 13 Ventura (Intel + Apple Silicon)
- macOS 14 Sonoma (Intel + Apple Silicon)
- macOS 15 Sequoia (Intel + Apple Silicon)

**Execution Contexts:**
- Direct: `bash script.sh`
- Piped: `cat script.sh | bash`
- Auto-accept: `bash script.sh -y`
- Non-interactive: `echo "" | bash script.sh`

**Edge Cases:**
- Port 18789 blocked
- Keychain locked
- Low disk space (<500MB)
- No internet connection

---

## Release Checklist

### ✅ Before Closed Beta (MUST DO)

- [ ] Apply stdin/TTY fix (`fixes/stdin-tty-fix.patch`)
- [ ] Test piped execution: `cat script.sh | bash`
- [ ] Test direct execution: `bash script.sh`
- [ ] Verify no regressions in normal flow
- [ ] Syntax check passes: `bash -n script.sh`

**ETA:** 45 minutes

---

### ✅ Before Public Beta (SHOULD DO)

- [ ] Re-enable template checksums (`fixes/re-enable-checksums.sh`)
- [ ] Generate fresh checksums for all templates
- [ ] Test checksum verification (valid + tampered)
- [ ] Full OS matrix testing (6 configurations)
- [ ] Security validation (no keys in `ps e`)

**ETA:** 4-6 hours (including manual testing across OS versions)

---

## Recommendations

### Immediate (Now)

1. **Apply stdin/TTY fix** — 15 minutes
   ```bash
   cd ~/.openclaw/apps/clawstarter
   bash fixes/stdin-tty-fix.patch
   bash fixes/test-stdin-fix.sh
   ```

2. **Test piped execution** — 5 minutes
   ```bash
   cat openclaw-quickstart-v2.sh | bash
   # Verify prompts work
   ```

3. **Commit and deploy** — Ready for closed beta

---

### Short Term (This Week)

1. **Re-enable checksums** — 2 hours
   - Run `fixes/re-enable-checksums.sh`
   - Generate real checksums
   - Integrate into script
   - Test verification

2. **Full test matrix** — 4 hours
   - Test on macOS 13-15
   - Both architectures (Intel + Apple Silicon)
   - All execution contexts

3. **Documentation** — 1 hour
   - Update README with piped execution notes
   - Add security documentation
   - Document test procedures

---

### Long Term (Before Public Beta)

1. Enhanced error handling
   - `/dev/tty` unavailable fallback
   - Better LaunchAgent startup verification
   - Network retry logic

2. Style cleanup
   - Refactor `[[ ... ]] &&` to `if` statements
   - Explicit IFS handling
   - Add bash 3.2 compatibility comments

3. Monitoring and telemetry
   - Track installation success/failure rates
   - Common error scenarios
   - Performance metrics

---

## Final Verdict

**Quality:** ⭐⭐⭐⭐⭐ Excellent  
**Security:** ⭐⭐⭐⭐⭐ Best-in-class  
**Reliability:** ⭐⭐⭐⭐☆ Very good (one stdin bug)  
**Compatibility:** ⭐⭐⭐⭐⭐ Fully bash 3.2 compatible  
**Performance:** ⭐⭐⭐⭐⭐ Well-optimized

**Blocker Issues:** 1 (stdin handling)  
**Security Regressions:** 1 (checksums disabled)

**Release Status:**
- ❌ NOT READY: Piped execution broken
- ✅ READY (after stdin fix): Closed beta (<50 technical users)
- ⚠️ READY (after checksums): Public beta

**Timeline to Ship:**
- **Closed beta:** 45 minutes (apply stdin fix + test)
- **Public beta:** 1 week (checksums + full test matrix)

---

## Questions Answered

### 1. List ALL bash 3.2 incompatibilities

**Answer:** NONE that are bugs. See `bash32-compat-checklist.md` for style issues.

---

### 2. What's the complete stdin/TTY fix?

**Answer:** 3 functions need `/dev/tty` handling:
- `prompt()` — NEEDS FIX
- `prompt_validated()` — NEEDS FIX
- `confirm()` — ALREADY FIXED ✅

See `stdin-tty-fix.patch` for complete implementation.

---

### 3. How do we re-enable template checksums?

**Answer:** Use `shasum -a 256` (works on all macOS) with case statement (no associative arrays).

See `re-enable-checksums.sh` for bash 3.2 compatible implementation.

---

### 4. What edge cases could crash the script?

**Answer:** Handled well:
- ✅ Disk full (pre-flight check)
- ✅ Keychain locked (retry loop)
- ✅ Port conflict (detect + kill)
- ✅ Homebrew/Node fail (error messages)

Partial handling:
- ⚠️ Network timeout (basic retry)
- ⚠️ LaunchAgent fails (basic check)

Not handled:
- ❌ `/dev/tty` unavailable (rare)

See review document section 4 for full analysis.

---

### 5. What's the minimum test matrix?

**Answer:**
- **OS:** macOS 13-15 (3 versions)
- **Arch:** Intel + Apple Silicon (2 types)
- **Execution:** Direct, piped, `-y` flag, non-interactive (4 methods)
- **Total:** 6 OS configs × 4 execution = 24 tests minimum

Critical path: 5 tests in 15 minutes.

---

### 6. How fast can the script run? What's the bottleneck?

**Answer:**
- **Current:** ~5 minutes
- **Bottleneck:** Node.js installation (2-3 min, 60% of time)
- **Optimization potential:** 1-2 min (if Node.js binary caching added)
- **Security overhead:** <1% (negligible)

**Verdict:** Already well-optimized, no fixes needed.

---

## Files Created

```
reviews/
  ├── prism-04-script-hardening.md      (40 KB, main review)
  └── PRISM-04-SUMMARY.md               (this file)

fixes/
  ├── stdin-tty-fix.patch               (executable, critical fix)
  ├── test-stdin-fix.sh                 (executable, verification)
  ├── re-enable-checksums.sh            (executable, checksum tool)
  └── bash32-compat-checklist.md        (compatibility reference)
```

---

## Contact

**For questions about this review:**
- Main review: `reviews/prism-04-script-hardening.md`
- stdin fix: `fixes/stdin-tty-fix.patch`
- Verification: `fixes/test-stdin-fix.sh`

**Next PRISM review:** (if needed) Template quality audit

---

**Review Complete:** 2026-02-15 02:30 EST  
**Subagent:** Watson (PRISM #4: Performance + Reliability)  
**Status:** Deliverables ready, fix available, awaiting deployment
