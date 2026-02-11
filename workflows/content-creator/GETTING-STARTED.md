# Getting Started: Content Creator

Welcome! This template gives you an AI assistant optimized for content creation. Let's get you productive in 5 minutes.

## Prerequisites

Before you start, make sure you have:
- ✅ **macOS** (these templates are Mac-specific)
- ✅ **Homebrew** installed ([get it here](https://brew.sh) if not)
- ✅ **OpenClaw** running (gateway started)
- ✅ **Basic terminal comfort** (copy/paste commands)

## Quick Setup (2 minutes)

### 1. Install Skills
```bash
bash ~/Downloads/openclaw-setup/workflows/content-creator/skills.sh
```

### 2. Set API Keys (Optional but Recommended)
```bash
# For video/article summarization
export GEMINI_API_KEY="your-key"

# For audio transcription  
export OPENAI_API_KEY="your-key"

# Add to ~/.zshrc to persist
```

### 3. Copy Agent Instructions
```bash
cp ~/Downloads/openclaw-setup/workflows/content-creator/AGENTS.md ~/.openclaw/workspace/
```

## ✅ Verify Your Setup

Run these commands to confirm everything works:

```bash
# 1. Check skills installed
which gifgrep && echo "✅ gifgrep ready"
which summarize && echo "✅ summarize ready"

# 2. Verify API key (for summarize)
[ -n "$GEMINI_API_KEY" ] || [ -n "$OPENAI_API_KEY" ] && echo "✅ API key set" || echo "⚠️ No API key - summarize won't work"

# 3. Check workspace folders
ls ~/.openclaw/workspace/content/ && echo "✅ Folders created"
```

**What success looks like:**
```
✅ gifgrep ready
✅ summarize ready
✅ API key set
ideas  drafts  published  analytics
✅ Folders created
```

## Your First Win (3 minutes)

Try these to see immediate value:

### Summarize a Video
> "Summarize this video and give me the key takeaways: [YouTube URL]"

### Find a Reaction GIF
> "Find me a 'chef's kiss' GIF for a tweet about great code"

### Generate an Image
> "Generate an image of a cozy home office with morning light"

### Research a Trend
> "What are people on X saying about [topic]? Give me the main takes."

## Sample Workflows

### Podcast Episode Prep
1. "Transcribe this audio file: ~/recordings/episode-42.mp3"
2. "Summarize the key points and interesting quotes"
3. "Draft 5 tweet threads promoting this episode"

### Content Ideation
1. "Research trending topics in [your niche] on X this week"
2. "What angles haven't been covered yet?"
3. "Help me outline a video on [chosen topic]"

### Social Media Batch
1. "I have 30 minutes. Help me draft a week of tweets on [theme]"
2. "Generate 3 image options for each post"
3. "What hashtags should I use?"

## Recommended Cron Jobs

These automations run in the background:

| Job | Frequency | Purpose |
|-----|-----------|---------|
| content-ideas | Daily 8 AM | Surface trending topics in your niche |
| trend-monitor | Every 4h | Alert on viral content opportunities |
| engagement-check | Daily 6 PM | Summarize today's engagement metrics |
| weekly-analytics | Sunday 9 AM | Weekly performance report |

Enable them:
```bash
openclaw cron import ~/Downloads/openclaw-setup/workflows/content-creator/crons/
```

## Folder Structure

Create these for organization:
```
~/.openclaw/workspace/
├── content/
│   ├── ideas/        # Running idea log
│   ├── drafts/       # Work in progress
│   └── published/    # Archive
├── images/
│   └── 2026-02/      # Generated images by month
└── transcripts/      # Audio/video transcripts
```

## Tips for Success

### Be Specific About Your Brand
The more your agent knows about your style, the better:
> "My brand is minimalist, slightly sarcastic, tech-focused. I use short sentences. Never use emojis in headlines."

### Save Good Prompts
When a prompt works well, save it:
> "Save this to my prompt library: [the prompt that worked]"

### Let It Do First Passes
Use your agent for first drafts, then add your voice:
> "Write 5 tweet options about [topic], I'll pick and polish"

### Review, Don't Automate Posting
Always review before posting. Your agent drafts, you publish.

## Next Steps

1. ✅ Complete the first win exercise above
2. 📝 Edit AGENTS.md with your specific brand voice
3. 🔧 Enable the cron jobs you want
4. 📊 Set up analytics tracking (optional)

---

*Questions? Ask your agent: "How do I use the content creator template?"*
