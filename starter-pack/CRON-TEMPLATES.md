# Starter Pack Cron Job Templates

**These are the exact cron jobs included in ClawStarter, with prompts simplified from our production versions.**

---

## Template Format

Each template includes:
- **Schedule** — When it runs
- **Model** — Which AI model to use
- **Timeout** — Max execution time
- **Delivery** — Where results go
- **Prompt** — Exact instructions for the agent

---

## 1. Morning Briefing

**Purpose:** Start your day with a quick overview of what's ahead.

```json
{
  "name": "morning-briefing",
  "schedule": {
    "kind": "cron",
    "expr": "0 8 * * 1-5",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "🌅 Morning briefing time.\n\nCheck:\n1. **Calendar** — Any events in the next 24 hours? (Use calendar tool or gog if configured)\n2. **Email** — Any unread urgent emails? (Check inbox, look for VIPs or urgent keywords)\n3. **Weather** — What's the forecast for today? (Use wttr.in or weather API)\n\nFormat your briefing:\n- **Today's Events:** [list with times, or \"No events scheduled\"]\n- **Urgent Email:** [count + subjects, or \"Inbox clear\"]\n- **Weather:** [brief forecast]\n\nKeep it concise (<10 lines). Post to Discord #general or write to memory/YYYY-MM-DD.md if Discord unavailable.\n\nAt end, write checkpoint:\n## [HH:MM] main:cron:morning-briefing — Daily briefing\n- **Result:** success\n- **Notable:** [event count, urgent emails, weather]",
    "model": "openrouter/google/gemini-2.5-flash-lite",
    "timeoutSeconds": 180
  },
  "delivery": {
    "mode": "announce",
    "channel": "discord",
    "to": "REPLACE_WITH_CHANNEL_ID"
  },
  "enabled": true
}
```

**Schedule:** 8 AM, Monday-Friday  
**Model:** gemini-lite (~$0.001/run)  
**Why this model:** Simple daily task, frequent use, cost-effective

---

## 2. Email Monitor

**Purpose:** Alert you when important emails arrive (without checking every single one).

```json
{
  "name": "email-monitor",
  "schedule": {
    "kind": "cron",
    "expr": "*/30 6-20 * * *",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "📧 Email check (quick scan).\n\nLook for:\n1. Unread emails from VIPs (boss, clients, important contacts)\n2. Subject lines with urgent keywords: URGENT, ASAP, IMPORTANT, ACTION REQUIRED\n3. Meeting invites needing response today\n\nIf you find anything urgent:\n- Post alert to Discord with: From, Subject, Preview\n- Write to memory: ## [HH:MM] main:cron:email-monitor — Urgent email detected\n\nIf inbox is calm:\n- Return HEARTBEAT_OK (no message needed)\n- Write to memory: ## [HH:MM] main:cron:email-monitor — No urgent email\n\nDon't report every email. Only urgent items.",
    "model": "openrouter/openai/gpt-5-nano",
    "timeoutSeconds": 120
  },
  "delivery": {
    "mode": "announce",
    "channel": "discord",
    "to": "REPLACE_WITH_CHANNEL_ID"
  },
  "enabled": true
}
```

**Schedule:** Every 30 minutes, 6 AM - 8 PM  
**Model:** gpt-nano (~$0.0001/run)  
**Why this model:** Simple pattern matching, runs frequently, ultra-cheap

**Note:** Returns HEARTBEAT_OK when nothing urgent (won't spam you with "no new email" messages).

---

## 3. Evening Memory Review

**Purpose:** End of day review — what happened, what carries forward to tomorrow.

```json
{
  "name": "evening-memory",
  "schedule": {
    "kind": "cron",
    "expr": "0 21 * * *",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "🌙 Evening memory review.\n\n**Your tasks:**\n1. Read memory/YYYY-MM-DD.md (today's file)\n2. Identify:\n   - Important decisions made today\n   - Promises to follow up on (\"I'll do X tomorrow\")\n   - Significant events worth remembering long-term\n3. Check if MEMORY.md needs updating (if today had major events)\n4. List carry-forward items for tomorrow\n\n**Write to today's memory file:**\n## [21:00] main:cron:evening-memory — Daily review\n- **Key events:** [list 2-3 most important things]\n- **Carry-forward:** [items for tomorrow, or \"None\"]\n- **Memory updated:** [yes/no]\n\n**If MEMORY.md needs update:** Add significant learnings/context to long-term memory.\n\n**If nothing significant happened:** Still write checkpoint (helps track quiet days too).",
    "model": "anthropic/claude-haiku-3-5",
    "timeoutSeconds": 300
  },
  "delivery": {
    "mode": "silent"
  },
  "enabled": true
}
```

**Schedule:** 9 PM daily  
**Model:** haiku (~$0.003/run)  
**Delivery:** Silent (writes to memory, no message unless error)  
**Why this model:** Requires some reasoning (cross-file context), but not complex enough for sonnet

---

## 4. Weekly Cost Report (Treasurer)

**Purpose:** Friday afternoon budget check — how much did you spend this week?

```json
{
  "name": "treasurer-weekly-report",
  "schedule": {
    "kind": "cron",
    "expr": "0 17 * * 5",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "💰 Weekly cost report time.\n\n**Steps:**\n1. Run: `treasurer status` (gets weekly totals)\n2. Run: `treasurer sessions --period week` (top spenders)\n3. Calculate week-over-week change (compare to last week if data available)\n\n**Format your report:**\n# 💰 Weekly Cost Report — Week Ending YYYY-MM-DD\n\n**Summary**\n- Total Spend: $XX.XX (+/- X% vs last week)\n- Request Count: X,XXX requests\n- Avg Cost/Request: $X.XX\n\n**Top 3 Spenders This Week**\n1. Session/Channel Name — $XX.XX (X,XXX requests)\n2. Session/Channel Name — $XX.XX (X,XXX requests)\n3. Session/Channel Name — $XX.XX (X,XXX requests)\n\n**Notable Events**\n- [Any unusual spikes, new channels, or cost anomalies]\n\n---\n*Next report: [date]*\n\nPost to Discord #treasurer (or #general if treasurer channel unavailable).\n\n**Also write to memory:**\n## [17:00] treasurer:cron:weekly-report — Cost summary\n- **Result:** success\n- **Notable:** Week total $XX.XX, top spender [name]",
    "model": "openrouter/google/gemini-2.5-flash-lite",
    "timeoutSeconds": 240
  },
  "delivery": {
    "mode": "announce",
    "channel": "discord",
    "to": "REPLACE_WITH_TREASURER_CHANNEL_ID"
  },
  "enabled": true
}
```

**Schedule:** 5 PM every Friday  
**Model:** gemini-lite (~$0.002/run)  
**Why this model:** Requires some formatting/calculation, but straightforward reporting task

**Prerequisites:**
- Treasurer CLI installed (`~/.openclaw/scripts/treasurer`)
- Treasurer sync running (extracts usage from session logs)

---

## 5. Memory Health Check (Librarian)

**Purpose:** Weekly checkup on your memory system — is it healthy or getting messy?

```json
{
  "name": "librarian-health-check",
  "schedule": {
    "kind": "cron",
    "expr": "0 20 * * 0",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "📚 Weekly memory health check.\n\n**Scan the past week's memory files:**\n1. List all memory/YYYY-MM-DD.md files from past 7 days\n2. Quick scan for:\n   - **Duplicates:** Same info written multiple times?\n   - **Contradictions:** Conflicting statements?\n   - **Stale entries:** Old TODOs never completed?\n   - **Format compliance:** Entries using standardized headers?\n\n3. Check MEMORY.md:\n   - Last updated when?\n   - Any recent significant events that should be there?\n\n**Generate health report:**\n# 📚 Memory Health Report — YYYY-MM-DD\n\n**Files Scanned:** X files (YYYY-MM-DD through YYYY-MM-DD)\n**Health Status:** ✅ Healthy | ⚠️ Needs attention | 🔴 Issues found\n\n**Findings:**\n- Duplicates: [count or \"None found\"]\n- Contradictions: [count or \"None found\"]\n- Stale entries: [count or \"None found\"]\n- Format issues: [count or \"None found\"]\n\n**MEMORY.md Status:**\n- Last updated: [date]\n- Freshness: ✅ Current | ⚠️ Needs update\n\n**Action Items:** [List cleanup tasks, or \"No action needed\"]\n\n---\nPost to Discord #memory-lab (or #general if unavailable).\n\n**Write to memory:**\n## [20:00] librarian:cron:health-check — Weekly scan\n- **Result:** success\n- **Notable:** [health status, issues found]",
    "model": "anthropic/claude-haiku-3-5",
    "timeoutSeconds": 300
  },
  "delivery": {
    "mode": "announce",
    "channel": "discord",
    "to": "REPLACE_WITH_MEMORY_LAB_CHANNEL_ID"
  },
  "enabled": true
}
```

**Schedule:** 8 PM every Sunday  
**Model:** haiku (~$0.003/run)  
**Why this model:** Requires reading multiple files and pattern detection, but not deep reasoning

---

## Installation Notes

### Placeholders to Replace

Before deploying these cron jobs, replace:

- `REPLACE_WITH_CHANNEL_ID` → Your Discord channel ID (e.g., `#general`)
- `REPLACE_WITH_TREASURER_CHANNEL_ID` → Your `#treasurer` channel ID
- `REPLACE_WITH_MEMORY_LAB_CHANNEL_ID` → Your `#memory-lab` channel ID

**Finding Discord channel IDs:**
1. Enable Developer Mode in Discord (User Settings → Advanced)
2. Right-click channel → Copy ID

### Importing Jobs

```bash
# One by one:
openclaw cron import morning-briefing.json
openclaw cron import email-monitor.json
openclaw cron import evening-memory.json
openclaw cron import treasurer-weekly-report.json
openclaw cron import librarian-health-check.json

# Or batch import (if installer supports):
openclaw cron import-batch starter-pack/cron/
```

### Testing Before Enabling

```bash
# Dry run (doesn't actually schedule):
openclaw cron run morning-briefing --dry-run

# Real run (tests the job once):
openclaw cron run morning-briefing

# View logs:
tail -f ~/.openclaw/logs/cron-morning-briefing.log
```

### Customizing Schedules

**Cron expression syntax:**
```
* * * * *
│ │ │ │ │
│ │ │ │ └─ Day of week (0-6, Sun-Sat)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)
```

**Examples:**
- `0 8 * * 1-5` — 8 AM, Monday-Friday
- `*/30 6-20 * * *` — Every 30 min, 6 AM - 8 PM
- `0 21 * * *` — 9 PM daily
- `0 17 * * 5` — 5 PM every Friday
- `0 20 * * 0` — 8 PM every Sunday

---

## Cost Breakdown

| Cron Job | Frequency | Model | Est. Cost/Run | Runs/Month | Monthly Cost |
|----------|-----------|-------|---------------|------------|--------------|
| Morning Briefing | Weekdays 8 AM | gemini-lite | $0.001 | ~22 | $0.022 |
| Email Monitor | Every 30 min (6-20) | gpt-nano | $0.0001 | ~840 | $0.084 |
| Evening Memory | Daily 9 PM | haiku | $0.003 | ~30 | $0.090 |
| Weekly Cost Report | Fridays 5 PM | gemini-lite | $0.002 | ~4 | $0.008 |
| Memory Health | Sundays 8 PM | haiku | $0.003 | ~4 | $0.012 |

**Total starter pack cron cost:** ~$0.22/month

**Note:** These are estimates. Actual costs vary based on prompt length, response length, and usage patterns.

---

## Disabling Jobs You Don't Need

Not everyone needs all 5 jobs. Disable what you don't want:

```bash
# List all jobs
openclaw cron list

# Disable specific job
openclaw cron disable email-monitor

# Re-enable later
openclaw cron enable email-monitor

# Delete permanently
openclaw cron delete email-monitor
```

**Minimal setup:** Morning briefing + Evening memory (2 jobs)  
**Standard setup:** All 5 jobs  
**Custom setup:** Pick and choose based on your workflow

---

## Modifying Prompts

**To edit a cron prompt:**

```bash
# Export current config
openclaw cron export morning-briefing > morning-briefing.json

# Edit the "message" field
nano morning-briefing.json

# Reimport
openclaw cron import morning-briefing.json
```

**Pro tip:** Test modified prompts with `openclaw cron run [name]` before letting them run on schedule.

---

## Memory Checkpoint Requirement

**EVERY cron job MUST write to daily memory before completing.**

This is how cron jobs coordinate with your main session. Without it, their work is invisible.

**Standard format:**
```markdown
## [HH:MM] AgentId:cron:job-name — Topic
- **Result:** success|failure|partial
- **Notable:** [key findings]
```

**Why ≤512 bytes:** Ensures atomic append (no corruption from concurrent writes).

If your prompt produces >512 byte checkpoints, split into multiple entries or trim to essentials.

---

**These templates are your starting point. Modify them as you learn what works for you.**

*Last updated: 2026-02-15*
