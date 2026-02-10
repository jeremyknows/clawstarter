# Contributing to OpenClaw for Beginners

Thanks for your interest in improving this setup guide! Here's how to contribute.

## Quick Start for Contributors

```bash
# Clone the repo
git clone https://github.com/jeremyknows/openclaw-for-beginners.git
cd openclaw-for-beginners

# Read the architecture
cat CLAUDE.md        # Patterns and constraints
cat docs/CODEBASE_MAP.md  # File relationships
```

## Types of Contributions

### 🐛 Bug Reports
Found something broken? [Open an issue](https://github.com/jeremyknows/openclaw-for-beginners/issues/new) with:
- What you expected to happen
- What actually happened
- Your macOS version and OpenClaw version
- Steps to reproduce

### 📝 Documentation Fixes
Typos, unclear instructions, outdated screenshots — all welcome. For small fixes, edit directly on GitHub. For larger changes, see the workflow below.

### 🔧 Script Improvements
Changes to `openclaw-autosetup.sh` or `openclaw-verify.sh` require extra care:
1. Test on a clean macOS user account (or VM)
2. Update the corresponding documentation files (see Cross-File Consistency below)
3. Run the verification script after your changes

### ✨ New Features
For new features, [open an issue first](https://github.com/jeremyknows/openclaw-for-beginners/issues/new) to discuss. We want to keep the setup process simple — not every feature belongs in a beginner guide.

## Development Workflow

### 1. Fork and Branch
```bash
git checkout -b your-feature-name
```

### 2. Make Your Changes
Follow the patterns in `CLAUDE.md`. Key constraints:
- **Atomic config editing**: backup → Python edit → validate → rename
- **Python safety in bash**: Always `sys.argv` + `<< 'PYEOF'` heredocs
- **Cross-file consistency**: Update ALL files that reference changed values

### 3. Test Your Changes

**For script changes:**
```bash
# Create a test user or use a VM
./openclaw-autosetup.sh
./openclaw-verify.sh
```

**For HTML guide changes:**
- Open `openclaw-setup-guide.html` in Safari, Chrome, and Firefox
- Test dark/light mode toggle
- Test the configurator (selections should persist across pages)
- Test copy buttons (should work on `file://` URLs)

### 4. Update Documentation
If you changed a value that appears in multiple files, update them all. The canonical list is in `docs/CODEBASE_MAP.md` under "Cross-File Consistency".

Key files that must stay in sync:
- `OPENCLAW-SETUP-GUIDE.md`
- `openclaw-setup-guide.html`
- `OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md`
- `OPENCLAW-CLAUDE-CODE-SETUP.md`
- `OPENCLAW-CLAUDE-SETUP-PROMPT.txt`
- `openclaw-autosetup.sh`
- `openclaw-verify.sh`

### 5. Commit and PR
```bash
git add .
git commit -m "Brief description of change"
git push origin your-feature-name
```

Then open a pull request on GitHub.

## Cross-File Consistency

This repo has 7 content files that describe the same setup process from different angles. When you change any of these values, update ALL files:

| Value | Must Match |
|-------|-----------|
| OpenClaw minimum version | `2026.1.29` |
| OpenClaw recommended version | `2026.2.9` |
| Gateway port | `18789` |
| Config file name | `openclaw.json` |
| API key prefixes | `sk-or-v1-`, `sk-ant-`, `pa-` |
| Access profiles | `explorer`, `admin`, `default` |
| Autosetup step count | 19 (full), 17 (minimal) |
| Verify check count | 18 |

## Voice and Tone

Different files have different audiences:
- **Technical docs** (`CLAUDE.md`, scripts): Exact commands, terse language
- **User guides** (`OPENCLAW-SETUP-GUIDE.md`): Friendly, explains "why"
- **Prompts** (`OPENCLAW-CLAUDE-SETUP-PROMPT.txt`): Conversational, assumes AI context

When updating content, adapt to each file's voice rather than copy-pasting the same wording everywhere.

## Code Style

### Bash Scripts
- Use `set -euo pipefail` at the top
- Quote all variables: `"$var"` not `$var`
- Use `[[ ]]` for tests, not `[ ]`
- Arithmetic: `count=$((count + 1))` not `((count++))`

### Python Embedded in Bash
```bash
python3 - "$var" << 'PYEOF'
import sys
val = sys.argv[1]  # Use sys.argv, never f-strings with shell vars
# ... rest of code
PYEOF
```

### HTML/CSS/JS
- Use semantic HTML
- CSS variables for theming
- No external dependencies (single-file guide)

## Questions?

Open an issue or reach out on [Discord](https://discord.com/invite/clawd).

---

Thank you for helping make OpenClaw more accessible! 🦞
