# ClawStarter v4 Changelog

All notable changes to ClawStarter v4 (the `curl | bash` installer for OpenClaw on Mac + Linux).

---

## [v4.0-beta] — 2026-03-21

### [Sprint 4: Code Review Fixes](./BUILD-SUMMARY-SPRINT4.md)
- **Fixed:** MEMORY.md heredoc now expands variables ($USER_NAME, $USER_TZ, $USE_CASE)
- **Fixed:** API key + Telegram token moved to ~/.openclaw/.secrets (600 perms), out of world-readable plist
- **Fixed:** Empty-string guards after sanitization (fail cleanly if name/use-case stripped to empty)
- **Fixed:** Telegram retry loop (no sleep before attempt 1, fast-fail on 401/403 auth errors)
- **Improved:** USE_CASE sanitization relaxed to preserve punctuation (periods, commas, colons, parens)
- **Added:** First-session onboarding arc to AGENTS.md template (4-question day-1 flow)
- **Commit:** 72e1075

### [Sprint 3: Onboarding Experience](./BUILD-SUMMARY-SPRINT3.md)
- **Added:** All 5 workspace templates (SOUL.md, USER.md, AGENTS.md with mandatory CIF, MEMORY.md, HEARTBEAT.md)
- **Added:** D7 retention survey in first-boot-hook.sh (7-day prompt)
- **Changed:** AGENTS.md from 600+ lines → ~250 lines (simplified for non-technical users)
- **Added:** Direct AGENTS.md generation in install.sh Phase 2 (was missing entirely)
- **Added:** {{SETUP_DATE}} variable in templates for first-session detection
- **Changed:** First-contact message from generic to personalized 4-question arc
- **Commit:** 5767794

### [Sprint 2: Install Script Build](./BUILD-SUMMARY-SPRINT2.md)
- **Added:** install-v4.sh (41KB, 8 phases, idempotent, fully tested)
- **Added:** first-boot-hook.sh (runs on first gateway startup, self-installs cron)
- **Added:** 5 workspace templates (tmpl format)
- **Added:** seed-jobs/health-check.json (single v4.0 cron job)
- **Added:** BotFather Option B flow (direct link, token validation, recovery prompts)
- **Added:** E2E Telegram test in Phase 7 (live message within 30s)
- **Added:** Input sanitization for USER_NAME and USE_CASE
- **Fixed:** 5 issues from first hardware test (Homebrew PATH, LaunchAgent, API key capture, sudo handling)
- **Commit:** 5767794

### [Sprint 1: Foundation & Planning](./CLAWSTARTER-V4-FOUNDATION.md)
- **Completed:** 1a (inventory), 1b (script audit), 1c (doctrine map), 1d (foundation doc), 1e (PRISM review)
- **Completed:** Two PRISM rounds (1st: VPS-era, 2nd: local-install pivot)
- **Locked:** 10 open questions (macOS 12+, Ubuntu only, free+OSS, closed beta ~4wk, etc.)
- **Decided:** Major pivot from hosted VPS to local `curl | bash` install
- **Key finding:** ops-seed.sh from v3 was 85% reusable, streamlined for v4
- **Deliverables:** inventory-raw.md, script-progression-map.md, doctrine-map.md, FOUNDATION.md

---

## Roadmap

- **Phase:** Closed beta (4 weeks, 10–20 testers), starting 2026-03-21
- **Target:** 70%+ first-try success rate, time-to-first-message ≤5 min
- **GA:** ~4–6 weeks post-beta (assuming clean beta results)
- **See:** [ROADMAP.md](./ROADMAP.md)

---

## Known Issues (Before Beta)

None — all Sprint 4 code review issues resolved.

---

## Known Limitations (v4.0)

- **macOS:** 12+ (Monterey) only. Intel + Apple Silicon both tested.
- **Linux:** Ubuntu 20.04 LTS+ only. Not tested on Fedora, Debian, Arch (post-GA consideration).
- **Offline:** Local model (qwen2.5:3b) uses ~2GB disk. Alternatively, API key (Anthropic/OpenAI/OpenRouter).
- **Single workspace:** One user = one ~/.openclaw/ directory. Multi-workspace support deferred to v4.1+.
- **Discord setup:** Separate manual guide (not in install script). Telegram is primary.

---

## Previous Versions (Archive)

- **v2.8.0** (last v2 release) — see archive/legacy/ and archive/old-versions/
- **v3.x** — unsupervised wild sprint, generated extensive GTM/marketing research (see archive/reviews/, docs/strategy/)

---

## Contributors & Attribution

- **Jeremy Knows** — Vision, product decisions, testing
- **Watson** — Script architecture, template design, QA automation, PRISM orchestration
- **Subagents** — Specialized review & build roles (see Sprint files for details)

---

## Resources

- [Getting Started](./QUICKSTART.md)
- [Foundation & Architecture](./CLAWSTARTER-V4-FOUNDATION.md)
- [Roadmap](./ROADMAP.md)
- [GTM Strategy](./docs/strategy/) (research & positioning)
- [GitHub](https://github.com/jeremyknows/clawstarter)

---

**Status:** Ready for closed beta  
**Last Updated:** 2026-03-21  
**Maintainer:** Jeremy Knows (@jeremyknows)
