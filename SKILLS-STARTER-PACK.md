# OpenClaw Skills Starter Pack

Welcome to OpenClaw! This guide will help you install essential skills that make your AI agent immediately useful.

---

## 🎯 Philosophy

The starter pack includes skills that are:
- **Immediately useful** — Try them right after setup
- **Low friction** — Simple installation, minimal auth
- **Wow factor** — Show what AI agents can really do
- **Cross-platform safe** — Work on any Mac

---

## ⚡ Quick Start (5 Essential Skills)

These skills require minimal setup and deliver immediate value. Install all 5 in under 5 minutes.

### 1. 🌤️ Weather

**Why:** Zero setup, instant gratification, no API keys required.

**What it does:** Get current weather and forecasts for any location worldwide.

**Install:**
```bash
# Already available via curl (no installation needed)
```

**Try it:**
```bash
# Ask your agent: "What's the weather in Tokyo?"
# Or: "Will it rain in London tomorrow?"
```

**Setup:** None! Uses free wttr.in and Open-Meteo APIs.

---

### 2. 📝 Apple Notes

**Why:** Native macOS integration, perfect for quick capture and retrieval.

**What it does:** Create, search, edit, and organize Apple Notes from the command line.

**Install:**
```bash
brew tap antoniorodr/memo
brew install antoniorodr/memo/memo
```

**Try it:**
```bash
# Ask your agent: "Add a note: Buy groceries - milk, eggs, bread"
# Or: "Search my notes for 'project ideas'"
# Or: "Show me all notes from the Ideas folder"
```

**Setup:** Grant Automation permissions when prompted (System Settings → Privacy & Security → Automation).

---

### 3. ⏰ Apple Reminders

**Why:** Native task management, perfect for todos and time-based reminders.

**What it does:** Create, list, complete, and manage reminders across all your Apple devices.

**Install:**
```bash
brew install steipete/tap/remindctl
```

**Try it:**
```bash
# Ask your agent: "Remind me to call mom tomorrow at 3pm"
# Or: "What's on my todo list today?"
# Or: "Mark 'buy milk' as complete"
```

**Setup:** Grant Reminders permissions when prompted.

---

### 4. 🧾 Summarize

**Why:** Instant insight into articles, videos, and documents. High wow factor.

**What it does:** Summarize URLs, YouTube videos, PDFs, and local files. Can extract transcripts too.

**Install:**
```bash
brew install steipete/tap/summarize
```

**Try it:**
```bash
# Ask your agent: "What's this video about? https://youtu.be/dQw4w9WgXcQ"
# Or: "Summarize this article: https://example.com/long-article"
# Or: "Give me the transcript from this YouTube video"
```

**Setup:**
```bash
# Uses Google Gemini by default (requires API key)
export GEMINI_API_KEY="your-key-here"

# Or use OpenAI, Anthropic, or xAI:
export OPENAI_API_KEY="your-key-here"
# export ANTHROPIC_API_KEY="your-key-here"
# export XAI_API_KEY="your-key-here"
```

**Get API key:** [Free Gemini API key](https://aistudio.google.com/app/apikey)

---

### 5. 🧲 GifGrep

**Why:** Fun, immediate results, shows agent's ability to work with media.

**What it does:** Search Tenor/Giphy for GIFs, preview in terminal, download, extract stills.

**Install:**
```bash
brew install steipete/tap/gifgrep
```

**Try it:**
```bash
# Ask your agent: "Find me a funny cat GIF"
# Or: "Search for 'office space' GIFs and show me the top 3"
# Or: "Download a 'high five' GIF"
```

**Setup:** Works immediately with Tenor (no API key needed). For Giphy access:
```bash
export GIPHY_API_KEY="your-key-here"
```

---

## 🚀 Bonus Skill: GitHub CLI

**Why:** Essential for developers, simple OAuth flow, immediate utility.

**What it does:** Manage issues, PRs, CI runs, and GitHub automation from the command line.

**Install:**
```bash
brew install gh
```

**Try it:**
```bash
# Ask your agent: "Show me open issues in steipete/openclaw"
# Or: "Check CI status on PR #123"
# Or: "Create an issue: 'Bug in skill loader'"
```

**Setup:**
```bash
gh auth login
# Follow the browser OAuth flow (takes 30 seconds)
```

---

## 📦 Installation Speed Run

Install all 5 essential skills + GitHub in one go:

```bash
# Install Homebrew taps
brew tap antoniorodr/memo
brew tap steipete/tap

# Install all skills
brew install \
  antoniorodr/memo/memo \
  steipete/tap/remindctl \
  steipete/tap/summarize \
  steipete/tap/gifgrep \
  gh

# Authenticate GitHub (optional but recommended)
gh auth login

# Set up summarize API key
export GEMINI_API_KEY="your-key-here"
# Add to ~/.zshrc or ~/.bashrc to persist
```

**Time required:** ~3-5 minutes (depending on download speeds)

---

## 🎓 Level 2 Skills (After You're Comfortable)

Once you've mastered the basics, try these more powerful (but slightly more complex) skills:

### 🔐 1Password

**Why:** Secure secret management for scripts and automation.

**What it does:** Read passwords, inject secrets, run commands with secure environment variables.

**Setup complexity:** Medium (requires 1Password account + desktop app + tmux)

**Install:**
```bash
brew install 1password-cli
```

**Prerequisites:**
- 1Password account (subscription required)
- 1Password desktop app installed and unlocked
- Understanding of tmux sessions

**Best for:** Power users who need secure credential management.

---

### 🎮 Google Workspace (gog)

**Why:** Comprehensive Gmail, Calendar, Drive, Sheets, and Docs automation.

**What it does:** Send emails, manage calendar events, search Drive, update Sheets, and more.

**Setup complexity:** Medium (requires OAuth2 credentials from Google Cloud Console)

**Install:**
```bash
brew install steipete/tap/gogcli
```

**Prerequisites:**
- Google account
- OAuth2 client credentials (requires Google Cloud Console setup)
- ~15 minutes for initial OAuth flow

**Best for:** Heavy Google Workspace users who want automation.

---

### 📧 Himalaya Email

**Why:** Universal email client for any IMAP/SMTP provider.

**What it does:** Read, send, search, and organize emails from the terminal.

**Setup complexity:** Medium (requires IMAP/SMTP configuration)

**Install:**
```bash
brew install himalaya
```

**Prerequisites:**
- Email provider with IMAP/SMTP access
- Server hostnames, ports, and credentials
- Password manager recommended for secure credential storage

**Best for:** Users who want terminal-based email or multi-account management.

---

### 🎙️ OpenAI Whisper (Local)

**Why:** Offline speech-to-text, no API costs.

**What it does:** Transcribe audio files locally on your Mac.

**Setup complexity:** Low (simple brew install, but first run downloads models)

**Install:**
```bash
brew install openai-whisper
```

**Note:** First transcription will download ~1-3GB model (one-time).

**Best for:** Privacy-conscious users or those with many audio files to transcribe.

---

### ☁️ OpenAI Whisper (API)

**Why:** Fast cloud-based transcription with OpenAI's accuracy.

**What it does:** Transcribe audio via OpenAI API (Whisper model).

**Setup complexity:** Low (just needs API key)

**Install:**
```bash
# Already available (uses curl)
export OPENAI_API_KEY="your-key-here"
```

**Best for:** Users who want fast, accurate transcription and already have OpenAI credits.

---

### 🎞️ Video Frames

**Why:** Extract frames from videos for analysis or documentation.

**What it does:** Pull single frames or thumbnails from video files.

**Setup complexity:** Low (just ffmpeg)

**Install:**
```bash
brew install ffmpeg
```

**Best for:** Video analysis, creating thumbnails, "what's happening at 2:45 in this video?"

---

### 📱 WhatsApp (wacli)

**Why:** Send WhatsApp messages programmatically, search message history.

**What it does:** Message contacts, search chats, backfill history.

**Setup complexity:** Medium (QR code auth + initial sync)

**Install:**
```bash
brew install steipete/tap/wacli
# Or: go install github.com/steipete/wacli/cmd/wacli@latest
```

**Prerequisites:**
- WhatsApp account
- QR code authentication via `wacli auth`
- Initial sync can take time for large message histories

**Best for:** Heavy WhatsApp users who want automation or history search.

---

### 📨 iMessage (imsg)

**Why:** Automate iMessage/SMS on macOS.

**What it does:** Send messages, read chat history, watch conversations.

**Setup complexity:** Medium (requires Full Disk Access + Automation permissions)

**Install:**
```bash
brew install steipete/tap/imsg
```

**Prerequisites:**
- macOS Messages.app signed in
- Full Disk Access for Terminal
- Automation permissions for Messages.app

**Best for:** macOS power users who want iMessage automation.

---

### 👀 Peekaboo (macOS Automation)

**Why:** The most powerful macOS automation tool - full UI control.

**What it does:** Screen capture, UI automation, click/type/scroll, window management, OCR, vision-guided actions.

**Setup complexity:** Medium-High (requires Screen Recording + Accessibility permissions)

**Install:**
```bash
brew install steipete/tap/peekaboo
```

**Prerequisites:**
- Screen Recording permission
- Accessibility permission
- Understanding of macOS security model

**Best for:** Advanced automation, UI testing, or users who want agents to control desktop apps.

**Warning:** This is powerful - requires careful use and good prompting.

---

## 🎯 Recommended Learning Path

### Week 1: Foundation
1. Install the 5 essential skills
2. Try each one with simple commands
3. Experiment with weather in different cities
4. Create a few notes and reminders
5. Summarize a few articles and YouTube videos
6. Search for some GIFs

### Week 2: Daily Use
1. Make notes/reminders part of your daily workflow
2. Use summarize for research and learning
3. If you're a developer, add GitHub skill
4. Start customizing TOOLS.md with your preferences

### Week 3: Level Up
1. Choose 1-2 Level 2 skills based on your needs
2. Set up Google Workspace if you're a heavy Gmail/Calendar user
3. Add Whisper if you work with audio
4. Explore Peekaboo if you want desktop automation

---

## 💡 Tips for Success

### Start Small
Don't install everything at once. Master the basics first.

### Document Your Setup
Use `TOOLS.md` to track:
- Which skills you've installed
- API keys you've configured
- Personal preferences (voices, default locations, etc.)

### Ask Your Agent
Your agent knows how to use all these skills. Just ask naturally:
- "What's the weather like?"
- "Add a note about the meeting"
- "Summarize this video for me"

### Customize Over Time
As you use OpenClaw, you'll discover which skills matter most. Focus on those.

### Check Permissions
Many skills need macOS permissions. Grant them when prompted, or check:
- System Settings → Privacy & Security → Automation
- System Settings → Privacy & Security → Full Disk Access
- System Settings → Privacy & Security → Screen Recording

---

## 🔍 Quick Reference

### Zero Setup (Works Immediately)
- ✅ weather
- ✅ video-frames (if ffmpeg installed)

### One-Line Setup (Brew + Done)
- ✅ apple-notes
- ✅ apple-reminders
- ✅ gifgrep

### API Key Required (But Simple)
- ✅ summarize (Gemini key - free tier available)
- ✅ openai-whisper-api (OpenAI key)

### OAuth/Auth Flow (5-15 min)
- ⚠️ github
- ⚠️ gog
- ⚠️ wacli

### Complex Setup (15+ min)
- ⚠️ 1password
- ⚠️ himalaya
- ⚠️ peekaboo

---

## 🚨 Common Issues

### "Permission denied" errors
**Solution:** Check System Settings → Privacy & Security and grant required permissions.

### "Command not found: <skill>"
**Solution:** Ensure you've run the brew install command and it completed successfully.

### API key not working
**Solution:** Double-check the key is correct and exported in your shell config (~/.zshrc or ~/.bashrc).

### Skill not responding
**Solution:** Try `<command> --help` to verify installation. Check skill's SKILL.md for requirements.

---

## 📚 Next Steps

1. **Install the 5 essential skills** using the speed run commands above
2. **Test each one** with simple commands via your agent
3. **Read AGENTS.md** to understand how your agent uses skills
4. **Customize TOOLS.md** with your personal setup notes
5. **Explore Level 2 skills** when you're ready for more power

Welcome to OpenClaw! 🐾

---

## 📖 Skill Directory Reference

All skills live in: `~/.npm-global/lib/node_modules/openclaw/skills/`

Each skill has a `SKILL.md` file with full documentation. Your agent reads these automatically, but you can too:

```bash
ls ~/.npm-global/lib/node_modules/openclaw/skills/
cat ~/.npm-global/lib/node_modules/openclaw/skills/weather/SKILL.md
```

For questions, check the main OpenClaw documentation or ask your agent: "How do I use the [skill name] skill?"
