# Changelog

All notable changes to ClawStarter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.8.0] - 2026-02-15

### 🎉 Major Release — Production-Ready

ClawStarter v2.8.0 is the first production-ready release, validated by 4 cycles of PRISM multi-agent review and live user testing.

### Added

**Setup Script Improvements:**
- Gateway token extraction and display after `openclaw doctor` completes
- Enhanced final verification step with dashboard URL, token, and clear "what's next" instructions
- Onboarding verification — checks config file exists before continuing, offers retry if missing
- Intro text explaining Y/Enter prompts and invisible password behavior
- jq dependency check with auto-install via Homebrew
- Security warnings about token exposure, git commit risks, and rotation command
- Token explainer: "Think of it like a password for your bot"

**Documentation:**
- New `QUICKSTART.md` — ultra-brief 3-step guide (15 minutes)
- Organized supplementary guides into `docs/` subdirectory
- Pre-Install Checklist now enforces required checkboxes (can't skip)
- Config Wizard ESC instruction moved to always-visible warning box
- User account prerequisite warnings added to README and QUICKSTART
- Optional security enhancement accordion (Keychain/1Password upgrade path)
- "First Connection" troubleshooting section in companion.html

**Quality Assurance:**
- 4 PRISM review cycles (10 specialist perspectives)
- Step 8 completely rewritten to match actual `openclaw onboard` behavior
- All file paths and script names verified for accuracy

### Fixed

**Critical Issues (PRISM-Identified):**
- Script name conflict: All references updated from `openclaw-quickstart-v2.sh` to `openclaw-autosetup.sh`
- macOS version mismatch: Standardized on macOS 13+ Ventura across all docs
- User account prerequisite: Added warnings to README, QUICKSTART, and companion.html (prevents #1 drop-off point)
- Step 8 phantom prompts: Eliminated "Which AI provider? 1/2/3" and "Budget Selection" sections that didn't match actual script behavior

**User Experience:**
- Pre-Install Checklist button now disabled until required checks completed
- companion.html Step 8 now accurately describes `openclaw onboard` wizard
- Password invisibility warning added to Step 7
- "y + Enter" confirmation guidance added

### Changed

- README references updated to point to current files (not deleted ones)
- Version bumped from v2.7.0-prism-fixed to v2.8.0
- Project status: "Production-ready — live tested and PRISM-audited"
- QUICKSTART simplified from 732 lines to 95 lines (87% reduction)
- Moved 4 guides to `docs/` subdirectory for clearer organization

### Removed

- Deleted `docs/openclaw-setup-guide.html` (redundant with companion.html)
- Moved `REVIEW-*.md` files to `archive/reviews/` (internal-only)
- Moved `JEREMY-VISION-V2.md` and `IMPLEMENTATION-PLAN.md` to `archive/`

### Security

- All credential exposure risks mitigated (per PRISM Security Reviewer)
- Defense-in-depth architecture documented in SECURITY.md
- Emergency procedures added for token rotation
- File permissions verified (`chmod 600` on openclaw.json)
- Optional Keychain/1Password integration guidance added

### Documentation Quality Metrics

**PRISM Validation:**
- Accuracy: A- (content matches current script behavior)
- Completeness: B+ (comprehensive with minor gaps)
- Clarity: B (multiple entry points well-organized)
- Security: A (excellent threat model and hardening)
- UX: B- (good happy path, drop-off points addressed)
- Professional Polish: A- (mature project quality)

**Estimated User Success Rate:** 80%+ for first-time users

### Known Limitations

- Discord Message Content Intent verification not yet automated (requires manual portal check)
- Template checksums temporarily disabled pending re-enablement
- Accessibility improvements (WCAG Level AA compliance) in progress
- End-to-end user testing with non-technical users ongoing

### Migration Notes

**From v2.7.x:**
- No breaking changes
- File paths updated (OPENCLAW-SETUP-GUIDE.md moved to docs/)
- Script name standardized (use `openclaw-autosetup.sh` going forward)

**Fresh Installation:**
- Use `companion.html` (recommended) or `QUICKSTART.md` for fastest setup
- Expect 15-20 minute setup time
- Gateway token will be displayed — save it somewhere safe

### Credits

**PRISM Review Team:**
- 4 cycles, 10 specialist perspectives
- Identified and validated fixes for 4 critical issues
- Verified production readiness

**Live Testing:**
- X Spaces test (Feb 15, 2026) — identified token display blocker
- Fresh Mac user validation pending

### What's Next

**Planned for v2.9.0:**
- Telegram setup integration (simpler than Discord)
- Discord Message Content Intent pre-flight check
- Template checksum re-enablement
- Automated connection test in final step

**Planned for v3.0.0:**
- Multi-channel setup wizard
- Interactive companion page with live gateway status
- Progress persistence (localStorage)
- Comprehensive uninstall guide

---

## [2.7.0] - 2026-02-10

Initial release with security hardening and PRISM business strategy review.

### Added
- OpenClaw automated setup script
- Interactive companion page
- Foundation Playbook template
- Security threat model
- 11/20 PRISM reviews complete

### Security
- Keychain isolation
- Input validation
- Atomic file operations

---

[2.8.0]: https://github.com/jeremyknows/clawstarter/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/jeremyknows/clawstarter/releases/tag/v2.7.0
