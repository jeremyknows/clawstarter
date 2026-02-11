# Skill Audit: ClawStarter Templates

**Date:** 2026-02-11
**Purpose:** Ensure templates include the best skills for user success

---

## Current Template Skills

### Content Creator
| Skill | Type | Purpose |
|-------|------|---------|
| gifgrep | External (brew) | Search/download GIFs |
| ffmpeg | External (brew) | Video frame extraction |
| summarize | External (brew) | Summarize videos/articles |
| **Built-in** | OpenClaw | web_search, web_fetch, tts, image |

**Missing opportunities:**
- ❌ x-research-skill (X/Twitter research)
- ❌ openai-whisper-api (transcription)
- ❌ nano-banana-pro (image generation)
- ❌ video-frames skill (better than raw ffmpeg)

### Workflow Optimizer
| Skill | Type | Purpose |
|-------|------|---------|
| memo | External (brew) | Apple Notes |
| remindctl | External (brew) | Apple Reminders |
| gogcli | External (brew) | Google Workspace |
| himalaya | External (brew) | Email (IMAP/SMTP) |
| summarize | External (brew) | Document summaries |
| 1password-cli | External (brew) | Secrets |
| **Built-in** | OpenClaw | web_search, web_fetch |

**Missing opportunities:**
- ❌ weather (quick weather checks)
- ❌ imsg (iMessage automation)

### App Builder
| Skill | Type | Purpose |
|-------|------|---------|
| gh | External (brew) | GitHub CLI |
| jq | External (brew) | JSON processing |
| fzf | External (brew) | Fuzzy finder |
| summarize | External (brew) | Doc summaries |
| tmux | External (brew) | Session management |
| ripgrep | External (brew) | Fast search |
| **Built-in** | OpenClaw | exec, Read, Write, Edit |

**Missing opportunities:**
- ❌ Quality skills (systematic-debugging, TDD, code review)
- ❌ generate-jsdoc (documentation)
- ❌ update-docs (README/CLAUDE.md maintenance)

---

## Quality Skills Available (Not in Templates)

### From Superpowers/Claude (HIGH VALUE)
These are methodology skills that improve agent behavior:

| Skill | Description | Who Benefits |
|-------|-------------|--------------|
| **systematic-debugging** | Structured debugging approach | App Builder |
| **test-driven-development** | TDD methodology | App Builder |
| **receiving-feedback** | Anti-sycophancy, critical thinking | Everyone |
| **verification-before-completion** | Evidence before assertions | Everyone |
| **complete-code-review** | Multi-agent code review | App Builder |
| **brainstorming** | Explore before building | Content, App Builder |
| **feature-dev** | 7-phase feature development | App Builder |

**Recommendation:** Add these to App Builder template (they're game-changers)

### Research & Content Skills
| Skill | Description | Who Benefits |
|-------|-------------|--------------|
| **x-research-skill** | X/Twitter research | Content Creator |
| **x-engage** | X engagement (drafts) | Content Creator |
| **nano-banana-pro** | Gemini image generation | Content Creator |
| **openai-image-gen** | OpenAI image generation | Content Creator |

**Recommendation:** Add x-research-skill to Content Creator

### Productivity Skills
| Skill | Description | Who Benefits |
|-------|-------------|--------------|
| **weather** | Weather lookups | Workflow Optimizer |
| **imsg** | iMessage automation | Workflow Optimizer |
| **peekaboo** | macOS UI automation | Power users |

---

## Recommended Skill Updates

### Content Creator → Add:
```bash
# Research
# x-research-skill is a skill file, not brew package
# Add note: "Ask agent to use x-research skill"

# Media
brew install steipete/tap/openai-whisper-api  # or note API-based
# nano-banana-pro is skill file, auto-available

# Video
# video-frames skill wraps ffmpeg better
```

### Workflow Optimizer → Add:
```bash
# Weather (zero setup, high value)
# Built-in via curl wttr.in - just enable in AGENTS.md

# iMessage (if they want it)
brew install steipete/tap/imsg
```

### App Builder → Add:
```bash
# Quality skills (these are skill files, not brew)
# Add to AGENTS.md: "Use systematic-debugging skill when debugging"
# Add to AGENTS.md: "Use verification-before-completion skill"
# Add to AGENTS.md: "Use test-driven-development skill"
```

---

## Skill Types Explained

### External Skills (brew install)
- Installed as CLI tools
- skills.sh handles installation
- Examples: gh, gifgrep, summarize

### Skill Files (SKILL.md)
- Already in ~/.openclaw/skills/ or bundled
- Agent reads them automatically when relevant
- Examples: systematic-debugging, brainstorming, x-research

### Built-in Tools
- Always available (web_search, web_fetch, exec, etc.)
- No installation needed
- Just mention in AGENTS.md

---

## Implementation Plan

### Phase 1: Update AGENTS.md (Immediate)
Add skill references to each template's AGENTS.md:

**Content Creator AGENTS.md:**
```markdown
## Skills to Use
- For X/Twitter research: Use x-research-skill
- For image generation: Use nano-banana-pro or openai-image-gen
- For transcription: Use openai-whisper-api skill
```

**App Builder AGENTS.md:**
```markdown
## Development Skills
- Before debugging: Use systematic-debugging skill
- Before claiming done: Use verification-before-completion skill
- For code review: Use complete-code-review skill
- For new features: Use brainstorming skill first
```

### Phase 2: Update skills.sh (Optional)
Add optional skill installs for power users.

### Phase 3: Template Gallery (Future)
Create skill packs users can add:
- "Quality Pack" (debugging, TDD, review)
- "Research Pack" (x-research, summarize)
- "Media Pack" (whisper, image gen)

---

## Summary

| Template | Current Skills | Recommended Adds | Priority |
|----------|---------------|------------------|----------|
| Content Creator | 3 + built-in | x-research, whisper | Medium |
| Workflow Optimizer | 6 + built-in | weather, imsg | Low |
| App Builder | 6 + built-in | **Quality skills** | **HIGH** |

**Key insight:** App Builder users would benefit most from the Superpowers skills (systematic-debugging, TDD, verification). These are methodology skills that dramatically improve agent behavior.

---

*Audit complete. Ready for implementation.*
