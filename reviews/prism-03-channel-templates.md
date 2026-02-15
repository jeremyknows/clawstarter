# PRISM Round 3: Channel Integration Templates

**Reviewer:** Integration Engineer  
**Date:** Feb 15, 2026 02:30 EST  
**Focus:** Design beginner-friendly channel integration templates that scale

---

## Executive Summary

**Verdict:** ✅ **APPROVE WITH DELIVERABLES**

New users should start with ONE channel (Discord recommended) and expand later. The production multi-agent, multi-channel setup is powerful but overwhelming. This review provides concrete templates to bridge beginners to power users.

**Key Insight:** Channel configuration is where "technical founders" hit a wall. They can run a bash script, but "create a Discord bot" is foreign territory. We need step-by-step hand-holding with screenshots-in-words.

---

## 1. Minimum Viable Discord Setup

**For a beginner, the absolute minimum is:**

1. **One Discord server** (can be private, just you + your bot)
2. **One channel** (#general or similar)
3. **One bot account** with basic permissions
4. **Bot token** in openclaw.json
5. **Channel allowlist** with `requireMention: false` (so bot responds without @-mentions)

**That's it.** No guilds object complexity. No multi-agent bindings. No specialized channels.

**What this enables:**
- Chat with your bot like it's a person in Discord
- File sharing (paste code, images, logs)
- Rich formatting (code blocks, embeds)
- Persistent history (unlike CLI sessions)

**Grows into:**
- Add specialized channels later (`requireMention: true` for topic-specific work)
- Add more agents with separate bot accounts
- Enable iMessage/Telegram for mobile alerts

---

## 2. Discord Bot Creation Guide (Non-Technical Users)

### Step-by-Step: Create Your Discord Bot

**Time estimate:** 10 minutes  
**Prerequisites:** A Discord account (free)

---

#### Step 1: Create a Discord Server (If You Don't Have One)

1. Open Discord (desktop or web: https://discord.com)
2. On the left sidebar, click the **"+" button** (Add a Server)
3. Choose **"Create My Own"**
4. Choose **"For me and my friends"** (or skip this question)
5. Name it something like **"My AI Workspace"**
6. Click **Create**

**You now have a private server.** By default, it has a #general channel. That's perfect.

---

#### Step 2: Create a Bot Account

1. Go to the **Discord Developer Portal**: https://discord.com/developers/applications
2. Click **"New Application"** (top right)
3. Name your bot (e.g., "Watson", "Claude", "MyBot")
4. Click **Create**

**You've created an application. Now turn it into a bot:**

5. On the left sidebar, click **"Bot"**
6. Click **"Add Bot"** → Confirm with **"Yes, do it!"**
7. Your bot now exists! But it's not in your server yet.

---

#### Step 3: Get Your Bot Token (THIS IS CRITICAL)

1. Still on the **Bot** page in the Developer Portal
2. Under the bot's username, you'll see **"TOKEN"**
3. Click **"Reset Token"** → Confirm
4. A long string appears (starts with `MTQ...` or similar)
5. **Copy this immediately** — you can only see it once
6. **DO NOT SHARE THIS TOKEN.** It's like a password for your bot.

**Save it somewhere safe** (you'll paste it into openclaw.json in a moment).

---

#### Step 4: Set Bot Permissions

Still in the Developer Portal:

1. On the left sidebar, click **"Bot"**
2. Scroll down to **"Privileged Gateway Intents"**
3. Enable these three toggles:
   - ✅ **PRESENCE INTENT** (optional, but harmless)
   - ✅ **SERVER MEMBERS INTENT** (helps with group chats)
   - ✅ **MESSAGE CONTENT INTENT** (required to read messages)
4. Click **"Save Changes"**

**Why these matter:** Without MESSAGE CONTENT INTENT, your bot can't read what you say. Discord blocks it for privacy.

---

#### Step 5: Invite Your Bot to Your Server

1. On the left sidebar, click **"OAuth2"** → **"URL Generator"**
2. Under **SCOPES**, check:
   - ✅ `bot`
3. Under **BOT PERMISSIONS**, check:
   - ✅ `Send Messages`
   - ✅ `Read Messages/View Channels`
   - ✅ `Read Message History`
   - ✅ `Attach Files`
   - ✅ `Embed Links`
   - ✅ `Add Reactions` (optional, for acknowledgments)
4. Scroll down, **copy the Generated URL**
5. Paste it into your browser, press Enter
6. Select **your server** from the dropdown
7. Click **Authorize** → Complete the CAPTCHA

**Your bot is now in your server!** You'll see it in the member list (offline/gray).

---

#### Step 6: Get Your Channel ID

1. In Discord, go to **User Settings** (gear icon, bottom left)
2. Go to **Advanced** (under "App Settings")
3. Enable **Developer Mode** → Close settings
4. Right-click your **#general channel** (or whichever channel you want to use)
5. Click **"Copy Channel ID"**
6. Paste it somewhere — you'll need this for openclaw.json

**Example ID:** `1024127507055775808` (18-digit number)

---

#### Step 7: Get Your Server ID (Guild ID)

1. Right-click your **server icon** (top left of the channel list)
2. Click **"Copy Server ID"**
3. Save this too

**Example ID:** `1024127505151565864`

---

### ✅ Checklist: You Should Now Have

- [ ] Bot token (long string starting with `MTQ...`)
- [ ] Channel ID (18-digit number)
- [ ] Server/Guild ID (18-digit number)
- [ ] Bot is in your server (visible in member list)

**Next step:** Configure openclaw.json (see Section 3 below)

---

## 3. Default Channel Config (JSON Snippet)

**Paste this into your `~/.openclaw/openclaw.json` file.**

Replace the placeholders:
- `YOUR_BOT_TOKEN_HERE` → The token from Step 3
- `YOUR_GUILD_ID_HERE` → Your server ID from Step 7
- `YOUR_CHANNEL_ID_HERE` → Your channel ID from Step 6
- `YOUR_DISCORD_USER_ID` → Right-click your name in Discord → Copy User ID

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "allowlist",
      "accounts": {
        "default": {
          "token": "YOUR_BOT_TOKEN_HERE",
          "allowBots": false,
          "groupPolicy": "allowlist",
          "dm": {
            "policy": "pairing",
            "allowFrom": ["YOUR_DISCORD_USER_ID"]
          },
          "guilds": {
            "YOUR_GUILD_ID_HERE": {
              "slug": "my-workspace",
              "reactionNotifications": "own",
              "channels": {
                "YOUR_CHANNEL_ID_HERE": {
                  "allow": true,
                  "requireMention": false,
                  "users": ["YOUR_DISCORD_USER_ID"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

**What this config does:**

- `"enabled": true` → Turns on Discord integration
- `"requireMention": false` → Bot responds to every message in this channel (no need to @-mention)
- `"users": [...]` → Only you can talk to the bot (add more user IDs later if needed)
- `"dm": { "policy": "pairing", "allowFrom": [...] }` → Bot accepts DMs from you only

**To restart OpenClaw and load the config:**

```bash
openclaw gateway restart
```

**To test:**
1. Open Discord, go to your channel
2. Type: `hello`
3. Your bot should respond!

---

## 4. Discord Permissions (Minimum Viable)

**These are the ONLY permissions your bot needs to function:**

| Permission | Why It's Needed |
|------------|----------------|
| `View Channels` | Bot can see the channel exists |
| `Send Messages` | Bot can reply to you |
| `Read Message History` | Bot can see context from earlier in the conversation |
| `Attach Files` | Bot can send images, code files, logs |
| `Embed Links` | Bot can format rich messages (embeds, previews) |

**Optional (but recommended):**

| Permission | Why It's Nice |
|------------|---------------|
| `Add Reactions` | Bot can acknowledge messages with ✅ emoji |
| `Use External Emojis` | If you add custom emojis later |

**DO NOT enable:**
- Administrator (way too broad)
- Manage Server (not needed)
- Manage Channels (not needed)
- Kick/Ban Members (not needed)

**If you already gave "Administrator" during invite:**
- Go to Server Settings → Roles
- Find your bot's role
- Uncheck "Administrator"
- Check only the specific permissions listed above

---

## 5. "I Don't Use Discord" Path (Telegram Alternative)

### Telegram: The Simpler (But Less Tested) Option

**Telegram is easier to set up than Discord, but less battle-tested in production.**

**Pros:**
- ✅ Faster bot creation (2 steps vs 7)
- ✅ Better mobile experience
- ✅ Simpler permission model
- ✅ Built-in file sharing

**Cons:**
- ❌ Less rich formatting (no embeds, limited markdown)
- ❌ No threading support
- ❌ Less tested in multi-agent workflows
- ❌ Harder to set up multiple bots (one phone number = one bot)

---

### How to Create a Telegram Bot (Quick Version)

1. **Open Telegram**, search for `@BotFather` (official bot creation bot)
2. Send: `/newbot`
3. Answer the questions:
   - **Bot name:** "My AI Assistant"
   - **Bot username:** Something unique ending in `bot` (e.g., `myworkspace_bot`)
4. BotFather gives you a **token** (looks like `123456:ABC-DEF...`)
5. **Save this token** — you'll paste it into openclaw.json

**To configure:**

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "YOUR_TELEGRAM_BOT_TOKEN",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  }
}
```

**To get your Telegram User ID:**
1. Search for `@userinfobot` in Telegram
2. Send: `/start`
3. It replies with your user ID (e.g., `711729701`)
4. Add this to `allowFrom` if you want to restrict access

**To test:**
1. Search for your bot's username in Telegram
2. Send: `/start`
3. Then: `hello`
4. Bot should respond

---

### When to Choose Telegram Over Discord

**Choose Telegram if:**
- You already use Telegram daily (less friction)
- You primarily work from mobile
- You don't need rich formatting or threading
- You want the simplest possible setup

**Choose Discord if:**
- You work from desktop primarily
- You want rich code formatting and file previews
- You plan to add multiple agents later
- You want channel-based organization (#work, #research, etc.)

**You can have both!** The configs don't conflict. Many power users run Discord for desktop work and Telegram for mobile alerts.

---

## 6. Copy-Paste Prompt: Channel Setup Walkthrough

**Give this prompt to your bot AFTER you've created the Discord bot account.**

This prompt walks the bot through configuring the channel integration with you.

---

### 📋 Prompt: Help Me Set Up Discord Integration

```
I've created a Discord bot and want to connect it to OpenClaw. Let's configure it together.

I have:
- My bot token: [PASTE YOUR TOKEN HERE]
- My Discord server (guild) ID: [PASTE YOUR GUILD ID]
- The channel ID I want to use: [PASTE YOUR CHANNEL ID]
- My Discord user ID: [PASTE YOUR USER ID]

Please:
1. Read my current openclaw.json file at ~/.openclaw/openclaw.json
2. Update the "channels" → "discord" section with my bot details
3. Set "requireMention": false for my channel (so I don't need to @-mention you)
4. Add my user ID to the "users" allowlist
5. Show me the changes before writing them
6. Write the updated config to ~/.openclaw/openclaw.json
7. Restart the gateway with: openclaw gateway restart
8. Confirm the bot is connected

After that, test the connection by sending a message to my Discord channel. If you see my message and respond, we're good!

If anything goes wrong, check the gateway logs:
tail -f ~/.openclaw/logs/gateway.log
```

---

**Alternative (Minimal) Version:**

If you're comfortable editing JSON yourself, just ask:

```
Show me a minimal Discord config for openclaw.json. I'll fill in my own token and IDs.
```

The bot will output the JSON snippet from Section 3, ready to paste.

---

## 7. What's Missing (Gaps in Current Templates)

**The existing ClawStarter templates are missing:**

1. **Channel configuration examples** → This review addresses it
2. **Visual guides** → Would be great to have screenshots, but text descriptions work for MVP
3. **Troubleshooting section** → "Bot is offline" / "Bot doesn't respond" / "Permission errors"
4. **Multi-agent setup** → How to add a second bot (Librarian pattern)
5. **iMessage setup** → For Mac users who want mobile alerts

**Recommendation:** Start with Discord-only template. Add Telegram, iMessage, and multi-agent guides as "Advanced Topics" in a separate doc.

---

## 8. Integration with Existing ClawStarter Flow

**Where this fits in the install.sh flow:**

1. User runs `install.sh` (handles OpenClaw installation, API key setup)
2. Bot creates workspace files from templates (AGENTS.md, SOUL.md, etc.)
3. **NEW:** Bot asks: "Do you want to set up a messaging channel now?"
   - Yes → Guide them through Discord bot creation (this review's guide)
   - No → Skip for now, provide link to guide for later
4. User pastes channel config into openclaw.json (or bot does it for them)
5. Gateway restart
6. Test message in Discord
7. ✅ Setup complete

**Alternative (less hand-holding):**

- Include the Discord setup guide in the companion page's "Post-Install" section
- Let users self-serve when they're ready
- Provide the copy-paste prompt in a "Quick Start" box

---

## 9. Template Files to Include in ClawStarter

**Additions needed in `~/.openclaw/apps/clawstarter/templates/`:**

### New File: `channel-configs/discord-minimal.json`

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "allowlist",
      "accounts": {
        "default": {
          "token": "YOUR_BOT_TOKEN_HERE",
          "allowBots": false,
          "groupPolicy": "allowlist",
          "dm": {
            "policy": "pairing",
            "allowFrom": ["YOUR_DISCORD_USER_ID"]
          },
          "guilds": {
            "YOUR_GUILD_ID_HERE": {
              "slug": "my-workspace",
              "reactionNotifications": "own",
              "channels": {
                "YOUR_CHANNEL_ID_HERE": {
                  "allow": true,
                  "requireMention": false,
                  "users": ["YOUR_DISCORD_USER_ID"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

---

### New File: `channel-configs/telegram-minimal.json`

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "YOUR_TELEGRAM_BOT_TOKEN",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  }
}
```

---

### New File: `guides/discord-setup.md`

(Contains the full guide from Section 2 of this review)

---

### New File: `guides/telegram-setup.md`

(Contains the Telegram guide from Section 5)

---

### Update: `workspace-scaffold-prompt.md`

Add this section after the personalization questions:

```markdown
## Optional: Channel Integration

Would you like to set up a messaging channel (Discord or Telegram) now? This lets you chat with me through a messaging app instead of just the terminal.

**Recommended:** Discord (best formatting, multi-agent support)  
**Alternative:** Telegram (simpler setup, better for mobile)

If yes, I'll guide you through creating a bot account and configuring it.  
If no, you can always add this later by reading `guides/discord-setup.md`.
```

---

## 10. Production Patterns vs. Beginner Patterns

**Jeremy's production setup is powerful but complex:**

| Feature | Production (Watson) | Beginner Template |
|---------|---------------------|-------------------|
| **Channels** | Discord (primary) + iMessage (alerts) | Discord only |
| **Agents** | 5 bots (Watson, Librarian, Treasurer, etc.) | 1 bot |
| **Discord channels** | 15+ channels with mixed requireMention rules | 1 channel, requireMention: false |
| **Account bindings** | Multi-agent bindings per Discord account | No bindings (single agent) |
| **Message routing** | Complex allowlists, user filtering | Simple: owner only |

**The migration path (beginner → power user):**

1. **Start:** 1 bot, 1 channel, requireMention: false
2. **Add channels:** Create #research, #code-review with requireMention: true
3. **Add agents:** Create Librarian bot for research, bind to separate account
4. **Add platforms:** Enable Telegram for mobile, iMessage for urgent alerts
5. **Advanced routing:** User allowlists, channel-specific agent assignments

**Key insight:** The beginner template should feel simple but not limiting. They should be able to "graduate" to production patterns without rewriting everything.

---

## 11. Troubleshooting Guide (For Companion Page)

**Common issues beginners hit:**

### Bot is Offline (Gray in Discord)

**Cause:** Gateway isn't running, or token is wrong

**Fix:**
```bash
# Check if gateway is running
openclaw gateway status

# If not running, start it
openclaw gateway start

# Check logs for errors
tail -f ~/.openclaw/logs/gateway.log
```

**If logs show "Invalid token":**
- Double-check the token in openclaw.json
- Make sure you copied the FULL token (no spaces, no line breaks)
- Regenerate the token in Discord Developer Portal if needed

---

### Bot is Online But Doesn't Respond

**Cause:** Channel not in allowlist, or MESSAGE CONTENT INTENT disabled

**Fix:**

1. Check Developer Portal → Bot → Privileged Gateway Intents
   - ✅ MESSAGE CONTENT INTENT must be enabled
2. Check openclaw.json → channels → discord → guilds → channels
   - Your channel ID must be listed with `"allow": true`
3. Restart gateway: `openclaw gateway restart`

---

### Bot Responds Only When @-Mentioned

**Cause:** `requireMention: true` in config

**Fix:**

Edit openclaw.json, find your channel config:
```json
"YOUR_CHANNEL_ID": {
  "allow": true,
  "requireMention": false  // ← Change this to false
}
```

Restart: `openclaw gateway restart`

---

### Bot Responds to Everyone in the Server

**Cause:** No `users` allowlist in channel config

**Fix:**

Add your Discord user ID to the channel config:
```json
"YOUR_CHANNEL_ID": {
  "allow": true,
  "requireMention": false,
  "users": ["YOUR_DISCORD_USER_ID"]  // ← Add this line
}
```

Restart gateway.

---

## 12. Recommendations for ClawStarter

### P0: Must Include

1. ✅ **Discord setup guide** (Section 2) → Add to `guides/discord-setup.md`
2. ✅ **Minimal config snippet** (Section 3) → Add to `channel-configs/discord-minimal.json`
3. ✅ **Copy-paste prompt** (Section 6) → Include in companion page
4. ✅ **Troubleshooting** (Section 11) → Add to companion page "Common Issues" section

### P1: Should Include

5. ✅ **Telegram alternative** (Section 5) → Add to `guides/telegram-setup.md`
6. ✅ **Permission reference** (Section 4) → Add to Discord guide
7. ⚠️ **Visual guide** → Screenshots or annotated images (Phase 2, not MVP)

### P2: Nice to Have

8. ❌ **Multi-agent setup** → Advanced topic, separate guide
9. ❌ **iMessage setup** → Mac-only, advanced topic
10. ❌ **Migration guide** → Production patterns, advanced

---

## 13. Final Verdict

**✅ APPROVE WITH DELIVERABLES**

The ClawStarter project is missing channel integration templates. This review provides:

- ✅ Step-by-step Discord bot creation (non-technical friendly)
- ✅ Minimal viable config (copy-paste ready)
- ✅ Telegram alternative (for users who don't use Discord)
- ✅ Troubleshooting guide (common errors + fixes)
- ✅ Copy-paste prompt (bot can configure itself)

**What makes this beginner-friendly:**

1. **No assumptions** → Explains every step, including "right-click"
2. **Concrete examples** → Real IDs, real tokens (sanitized), real config
3. **One path to success** → Discord first, alternatives later
4. **Error-resilient** → Troubleshooting built in
5. **Scales up** → Same config structure as production

**Integration with PRISM Round 1:**

- Companion page should have a "Post-Install: Add a Channel" section
- Include the Discord guide as an expandable accordion
- Provide the config snippet with one-click copy
- Link to troubleshooting if setup fails

**Next step:** Merge these templates into ClawStarter repo, test with a fresh user, iterate on clarity.

---

## Deliverables Summary

**Files to create in `~/.openclaw/apps/clawstarter/`:**

1. `guides/discord-setup.md` — Full Discord bot creation walkthrough
2. `guides/telegram-setup.md` — Telegram alternative guide
3. `channel-configs/discord-minimal.json` — Copy-paste config snippet
4. `channel-configs/telegram-minimal.json` — Telegram config snippet
5. `troubleshooting/channels.md` — Common channel setup issues

**Updates to existing files:**

- `workspace-scaffold-prompt.md` → Add optional channel setup section
- Companion page (when built) → Include "Add a Channel" post-install step

**Copy-paste prompts** (for companion page):

- "Help me set up Discord integration" (Section 6)
- "Show me a minimal Discord config" (Section 6, alternative)

---

**End of PRISM Round 3 Review**
