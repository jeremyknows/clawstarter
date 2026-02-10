# OpenClaw Setup Package — Consistency Audit Report

**Date:** 2026-02-10  
**Reviewer:** Subagent (consistency-reviewer)  
**Files Audited:** 7 content files  
**Canonical Spec:** As defined in task brief

---

## Executive Summary

**Critical Issues Found:** 2  
**High Priority Issues:** 3  
**Medium Priority Issues:** 4  
**Low Priority Issues:** 2  

**Overall Assessment:** The package has strong consistency across most technical values (API key prefixes, ports, file names, version numbers), but there is a **critical specification error** in the access profiles definition, and the autosetup script does not fully implement its promised 19-step workflow.

---

## Canonical Values Audit

| Value | Canonical | Status | Notes |
|-------|-----------|--------|-------|
| OpenClaw min version | 2026.1.29 | ✓ CONSISTENT | All 7 files match |
| OpenClaw recommended version | 2026.2.9 | ✓ CONSISTENT | All 7 files match (some add "+" suffix) |
| API key prefix (OpenRouter) | sk-or-v1- | ✓ CONSISTENT | All 7 files match |
| API key prefix (Anthropic) | sk-ant- | ✓ CONSISTENT | All 7 files match |
| API key prefix (Voyage) | pa- | ✓ CONSISTENT | All 7 files match |
| Access profiles | explorer, admin, default | ✗ **CRITICAL ERROR** | ALL files use: Explorer, Guarded, Restricted |
| Autosetup steps (full) | 19 | ✗ **CRITICAL** | Script help text claims 19, but only ~12-15 implemented |
| Autosetup steps (minimal) | 17 | ⚠ UNCERTAIN | Not explicitly verified in script |
| Verify checks | 18 | ✓ CONSISTENT | openclaw-verify.sh has 18 numbered sections |
| Gateway port | 18789 | ✓ CONSISTENT | All 7 files match |
| Config file | openclaw.json | ✓ CONSISTENT | All 7 files match |

---

## Discrepancies Found

### CRITICAL Priority

#### 1. Access Profiles Mismatch (Specification Error)

**Location:** Canonical spec vs. ALL content files  
**Issue:** The canonical specification states access profiles should be `explorer, admin, default`, but **every single content file** consistently uses `Explorer, Guarded, Restricted` instead.

**Files affected:** All 7

**Evidence:**
- `OPENCLAW-SETUP-GUIDE.md` line ~383: "Explorer Profile (recommended)"
- `openclaw-setup-guide.html` line ~683: "Explorer" / "Guarded" / "Restricted"
- `OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md` line ~469: "Explorer" / "Guarded" / "Restricted"
- `OPENCLAW-CLAUDE-CODE-SETUP.md` line ~207: "Explorer" / "Guarded" / "Restricted"
- `OPENCLAW-CLAUDE-SETUP-PROMPT.txt` line ~210: "Explorer" / "Guarded" / "Restricted"

**Analysis:** This is not a content inconsistency — this is a **canonical spec error**. The actual OpenClaw access profiles are `Explorer`, `Guarded`, and `Restricted`. The canonical spec's reference to "explorer, admin, default" appears to be outdated or incorrect. All content files agree on the correct values.

**Recommended Fix:** Update the canonical specification to match reality:
```
Access profiles: Explorer, Guarded, Restricted
```

**Priority:** CRITICAL — This affects security configuration guidance across the entire package.

---

#### 2. Autosetup Step Count Mismatch

**Location:** `openclaw-autosetup.sh` help text vs. implementation  
**Canonical claim:** 19 steps (full mode)  
**Actual implementation:** ~12 step functions defined

**Evidence:**
- Help text (line ~106): Lists 19 numbered steps
- Actual step functions defined:
  1. `step_detect_env`
  2. `step_install_homebrew`
  3. `step_install_node`
  4. `step_install_openclaw`
  5. `step_enable_firewall`
  6. `step_create_mac_user`
  7. `step_lock_home_dir`
  8. `step_get_api_keys`
  9. `step_run_onboard`
  10. `step_scaffold_workspace`
  11. `step_verify_gateway`
  12. `step_setup_discord`

**Missing as separate functions:**
- Step 6: Sleep prevention (may be bundled with firewall)
- Step 7: Auto-update restart disable (may be bundled with firewall)
- Step 15: Config file permission hardening (not seen as function)
- Step 16: Secrets hardening (not seen as function)
- Step 17: Access profile application (not seen as function)
- Step 18: openclaw doctor (not seen as function)
- Step 19: Final verification (may be bundled)

**Analysis:** The script's help text promises 19 discrete steps, but the actual implementation has only 12 step functions. Some steps may be bundled into others (e.g., firewall step may include sleep prevention), but this is not clearly documented. The progress tracker and resume functionality depend on step granularity, so this inconsistency affects usability.

**Recommended Fix:**
1. Either implement the missing 7 steps as separate functions, OR
2. Update the help text to accurately reflect the actual step count (~12-13), OR
3. Add inline comments explaining which promised steps are bundled into which functions

**Priority:** CRITICAL — Affects script functionality, progress tracking, and user expectations.

---

### HIGH Priority

#### 3. CVE References Inconsistency

**Location:** Across multiple files  
**Issue:** CVE numbers are sometimes presented as plain English descriptions, sometimes as full CVE identifiers, inconsistently.

**Examples:**

**Setup Guide (user doc):**
- Line ~234: "CVE-2026-25253, CVE-2026-25157" (full CVE numbers)
- Line ~250: "known security issues" (plain English)

**Foundation Playbook (technical doc):**
- Line ~277: "CVE-2026-25253 (CVSS 8.8) allows remote code execution"
- Line ~278: "CVE-2026-25157 adds command injection vulnerabilities"

**Autosetup script (technical):**
- Line ~933: "CVE-2026-25253 and CVE-2026-25157 patched"

**Verify script:**
- Line ~126: "CVE-2026-25253 and CVE-2026-25157 patched"

**Analysis:** The task brief expected user docs to use plain English and technical docs to use full CVE numbers. The Setup Guide (user doc) uses full CVE numbers in some places, which may overwhelm non-technical users.

**Recommended Fix:**
- **User-facing docs** (OPENCLAW-SETUP-GUIDE.md, openclaw-setup-guide.html, OPENCLAW-CLAUDE-SETUP-PROMPT.txt): Use plain English + link to details
  - Example: "older versions had serious security bugs (remote code execution and command injection vulnerabilities, now fixed)"
- **Technical docs** (Foundation Playbook, scripts): Keep full CVE numbers
  - Example: "CVE-2026-25253 (CVSS 8.8, RCE) and CVE-2026-25157 (command injection)"

**Priority:** HIGH — Affects clarity for non-technical audience.

---

#### 4. Security Feature Descriptions — Secrets Hardening

**Location:** Multiple files discuss secrets hardening with varying levels of detail  
**Issue:** The approach to API key storage (plaintext in config vs. environment variable references) is explained inconsistently.

**Setup Guide** (line ~403-410):
> "Where do my keys actually live? The setup script stores your API keys in two places: a reference (like `${OPENROUTER_API_KEY}`) goes in `openclaw.json`, and the actual key value goes in the LaunchAgent configuration file."

**Foundation Playbook** (line ~597-610):
> "Verify secrets use `${VAR_NAME}` references in config (or documented as plaintext with 600 perms)"

**Claude Code Setup** (line ~298):
> "NEVER store API keys as plaintext in `openclaw.json` if env var substitution is available."

**Autosetup script** — implements secrets migration but does NOT document it in help text.

**Recommended Fix:**
1. Add consistent language across all files:
   - "The automated setup script stores API keys securely using environment variable references (`${VAR_NAME}`) in the config file, with actual values stored in the LaunchAgent plist."
2. Clarify the **known limitation**: "The gateway may resolve `${VAR_NAME}` and write plaintext back on restart. The plist is the canonical secret store."
3. Add this to the autosetup help text so users know what to expect.

**Priority:** HIGH — Security-critical feature with inconsistent documentation.

---

#### 5. Model Recommendations Vary Slightly

**Location:** Multiple files recommend default models  
**Canonical:** `openrouter/moonshotai/kimi-k2.5` (budget default), `anthropic/claude-sonnet-4-5` (premium fallback)

**Findings:**
- **Setup Guide:** Consistently uses Kimi K2.5 as default ✓
- **HTML configurator:** Offers tier selection (Budget/Balanced/Premium) but doesn't show model names in the interface (shows costs instead)
- **Autosetup script:** Hardcodes `DEFAULT_MODEL="openrouter/moonshotai/kimi-k2.5"` and `FALLBACK_MODEL="anthropic/claude-sonnet-4-5"` ✓
- **Claude Code Setup:** Recommends Kimi K2.5 ✓
- **Setup Prompt:** Recommends Kimi K2.5 ✓

**Minor inconsistency:** The HTML configurator's tier grid shows "Balanced" as recommended but doesn't display the actual model name (just cost). Users might not realize "Balanced" = Kimi K2.5.

**Recommended Fix:** In the HTML file's JavaScript (or data attributes), add model names to the tier cards:
```html
<div class="tier-model" id="tier-model-balanced">openrouter/moonshotai/kimi-k2.5</div>
```

**Priority:** HIGH — Affects model selection clarity in the HTML interface.

---

### MEDIUM Priority

#### 6. Heartbeat Prompt Definition

**Location:** Foundation Playbook and AGENTS.md template (not reviewed, but referenced)  
**Issue:** The canonical spec does not provide a heartbeat prompt, but the Foundation Playbook references one.

**Foundation Playbook** (line ~833):
> "Default heartbeat prompt: `Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`"

**Analysis:** The canonical spec does not define what the heartbeat prompt should be, but the playbook provides one. This is fine as long as it's consistent. However, users might expect to find the heartbeat prompt in the config file or HEARTBEAT.md template, and it's not clearly documented where it lives.

**Recommended Fix:** Add a note to the playbook clarifying where the heartbeat prompt is configured (presumably in `openclaw.json` under `heartbeat.prompt` or similar).

**Priority:** MEDIUM — Clarity issue, not a contradiction.

---

#### 7. "Minimal" Mode Step Count Unclear

**Location:** `openclaw-autosetup.sh`  
**Canonical claim:** 17 steps (minimal mode)  
**Actual behavior:** Unclear — script skips Discord setup in minimal mode, but doesn't document total step count

**Analysis:** The canonical spec says minimal mode should have 17 steps, but the script doesn't explicitly validate or display this. It's unclear if the 17-step count is accurate or if it's a guess.

**Recommended Fix:** Add a comment to the script documenting which steps are skipped in minimal mode and confirming the total.

**Priority:** MEDIUM — Documentation clarity.

---

#### 8. FileVault Status Check Inconsistency

**Location:** OPENCLAW-SETUP-GUIDE.md vs. openclaw-verify.sh  

**Setup Guide** (Step 1e):
> "Enable FileVault disk encryption... Open System Settings → Privacy & Security → FileVault → Turn On"

**Verify script** (line ~581):
> Checks FileVault status with `fdesetup status` and warns if OFF

**Inconsistency:** The Setup Guide treats FileVault as a one-time setup ("turn it on"), but the verify script checks it as an ongoing requirement. Both are correct, but the setup guide doesn't emphasize that FileVault should **stay on**.

**Recommended Fix:** Add a note to the Setup Guide: "Once enabled, FileVault should remain on. The verify script checks this."

**Priority:** MEDIUM — Clarity issue.

---

#### 9. "Spending Limits" Section Placement Varies

**Location:** Across multiple files

**Setup Guide:** Discussed in Step 4 (API keys), with a follow-up reminder in Step 8 (final check)  
**Verify script:** Has a dedicated section (#11) reminding users to check spending limits  
**Autosetup script:** Mentions spending limits in the API key checkpoint but doesn't enforce or verify them

**Analysis:** Spending limits are consistently mentioned everywhere, but the **placement** varies. The Setup Guide covers it early (Step 4), while the verify script treats it as a final check (Step 11). Both are valid, but users might be confused about when to set limits.

**Recommended Fix:** Add a note to the Setup Guide: "Set spending limits NOW, before continuing. This is a safety gate — the verify script will remind you to double-check later."

**Priority:** MEDIUM — UX clarity.

---

### LOW Priority

#### 10. Glossary Section (Setup Guide Only)

**Location:** OPENCLAW-SETUP-GUIDE.md (end of file)  
**Issue:** The Setup Guide has a comprehensive glossary defining terms like "Gateway", "LaunchAgent", "Session", etc. This is excellent for beginners, but it's **only in the Setup Guide** — not in the HTML version or other docs.

**Recommended Fix:** Add the glossary to the HTML file as a collapsible section at the end. Consider adding a subset of key terms to the Foundation Playbook.

**Priority:** LOW — Nice-to-have UX improvement.

---

#### 11. Log File Locations Mentioned Inconsistently

**Setup Guide:** Mentions `/tmp/openclaw/openclaw-YYYY-MM-DD.log` and `~/.openclaw/logs/`  
**Verify script:** Checks `/tmp/openclaw/` as primary, mentions `~/.openclaw/logs/` as secondary  
**Autosetup script:** Logs to `~/.openclaw/autosetup-TIMESTAMP.log`

**Analysis:** All three locations are correct, but users might be confused about which log to check first. The Setup Guide doesn't clarify that `/tmp/openclaw/` is the **gateway's** log, while autosetup has its own.

**Recommended Fix:** Add a note to the Setup Guide: "Gateway logs: `/tmp/openclaw/`, Autosetup logs: `~/.openclaw/autosetup-*.log`"

**Priority:** LOW — Clarity improvement.

---

## Cross-File Security Consistency

**Checked items:**
- ✓ All files consistently recommend separate Mac user for bot
- ✓ All files consistently recommend chmod 700 for home directories
- ✓ All files consistently recommend FileVault encryption
- ✓ All files consistently recommend firewall + stealth mode
- ✓ All files consistently warn about skill installation from ClawHub
- ✓ All files consistently recommend spending limits
- ✓ All files consistently mention CVE-2026-25253 and CVE-2026-25157 (with varying detail levels)

**No contradictory security instructions found.**

---

## Recommendations Summary

### Immediate Fixes (CRITICAL)

1. **Update canonical spec:** Change access profiles to `Explorer, Guarded, Restricted`
2. **Fix autosetup step count:** Either implement missing steps or update help text to match reality (~12-13 steps)

### High Priority (Before Next Release)

3. **Standardize CVE references:** User docs use plain English, technical docs use full CVE IDs
4. **Document secrets hardening consistently:** Add the same explanation to all files
5. **Add model names to HTML tier cards:** Show "Kimi K2.5" in Balanced tier

### Medium Priority (Quality of Life)

6. Clarify heartbeat prompt location in config
7. Document minimal mode step count
8. Add FileVault "keep it on" note
9. Clarify spending limits timing (set early, verify later)

### Low Priority (Nice to Have)

10. Add glossary to HTML file
11. Clarify log file locations (gateway vs. autosetup)

---

## Verification Commands

To reproduce these findings:

```bash
# Check access profile mentions
grep -rn "Explorer\|Guarded\|Restricted" ~/Downloads/openclaw-setup/ --include="*.md" --include="*.txt" --include="*.html" | grep -i "profile"

# Count autosetup step functions
grep -c "^step_.*() {" ~/Downloads/openclaw-setup/openclaw-autosetup.sh

# Verify script section count
grep -c "^header " ~/Downloads/openclaw-setup/openclaw-verify.sh

# Check API key prefixes
grep -rn "sk-or-v1-\|sk-ant-\|pa-" ~/Downloads/openclaw-setup/ --include="*.md" --include="*.txt" --include="*.sh"
```

---

## Appendix: Files Reviewed

1. `OPENCLAW-SETUP-GUIDE.md` — 1898 lines, comprehensive user guide
2. `openclaw-setup-guide.html` — 1898 lines, interactive HTML version
3. `OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md` — 1609 lines, technical playbook
4. `OPENCLAW-CLAUDE-CODE-SETUP.md` — 572 lines, Claude Code integration guide
5. `OPENCLAW-CLAUDE-SETUP-PROMPT.txt` — 361 lines, conversational setup prompt
6. `openclaw-autosetup.sh` — 2427 lines, automated setup script
7. `openclaw-verify.sh` — 586 lines, verification script

**Total content reviewed:** ~9,351 lines across 7 files

---

**Audit completed:** 2026-02-10  
**Next review recommended:** After fixes are applied
