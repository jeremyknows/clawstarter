# ClawStarter — 3-Step Quickstart

**From zero to running AI bot in 15 minutes.**

---

## Before You Start

<details>
<summary>🍎 <strong>macOS</strong></summary>

✅ **You need:**
- A Mac (any model, macOS 13+ Ventura or newer)
- $5-10 for AI credits ([OpenRouter](https://openrouter.ai/keys)) — or use the free tier
- 15 minutes

⚠️ **Important:** For security, your bot should run on a separate macOS user account (not your admin account). This isolates the bot from your personal files.

**Already have a second user?** Great! Log into that account and continue.  
**Don't have one?** Open `companion.html` in your browser and follow Step 3 to create one, then come back here.

</details>

<details>
<summary>🪟 <strong>Windows</strong></summary>

✅ **You need:**
- Windows 10 (May 2020 Update or later) or Windows 11
- $5-10 for AI credits ([OpenRouter](https://openrouter.ai/keys)) — or use the free tier
- 15-20 minutes
- Administrator access

⚠️ **How it works:** OpenClaw runs inside WSL2 (Windows Subsystem for Linux). The setup script installs WSL2 + Ubuntu automatically — you don't need to know Linux.

**A reboot may be required** after enabling WSL2. The script handles this and can resume where it left off.

</details>

✅ **You'll have:**
- Running AI bot (web dashboard)
- Auto-starts on reboot
- Ready to chat

---

## Step 1: Get Your API Key

1. Go to **[openrouter.ai/keys](https://openrouter.ai/keys)**
2. Sign up (email or Google)
3. Add $5-10 in credits
4. Create an API key
5. **Copy it** (starts with `sk-or-v1-...`)

💡 **Alternative:** Use Anthropic ([console.anthropic.com](https://console.anthropic.com)) if you prefer Claude directly.

---

## Step 2: Run the Setup

Open **companion.html** in your browser and follow the 10-step wizard.

**Or, use the command-line installer:**

<details>
<summary>🍎 <strong>macOS</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/jeremyknows/clawstarter/main/openclaw-autosetup.sh | bash
```

The script will install dependencies (Homebrew, Node.js, OpenClaw), ask for your API key, and configure the model fallback chain (`kimi-k2.5-free` → `haiku-4.5` → `qwen3-coder:free`).

</details>

<details>
<summary>🪟 <strong>Windows</strong></summary>

1. Download [`openclaw-windows-setup.ps1`](openclaw-windows-setup.ps1)
2. Right-click → **Run with PowerShell** (or open PowerShell as Admin and run it)
3. If Windows SmartScreen warns you, click **More info** → **Run anyway**
4. Follow the prompts — the script installs WSL2, Ubuntu, Node.js, and OpenClaw
5. If a reboot is required, re-run with: `.\openclaw-windows-setup.ps1 -Resume`

The script configures the same model fallback chain (`kimi-k2.5-free` → `haiku-4.5` → `qwen3-coder:free`).

</details>

The scripts will:
- Install dependencies (Node.js, OpenClaw)
- Ask for your API key
- Set up the bot
- Start the gateway

**Time:** 10-15 minutes (longer if installing Homebrew for the first time)

---

## Step 3: Start Chatting

When you see:
```
✅ Setup complete!
Dashboard: http://127.0.0.1:18789
Gateway token: [long random string]
```

1. **Save the gateway token** somewhere safe
2. Open **http://127.0.0.1:18789** in your browser
3. Paste your gateway token
4. Send a message: `Hello! What can you help me with?`

**Done!** Your bot is running.

---

## What's Next?

### Try It Out
```
Summarize this article: [paste URL]
What's the weather in [your city]?
Help me brainstorm 10 project names
```

### Customize
Edit `~/.openclaw/workspace/AGENTS.md` to change personality and behavior.

### Add Channels
Set up Discord, Telegram, or iMessage — see the [full setup guide](OPENCLAW-SETUP-GUIDE.md).

### Go Deeper
The [Foundation Playbook](OPENCLAW-FOUNDATION-PLAYBOOK-TEMPLATE.md) has 8 phases covering security, memory, automation, and multi-agent setups. Do them at your own pace.

---

## Common Issues

| Problem | Fix |
|---------|-----|
| Gateway won't start | `openclaw gateway restart` |
| API key invalid | Double-check you copied the full key |
| Dashboard connection refused | Run `openclaw gateway status` |
| Need help | Run `openclaw doctor` |

**Full troubleshooting:** [docs.openclaw.ai/help](https://docs.openclaw.ai/help)

---

**That's it.** You have a working AI agent. Enjoy! 🚀
