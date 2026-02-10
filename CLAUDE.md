# OpenClaw Setup Package

Complete documentation package for setting up OpenClaw AI agent on macOS. Audience: non-technical founders.

## Stack
- **Languages:** Bash (scripts), HTML/CSS/JS (interactive guide), Markdown (docs)
- **Runtime deps:** Python 3 (ships with macOS, used for JSON manipulation in scripts)
- **Target platform:** macOS 13+ (Apple Silicon or Intel)

## Quick Commands
```bash
# Run automated setup (interactive, 19 steps)
bash openclaw-autosetup.sh

# Minimal mode (gateway only, 17 steps)
bash openclaw-autosetup.sh --minimal

# Resume from last checkpoint
bash openclaw-autosetup.sh --resume

# Post-setup verification (18 checks)
bash openclaw-verify.sh
```

## Structure
```
openclaw-setup/
├── docs/CODEBASE_MAP.md              # Full architecture map
├── templates/
│   ├── workspace/                    # 8 workspace templates (single source of truth)
│   │   ├── AGENTS.md                 # Operating manual
│   │   ├── BOOTSTRAP.md              # First-run wizard (self-deletes)
│   │   ├── HEARTBEAT.md              # Scheduled checks
│   │   ├── IDENTITY.md               # Bot name/emoji/vibe
│   │   ├── MEMORY.md                 # Long-term memory
│   │   ├── SOUL.md                   # Personality
│   │   ├── TOOLS.md                  # Infrastructure docs
│   │   └── USER.md                   # Owner profile
│   └── workspace-scaffold-prompt.md  # Manual workspace setup prompt
├── openclaw-autosetup.sh             # 19-step automated setup
├── openclaw-verify.sh                # 18-check diagnostic
├── openclaw-setup-guide.html         # Interactive guide (configurator)
├── OPENCLAW-SETUP-GUIDE.md           # Markdown guide
├── OPENCLAW-CLAUDE-CODE-SETUP.md     # Claude Code CLI prompt
├── OPENCLAW-CLAUDE-SETUP-PROMPT.txt  # Claude.ai conversational prompt
└── OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md  # Post-setup hardening (8 phases)
```

## Key Patterns
- **Atomic config editing:** All `openclaw.json` changes use backup → Python 3 edit → Zod validate → rename (or restore on failure). Never edit config directly.
- **Python safety:** All 22 embedded Python blocks use `sys.argv` + `<< 'PYEOF'` heredocs. Never interpolate shell variables into Python code.
- **Secrets architecture:** `${VAR_NAME}` references in `openclaw.json`, actual values in LaunchAgent plist `EnvironmentVariables` dict. Gateway resolves at startup.
- **Account-switching flow:** All admin/sudo tasks consolidated in Steps 1-7. User switches to bot user ONCE and stays there.
- **Idempotent steps:** Every autosetup step can be re-run safely. Progress tracked in `~/.openclaw-autosetup-progress` JSON.
- **Workspace templates via `cp -n`:** Always copy from `templates/workspace/`. Never heredoc template content into scripts.
- **Cross-file consistency:** 7 content files share CVE numbers, version thresholds, API key prefixes, access profiles. When updating one, update all.
- **HTML conditional visibility:** `data-requires` attributes evaluated against configurator selections. `localStorage` with `sessionStorage` fallback.
- **CVE language split:** User-facing = plain English ("serious security bug"). Technical (scripts/playbook) = full CVE numbers.
- **Color-coded script output:** Both scripts use GREEN/PASS, RED/FAIL, YELLOW/WARN, CYAN/INFO.

## Critical Constraints
- Config file (`~/.openclaw/openclaw.json`) is Zod-validated — unknown keys cause validation errors
- OpenClaw min version 2026.1.29 (CVE patches), recommended 2026.2.9+ (safety scanner + credential redaction)
- API key prefixes: `sk-or-v1-` (OpenRouter), `sk-ant-` (Anthropic), `pa-` (Voyage AI)
- Autosetup minimal mode: STEP_TOTAL=17 (skips mac_user + discord)
- Gateway rewrites `${VAR_NAME}` back to plaintext on restart — LaunchAgent plist is canonical secret store
- BOOTSTRAP.md self-deletes after first-run — its existence signals first-run not yet complete
- MEMORY.md only loads in private OpenClaw sessions, NOT group channels
- `localhost` resolves to IPv6 in Node 18+ — use `127.0.0.1` for Ollama

## Architecture
See [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for full architecture, data flow diagrams, and navigation guide.
