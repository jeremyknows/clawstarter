# OpenClaw Quickstart — 3 Easy Steps

**From zero to running bot in ~15 minutes.**

This guide is for beginners who just want their bot working. No separate Mac user, no Discord setup, no advanced security — just the essentials. You can add those later.

---

## Before You Start

**What you need:**
- A Mac (Mac Mini, MacBook, or iMac)
- An AI provider account ([OpenRouter](https://openrouter.ai) recommended — $5-10 to start)
- 15 minutes

**What you'll have at the end:**
- A running AI bot you can chat with via web dashboard
- Auto-starts when your Mac reboots
- Ready to customize

**Not included (deferred to "Advanced Setup"):**
- Separate Mac user account (security best practice)
- Discord/Telegram/iMessage channels
- Access profiles and tool restrictions
- Sleep prevention and firewall setup
- Secrets migration to environment variables

If you want those features, use the [full setup guide](OPENCLAW-SETUP-GUIDE.md) instead.

---

## Step 1: Download & Run

Open **Terminal** (Applications → Utilities → Terminal), then run ONE command:

```bash
bash openclaw-quickstart.sh
```

This script will:
- ✓ Detect your environment (macOS, architecture)
- ✓ Install Homebrew (if missing)
- ✓ Install Node.js 22 (if missing)
- ✓ Install or update OpenClaw
- ✓ Check for common issues

**What if something fails?**  
The script will tell you what went wrong and how to fix it. Most common issue: permissions. If you see "permission denied," run with `sudo` only if the script explicitly tells you to.

**Time:** 3-5 minutes (longer if installing Homebrew for the first time)

---

## Step 2: Make Your Choices

The script will ask **4-5 simple questions**. No tech jargon. Answer honestly — you can change everything later.

### Question 1: Which AI provider?

**Recommended:** OpenRouter (option 1)
- One API key, 100+ models
- Budget-friendly default model
- Sign up: [openrouter.ai](https://openrouter.ai)
- Add $5-10 in credits, create an API key, copy it

**Premium option:** Anthropic (option 2)
- Claude models directly from the source
- Higher quality, higher cost
- Sign up: [console.anthropic.com](https://console.anthropic.com)

**Both:** Use OpenRouter for everyday tasks, Anthropic for complex reasoning

**Paste your API key when prompted.** The script will never show it in plain text.

### Question 2: Monthly spending budget?

This sets which AI model your bot uses by default:

| Tier | Cost/month | What you get |
|------|-----------|--------------|
| Budget | ~$5-15 | Fast, cheap models (good for simple tasks) |
| Balanced | ~$15-50 | Good quality, reasonable cost (recommended) |
| Premium | $50+ | Best models, no compromises |

**Tip:** Start with **Balanced**. You can change the model later in the config.

### Question 3: Personality style?

How should your bot talk to you?

| Style | Vibe | Example response |
|-------|------|-----------------|
| Professional | Formal, structured | "Certainly. I've reviewed the document and identified three key points..." |
| Casual | Friendly, conversational | "Sure thing! I checked the doc and here's what I found..." |
| Direct | Concise, no fluff | "Three issues: 1) X, 2) Y, 3) Z. Need details?" |
| Custom | You configure later | Default casual, you refine over time |

**Most people pick Casual (option 2).**

### Question 4: Bot name?

Give your bot a name. Suggestions:
- Atlas, Watson, Scout, Maverick, Nova, Echo
- Or pick your favorite AI/robot character

**Default:** "Atlas"

### Question 5: How do you want to chat?

For now, the script only sets up the **web dashboard** (simplest option). You can add Discord, Telegram, iMessage, etc. later using the full setup guide.

**Dashboard = browser-based chat.** Works instantly, no extra setup.

---

## Step 3: Start Chatting

The script will:
1. Create your config file
2. Set up a secure workspace
3. Start the gateway (background service)
4. Show you the dashboard URL

**When you see:**
```
🎉 SUCCESS! Your bot is alive.

Dashboard: http://127.0.0.1:18789/
```

**You're done.** Open that URL in your browser and send your first message:

```
Hello! What can you help me with?
```

If the bot responds, congratulations — you have a working AI agent.

**Gateway token:** The script will show you a long random string (gateway auth token). **Save this** — you'll need it if you ever access the dashboard from another device or reinstall.

---

## What Just Happened?

Here's what the quickstart script set up:

1. **Installed dependencies:**  
   - Homebrew (macOS package manager)
   - Node.js 22 (runtime for OpenClaw)
   - OpenClaw (the agent framework)

2. **Created a config file:**  
   - Location: `~/.openclaw/openclaw.json`
   - Contains: Your API keys, default model, gateway settings
   - Permissions: `chmod 600` (only you can read it)

3. **Set up a workspace:**  
   - Location: `~/.openclaw/workspace/`
   - Contains: `AGENTS.md` (bot's personality), `memory/` folder
   - Your bot reads `AGENTS.md` every session to know how to behave

4. **Started the gateway:**  
   - A background service (LaunchAgent) that keeps the bot alive 24/7
   - Auto-restarts if it crashes or after a reboot
   - Runs on port 18789 (local only — not exposed to the internet)

**Is my bot using my computer's resources?**  
Yes, lightly. Expect ~200-500 MB of RAM while idle, CPU spikes when responding. On a Mac Mini M4, you won't notice it.

**Is this secure?**  
For personal use on a single-user Mac, yes — your API keys are protected by file permissions (`chmod 600`), and the gateway only listens on `127.0.0.1` (local machine). For production or shared machines, see "Advanced Setup" below.

---

## Common Issues

| Problem | Solution |
|---------|----------|
| `bash: openclaw-quickstart.sh: No such file` | Run `cd ~/Downloads/openclaw-setup` first, then try again |
| `node: command not found` after install | Restart Terminal, or add to PATH: `export PATH="$(brew --prefix)/opt/node@22/bin:$PATH"` |
| Gateway won't start | Check logs: `tail /tmp/openclaw/gateway-stderr.log` |
| API key error "invalid key" | Double-check you copied the full key from the provider dashboard |
| Dashboard shows "connection refused" | Gateway may not be running. Run `openclaw gateway status` |
| Bot isn't responding in dashboard | Check the config model is correct: `openclaw doctor` |

**Still stuck?**  
Run the diagnostic tool:
```bash
openclaw doctor
```

This checks for common misconfigurations and suggests fixes.

---

## What's Next?

### Try These First Messages

Get to know your bot:

```
What's your name and purpose?
```

```
What can you help me with?
```

```
Show me your personality settings
```

```
What files do you have access to?
```

Ask it to do something useful:

```
Summarize this article: [paste URL]
```

```
What's the weather like in [your city]?
```

```
Help me brainstorm 10 names for a new project about AI agents
```

### Customize Your Bot

Edit `~/.openclaw/workspace/AGENTS.md` to change personality, tone, and behavior:

```bash
nano ~/.openclaw/workspace/AGENTS.md
```

The bot reads this file at the start of every session. Changes take effect immediately.

### Add Communication Channels

Right now you can only chat via the dashboard. To add Discord, Telegram, iMessage, or WhatsApp:

1. Follow the [full setup guide](OPENCLAW-SETUP-GUIDE.md) Step 7 (Discord)
2. Or see the [Foundation Playbook](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md) Phase 3 (multi-channel)

**Why not set up Discord now?**  
The quickstart focuses on getting you to a working bot ASAP. Discord setup involves creating a bot application in the Developer Portal, getting IDs, configuring permissions — about 10 extra minutes. If you want that, use the full setup guide instead.

### Advanced Setup (Optional, Do Later)

The quickstart skipped these for simplicity. Add them when you're ready:

| Feature | Why You Want It | Where to Learn |
|---------|----------------|----------------|
| **Separate Mac user** | Security boundary — bot can't touch your personal files | [Setup Guide Step 1](OPENCLAW-SETUP-GUIDE.md#step-1-prepare-your-mac-15-min-admin-account) |
| **Sleep prevention** | Keep your Mac awake 24/7 so the bot never stops | [Foundation Playbook Phase 1](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md#phase-1-security-hardening) |
| **Firewall + stealth mode** | Block uninvited connections, hide your Mac on the network | [Setup Guide Step 1f](OPENCLAW-SETUP-GUIDE.md#1f-enable-macos-firewall) |
| **Access profiles** | Control what tools the bot can use (restrict risky commands) | [Foundation Playbook Phase 1](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md#phase-1-security-hardening) |
| **Secrets hardening** | Move API keys out of config into environment variables | [Foundation Playbook Phase 1](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md#phase-1-security-hardening) |
| **Memory system** | Persistent memory across sessions (bot remembers you) | [Foundation Playbook Phase 2](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md#phase-2-memory--persistence) |
| **Proactive automation** | Morning briefings, email checks, scheduled tasks | [Foundation Playbook Phase 4](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md#phase-4-proactive-automation) |

**Recommended timeline:**  
- **Week 1:** Just use the bot, get comfortable
- **Week 2:** Add sleep prevention + separate Mac user (security basics)
- **Week 3:** Set up Discord or your preferred channel
- **Month 2+:** Explore advanced features (memory, automation, multi-agent)

The [Foundation Playbook](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md) breaks this into 8 phases you can do at your own pace.

---

## Understanding Your Bot

### What It Can Do (Out of the Box)

✅ Answer questions  
✅ Search the web (Brave Search API)  
✅ Read and summarize URLs  
✅ Run shell commands (on your Mac)  
✅ Read/write files in the workspace  
✅ Remember things within a conversation  

### What It Can't Do (Without Extra Setup)

❌ Send emails (needs email channel config)  
❌ Control smart home devices (needs skill + API)  
❌ Browse websites interactively (browser tool is denied by default)  
❌ Remember things across sessions (needs memory system)  
❌ Post to social media (needs channel credentials)  
❌ Take photos/videos (needs camera skill + hardware)  

Most of these require either:
- Installing a skill (`openclaw skill install <name>`)
- Configuring a new channel (email, social media)
- Enabling a denied tool in `openclaw.json`

The Foundation Playbook covers all of this in Phases 3-6.

### Files Your Bot Uses

| File | Purpose | Can I edit it? |
|------|---------|----------------|
| `~/.openclaw/openclaw.json` | Main config (API keys, models, channels) | ✅ Yes, but back up first |
| `~/.openclaw/workspace/AGENTS.md` | Bot's personality and operating instructions | ✅ Yes, edit freely |
| `~/.openclaw/workspace/MEMORY.md` | Long-term memory (created after Phase 2) | ✅ Yes (bot updates this too) |
| `~/.openclaw/workspace/memory/YYYY-MM-DD.md` | Daily conversation logs | ✅ Yes (bot writes here) |
| `~/Library/LaunchAgents/ai.openclaw.gateway.plist` | Auto-start config | ⚠️ Advanced users only |

**Backup everything before editing:**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
```

### How to Restart Your Bot

If you change the config or something seems stuck:

```bash
openclaw gateway restart
```

Check if it's running:
```bash
openclaw gateway status
```

View recent logs:
```bash
tail -20 /tmp/openclaw/gateway-stderr.log
```

---

## FAQ

**Q: Do I need to keep Terminal open?**  
No. The gateway runs in the background as a LaunchAgent. You can close Terminal and the bot keeps running.

**Q: Will my bot survive a restart?**  
Yes. The LaunchAgent auto-starts on boot. Your bot will be alive within ~30 seconds of macOS starting.

**Q: Can I use this on a MacBook (laptop)?**  
Yes, but laptops sleep when you close the lid. You'll need to:
1. Run `sudo pmset -a sleep 0` (disable sleep)
2. Use an external display + keyboard, or use "clamshell mode"
3. Or accept that the bot only works when the lid is open

**Mac Mini M4 is recommended for 24/7 operation** (~$600, silent, low power).

**Q: How much does this cost to run?**  
- **Hardware:** $0 if you already have a Mac
- **Electricity:** ~$2-5/month (Mac Mini M4 uses 5-15W idle)
- **AI costs:** $5-50/month depending on your usage tier

**Q: Is my data sent to the cloud?**  
Your bot runs locally, but it calls AI providers (OpenRouter, Anthropic) for responses. Those providers see your messages. Your workspace files and config stay on your Mac.

**Q: Can I share my bot with friends/family?**  
Not easily with this setup. The dashboard is local-only (`127.0.0.1`). To make it accessible over the network, you'd need:
- Expose the gateway to your LAN (change `127.0.0.1` to `0.0.0.0` in config)
- Set up authentication (already enabled by default)
- Optionally use a reverse proxy (Cloudflare Tunnel, Tailscale)

This is an advanced topic covered in the Foundation Playbook Phase 7.

**Q: What if I want to use a different model?**  
Edit `~/.openclaw/openclaw.json` and change the `"model"` field. Examples:

```json
"model": "anthropic/claude-opus-4-6"
"model": "openrouter/google/gemini-pro-1.5"
"model": "openrouter/meta-llama/llama-3.3-70b-instruct"
```

Full model list: [openrouter.ai/models](https://openrouter.ai/models)

**Q: Can I run multiple bots on one Mac?**  
Yes, but it's advanced. You'd need separate configs, workspaces, and gateway ports. The Foundation Playbook Phase 8 covers multi-agent setups.

---

## Emergency: Stop Everything

If something goes wrong and you need to shut down the bot immediately:

```bash
# Kill the gateway process
killall openclaw

# Unload the LaunchAgent (prevents auto-restart)
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Disable API keys (so no charges)
# Go to your provider dashboard and delete/disable the key
```

To restart after fixing:
```bash
launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

---

## Get Help

- **Official docs:** [docs.openclaw.ai](https://docs.openclaw.ai)
- **Troubleshooting:** [docs.openclaw.ai/help/troubleshooting](https://docs.openclaw.ai/help/troubleshooting)
- **Run diagnostics:** `openclaw doctor`
- **Check logs:** `tail -50 /tmp/openclaw/gateway-stderr.log`

If you're stuck and can't find help in the docs, the full [Setup Guide](OPENCLAW-SETUP-GUIDE.md) and [Foundation Playbook](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md) cover every step in detail.

---

## You Did It

**Congratulations!** You have a running AI agent. 

**What you learned:**
- How to install OpenClaw
- How to configure an AI provider
- How to start and interact with your bot
- Where the important files live

**Next steps:**
1. Chat with your bot for a week — get comfortable
2. Read the [Foundation Playbook](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md) introduction
3. When ready, tackle Phase 1 (security hardening) and Phase 2 (memory)

**The journey from here is yours.** You can keep it simple (just dashboard chat) or go deep (multi-channel, automation, custom skills). The bot grows with you.

Enjoy. 🚀
