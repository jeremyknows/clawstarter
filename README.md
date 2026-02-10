# OpenClaw Setup Guide

Everything you need to set up [OpenClaw](https://openclaw.ai) on a Mac — from zero to a running AI agent.

**Audience:** Non-technical founders and first-time users. No Terminal experience required.

## Quick Start

Open **`openclaw-setup-guide.html`** in your browser and follow the steps. That's it.

(Double-click the file. It works offline — no internet needed to read the guide.)

## What's in This Package

### Setup Guides (pick one)

| File | What it is | Best for |
|------|-----------|----------|
| `openclaw-setup-guide.html` | Interactive step-by-step guide with a configurator | Most people (recommended) |
| `OPENCLAW-SETUP-GUIDE.md` | Same guide as plain text | People who prefer reading markdown |

### AI-Assisted Setup (optional)

These are prompts you paste into an AI assistant so it can walk you through setup conversationally:

| File | What it is | Best for |
|------|-----------|----------|
| `OPENCLAW-CLAUDE-SETUP-PROMPT.txt` | Prompt for [Claude.ai](https://claude.ai) | Chatting through setup with Claude in a browser |
| `OPENCLAW-CLAUDE-CODE-SETUP.md` | Prompt for [Claude Code](https://claude.ai/claude-code) (CLI) | Having Claude Code run commands for you in Terminal |

The HTML guide also generates a customized version of the Claude.ai prompt on its final page, tailored to the choices you made in the configurator.

### Automation

| File | What it is | Best for |
|------|-----------|----------|
| `openclaw-autosetup.sh` | Automated setup script (19 steps) — handles ~80% of the work | "Just do it for me" people |
| `openclaw-verify.sh` | Post-setup diagnostic (18 checks) — checks for common issues | Verifying everything is working |

### After Setup

| File | What it is |
|------|-----------|
| `OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md` | Optional hardening guide (security audit, backups, monitoring). Do Phase 1 this week; the rest at your own pace. |
| `templates/workspace-scaffold-prompt.md` | Standalone prompt — paste into your bot's first chat to scaffold workspace + run first-time personalization. Use this if you didn't run autosetup.sh and aren't following the Playbook. |

### Workspace Templates

The `templates/workspace/` folder contains starter files for your bot's workspace (`~/.openclaw/workspace/`). The autosetup script copies them automatically (Step 12). For manual setup, use `templates/workspace-scaffold-prompt.md` or copy files directly:

| File | Purpose |
|------|---------|
| `AGENTS.md` | Operating manual — startup procedure, safety rules, memory discipline |
| `SOUL.md` | Personality and communication style |
| `TOOLS.md` | Environment-specific infrastructure (API providers, channels, devices) |
| `IDENTITY.md` | Name, emoji, vibe |
| `USER.md` | Owner profile and preferences |
| `MEMORY.md` | Long-term memory template |
| `HEARTBEAT.md` | Scheduled check configuration |
| `BOOTSTRAP.md` | First-run setup wizard (deletes itself after completion) |

## Requirements

- **Mac** (Apple Silicon or Intel)
- **macOS 13+** (Ventura or newer)
- **Admin access** to create a new Mac user account
- **~30 minutes** for the full manual setup (~10 minutes with the script)

## How the Pieces Fit Together

```
You are here
     │
     ▼
 ┌─────────────────────────────────┐
 │  openclaw-setup-guide.html      │──── The main guide. Start here.
 │  (or OPENCLAW-SETUP-GUIDE.md)   │
 └──────────────┬──────────────────┘
                │
    ┌───────────┼───────────────┐
    ▼           ▼               ▼
 Manual    Script mode     AI-assisted
 (follow   (runs           (paste prompt
  steps)    autosetup.sh)   into Claude)
    │           │               │
    └───────────┼───────────────┘
                ▼
        Workspace scaffolded ──── Templates copied, daily log created
                │
                ▼
        openclaw-verify.sh ──── Confirms everything is working
                │
                ▼
        BOOTSTRAP.md ──── First-chat personalization (bot asks 9 questions)
                │
                ▼
        Foundation Playbook ──── Optional post-setup hardening
```

## Architecture

For full architecture documentation, data flow diagrams, and a navigation guide for contributors, see [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md).

## What's Next

After setup, your workspace has template files ready to personalize. **Open a chat with your bot** — if BOOTSTRAP.md exists, it will walk you through 9 questions to set up your name, timezone, personality, and preferences. This takes about 5 minutes and makes the bot genuinely yours.

Then open `OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md` — it's an optional hardening guide organized in 8 phases. **Only Phase 1 (Security Hardening) is urgent** — do it the same week you set up. Everything else can wait and be done at a pace of one phase per week.

## Version

**Recommended: v2026.2.9** (latest). Minimum: v2026.1.29 (security patches). The guide and scripts check your version automatically.

## Security Notes

- OpenClaw runs AI agents that execute code. The guide creates a **dedicated Mac user** so the agent can't access your personal files.
- The autosetup script migrates secrets from plaintext to **environment variable references** (`${VAR_NAME}` syntax), storing actual values in the LaunchAgent plist.
- File permissions are locked down to 600 (config) and 700 (home directory).
- mDNS/Bonjour network discovery is disabled to prevent the gateway from being visible on the local network.
- Older versions (before 2026.1.29) had serious security bugs that are now fixed. The scripts check your version automatically.
- Never install skills from ClawHub without reviewing the code yourself.

## License

This setup guide is provided as-is for use with OpenClaw. See [openclaw.ai](https://openclaw.ai) for the OpenClaw license.
