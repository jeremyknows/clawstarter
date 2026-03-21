# ClawStarter v4 Roadmap

**Status:** Sprint 4 complete, ready for closed beta.  
**Last Updated:** 2026-03-21  
**Vision:** A zero-friction `curl | bash` installer for OpenClaw. Telegram-first, local install, 10-minute setup.

---

## Current Phase — Closed Beta (~4 weeks, starting now)

**Goal:** Real hardware testing with 10–20 non-technical testers. Focus: Does the script work end-to-end? Are instructions clear?

### Beta Deliverables
- [ ] **Test pool recruited** — 10–20 willing participants (preferably outside OpenClaw core team)
- [ ] **Pre-beta guide written** — clear expectations, how to report issues, what we're measuring
- [ ] **First-run analytics** — track: install success rate, time to first message, user retention day 1 + day 7
- [ ] **Issue triage** — P0 blockers vs. UX paper cuts
- [ ] **Weekly builds** — hot fixes as issues surface

### Success Criteria (Beta Complete)
- **70%+ install success rate** on both macOS 12+ and Ubuntu 20.04+ (first attempt, no rework)
- **Time-to-first-message ≤ 5 minutes** after completing install
- **No P0 security issues** discovered
- **5+ users with 7-day retention** (they come back and use it)

---

## Post-Beta: Feature Parity + Polish (Weeks 5–8)

### Windows Support (Optional, v4.1+)
- PowerShell equivalent of install-v4.sh
- Deferred post-beta decision based on demand

### Onboarding Experience Refinement
- User feedback on first-session questions (4-question limit)
- PRISM validation on revised AGENTS.md template
- First-win experience testing (proactive task/suggestion in day 1)

### Documentation + Marketing
- Blog post on "building an installer in 2026" (transparency, learnings)
- Positioning document (competitor differentiation)
- Get started guide (different from technical QUICKSTART)

---

## GA Release (Week 9+)

### Criteria
- **Closed beta resolved all P0/P1 issues**
- **Independent test on fresh macOS/Ubuntu user = success**
- **Marketing materials live** (landing page updated, docs deployed)
- **GitHub Releases + notarization** ready for curl | bash distribution
- **Homebrew tap** available (macOS)

### Launch Activities
- Announcement to OpenClaw Discord
- Tweet/social in @jeremyknows voice
- Email to early waitlist (if any)
- Follow "Community-First, Build in Public" GTM strategy (see docs/strategy/go-to-market.md)

---

## Post-Launch: Sustain + Expand (Month 2+)

### Maintenance
- **Quarterly security audits** (as dependency versions update)
- **Version bump schedule** (aligned with OpenClaw releases)
- **Passive support** (GitHub Issues, small fixes)

### Revenue Exploration (if applicable)
- See docs/strategy/monetization.md
- Not primary focus — initial goal is adoption + trust-building

### Optional Expansion
- **Skill packs** — "ClawStarter Creator Bundle," "ClawStarter for Founders," etc.
- **Distribution partnerships** — ProductHunt, Indie Hackers, etc.
- **Localization** — non-English markets (if demand exists)

---

## Philosophy
1. **No premature complexity** — only add what users ask for
2. **Test ruthlessly** — document real user behavior before scaling
3. **Stay opinionated** — ClawStarter has a POV (Telegram first, local install, personalized)
4. **Be transparent** — share wins and failures publicly

---

## Known Constraints
- **macOS 12+ only** (Monterey; earlier versions at own risk, not supported)
- **Ubuntu 20.04+ only** (LTS versions, not rolling releases)
- **Offline first** — local model (qwen2.5:3b) recommended to avoid API key friction
- **Single workspace per user** — no multi-workspace in v4

---

## Success Metrics (Track Weekly During Beta)

| Metric | Target | How We Measure |
|--------|--------|-----------------|
| Install success (first try) | 70%+ | Count completions vs. attempts |
| Time to first message | ≤5 min | User reports or logs |
| Day-1 retention | 5+ users | Come back same day? |
| Day-7 retention | 3+ users | Still using after 1 week? |
| User satisfaction | NPS 8+ | Brief post-install survey |
| No P0 security issues | 0 | Security audit + user reports |

---

## Decisions Locked (Sprint 1)

See data/sprints/clawstarter-v4-sprint1-goals.json for all Q&A.

- macOS 12+ (Monterey)
- Ubuntu 20.04+ only
- Always-on machine optional (document both modes)
- Free + open-source (no immediate monetization)
- install.sh --upgrade (not npm)
- Discord setup separate guide, not in script
- ~/.openclaw (standard location)
- Checkpoint/resume on partial failure
- Cost visibility deferred to v4.1
- Closed beta ~4 weeks, 10–20 testers

---

## Questions for Jeremy (if any arise during beta)

TBD — log new decisions here as they come up.

---

**Owner:** Jeremy Knows  
**Next Review:** After first 5 beta installations complete  
**Links:** [Sprint 1 Plan](./FOUNDATION.md) | [Sprint 2 Build](./BUILD-SUMMARY-SPRINT2.md) | [Sprint 3 UX](./BUILD-SUMMARY-SPRINT3.md) | [Sprint 4 Fixes](./review-agent-findings.md)
