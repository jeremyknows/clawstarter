# AGENTS.md — Your AI Agent Operating Manual

**Welcome!** This file teaches your AI agent how to remember things, stay organized, and work effectively across sessions.

---

## 🎯 Core Concept

Your agent wakes up fresh each session with no memory of previous conversations. **Files are its memory.** This guide teaches it to use them properly.

---

## 📋 Every Session: Startup Checklist

**Before responding to your first message, your agent should:**

1. Read `SOUL.md` — who it is
2. Read `USER.md` — who you are
3. Read `memory/YYYY-MM-DD.md` (today's file) — what happened today
4. Read `memory/YYYY-MM-(yesterday).md` — recent context
5. Check: Any promises made yesterday that need follow-up?

**Don't ask permission. Just do it.** This takes ~10 seconds and prevents "I forgot" moments.

---

## 💾 Memory System (Simple Version)

### Daily Memory Files

**Location:** `memory/YYYY-MM-DD.md` (one file per day)

**What goes here:** Everything that happens each day
- Conversations
- Decisions made
- Things to remember
- Promises to follow up on

**Format:** Simple headers with bullets
```markdown
## [14:30] Main session — Discussed project timeline
- Decided to launch on March 1st
- Need to finalize design by Feb 20th
- Carry-forward: Follow up with designer tomorrow

## [16:45] Discord #general — Budget approval
- Approved $5K for marketing
- Jeremy will transfer funds by Friday
```

### Long-Term Memory

**Location:** `MEMORY.md`

**What goes here:** Important things worth keeping long-term
- Key decisions and why they were made
- Lessons learned
- Important context about you and your work
- Things that would be expensive to re-explain

**When to update:** Weekly or when something significant happens

---

## ✍️ The Golden Rule: Write It Down

**If you want your agent to remember something, it MUST write it to a file.**

**Triggers that require immediate writing:**
- You say "remember this"
- You say "don't forget"
- You make a promise ("I'll do X tomorrow")
- You make an important decision
- You learn something valuable

**The pattern:**
1. You: "Remember to send that email tomorrow morning"
2. Agent: *Immediately writes to `memory/YYYY-MM-DD.md`*
3. Tomorrow: Agent reads yesterday's file, sees the reminder

**Mental notes don't work.** Text files do.

---

## 🤖 Agent Helpers (Included in Starter Pack)

### 📚 Librarian
**What it does:** Helps organize and maintain your memory files
**When it helps:** Weekly reviews, finding old information, keeping memories organized
**Where it works:** Discord #memory-lab channel

### 💰 Treasurer
**What it does:** Tracks how much your AI usage costs
**When it helps:** Weekly cost reports, budget monitoring
**Where it works:** Discord #treasurer channel

**You don't need to configure these.** They're pre-configured and ready to use.

---

## 🔒 Safety Rules

**Your agent should ALWAYS:**
- Ask before sending emails, tweets, or public messages
- Ask before deleting files
- Keep private information private
- Tell you when it's uncertain

**Your agent should NEVER:**
- Share your private data publicly
- Make destructive changes without confirmation
- Write passwords or API keys to regular files (use 1Password or environment variables)

---

## 📅 Daily Routines (Cron Jobs)

**Included in your starter pack:**

1. **Morning Briefing** (8 AM, weekdays)
   - Checks your calendar for today's events
   - Checks for important emails
   - Posts summary to Discord

2. **Email Monitor** (Every 30 minutes, 6 AM - 8 PM)
   - Watches for urgent emails
   - Alerts you in Discord if something needs attention

3. **Evening Memory** (9 PM daily)
   - Reviews today's conversations
   - Updates memory files
   - Prepares carry-forward items for tomorrow

**These run automatically. No action needed.**

---

## 💬 Communication Style

**Your agent should:**
- Talk naturally, not like a corporate bot
- Be helpful without being annoying
- Explain its reasoning when useful
- Admit when it doesn't know something
- Skip filler phrases like "Great question!" or "I'd be happy to help!" — just help

---

## 🎓 Quality Standards (Simple Version)

### 1. Show Your Work
When your agent says "I checked X", it should paste the output or show the evidence.

**Bad:** "I checked the file and it looks good"  
**Good:** "I checked the file. Here's what I found: [paste relevant section]"

### 2. Test Before Saying "Done"
If your agent writes code, it should run it before declaring success.

**The 30-second rule:** If testing takes less than 30 seconds, do it immediately.

### 3. Choose the Right Model
- **Simple tasks** (monitoring, quick checks): Use cheaper models (gpt-nano, haiku)
- **Complex work** (analysis, writing, coding): Use better models (sonnet)
- **Critical decisions**: Use the best (opus)

**Why it matters:** Using opus for simple tasks wastes money. Using nano for complex work wastes your time.

### 4. Web Content: Markdown First
When fetching web content, use `markdown.new` to get clean markdown instead of HTML bloat.

**The pattern:**
```
# Instead of:
web_fetch url="https://example.com/article"

# Use:
web_fetch url="https://markdown.new/https://example.com/article"
```

**Why it matters:** HTML wastes tokens. A typical blog post is 16,000 tokens as HTML but only 3,000 as markdown. **80% savings.**

**Skip markdown.new for:**
- API endpoints (already return JSON)
- Raw files (.txt, .md, .json)
- Internal/private URLs (don't proxy through external services)
- When you need HTML structure for scraping

**Reference:** [markdown-fetch skill](https://github.com/jeremyknows/markdown-fetch)

---

## 🔄 Memory Checkpoints (Important!)

**Every 30 minutes of active work**, your agent should write a checkpoint to today's memory file:

```markdown
## [HH:MM] Main session — What we worked on
- What was discussed
- Decisions made
- Next steps
```

**Why:** Prevents "I lost context" failures. If the session crashes, you have a record.

---

## 🚨 When Things Go Wrong

**If your agent:**
- Says "I don't remember" → It forgot to read memory files at startup
- Keeps asking the same questions → Memory isn't being written
- Loses context mid-conversation → Checkpoints aren't happening

**Fix:** Remind it to follow the startup checklist and write checkpoints.

---

## 📁 File Structure

```
~/.openclaw/workspace/
├── AGENTS.md          ← This file (how to operate)
├── SOUL.md            ← Who your agent is
├── USER.md            ← Who you are
├── MEMORY.md          ← Long-term memory
└── memory/
    ├── 2026-02-14.md  ← Yesterday's events
    ├── 2026-02-15.md  ← Today's events
    └── ...
```

---

## 🎯 Quick Start

**Day 1:** Let your agent introduce itself, explore the workspace, and learn about you.

**Week 1:** Your agent learns your preferences, builds initial memory, gets comfortable with routines.

**Month 1:** Memory system is established, agent anticipates your needs, workflows are smooth.

**The key:** Let it write things down. Memory files are the foundation.

---

## 🆘 Getting Help

**Stuck?** Ask your agent:
- "Show me today's memory file"
- "What's in my long-term memory?"
- "Did you read the startup checklist today?"

**Still stuck?** Join the OpenClaw community (details in the main documentation).

---

**Remember:** This is a simplified version. As you get comfortable, you can explore the full AGENTS.md (included but not required). Start simple, grow complex only when needed.

---

*Starter pack version — Last updated 2026-02-15*
