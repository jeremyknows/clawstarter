# X/Twitter Integration Guide

Connect your OpenClaw agent to X (Twitter) for posting, searching, and engagement.

---

## Quick Start

### 1. Create X Developer App

1. Go to [developer.x.com](https://developer.x.com)
2. Create a project and app
3. Configure **User authentication settings**:
   - **App permissions:** Read and Write
   - **Type:** Web App, Automated App or Bot
   - **Callback URL:** `http://localhost:3000/callback`

### 2. Get OAuth 2.0 Credentials

Copy from the Developer Portal:
- Client ID
- Client Secret

### 3. Authorize Your App

Run the setup script:

```bash
cd ~/.openclaw/workspace/scripts
node x-oauth2-authorize.js
```

Follow the prompts to authorize and get your refresh token.

### 4. Save Credentials

Add to your environment (`.zshrc` or `.env`):

```bash
export X_OAUTH2_CLIENT_ID="your-client-id"
export X_OAUTH2_CLIENT_SECRET="your-client-secret"
export X_OAUTH2_REFRESH_TOKEN="your-refresh-token"
```

### 5. Test

```bash
node scripts/x-post-v2.js tweet "Hello from OpenClaw! 🦞"
```

---

## Why OAuth 2.0?

**Always use OAuth 2.0.** OAuth 1.0a has known issues:

| Issue | OAuth 1.0a | OAuth 2.0 |
|-------|------------|-----------|
| Long tweets | ❌ 403 errors | ✅ Works |
| Rate limits | 200/3hrs | 300/3hrs |
| Complexity | High (signatures) | Low (Bearer token) |
| Status | Deprecated | ✅ Recommended |

---

## Required Scopes

Request these scopes during authorization:

```
tweet.read tweet.write users.read offline.access
```

Optional for DMs:
```
dm.read dm.write
```

The `offline.access` scope is **critical** — it gives you a refresh token that never expires.

---

## Troubleshooting 403 Errors

Even with OAuth 2.0, X's content moderation can block posts. Known triggers:

### Trigger Patterns

| ❌ Triggers 403 | ✅ Safe Alternative |
|-----------------|---------------------|
| "How could this be exploited?" | "What could break?" |
| "What are the attack vectors?" | "What are the risks?" |
| Question marks in numbered lists | Use periods instead |
| Multiple "!!!" or "???" | Single punctuation |

### Example Fix

```
❌ BLOCKED:
"PRISM Review:
1. Security: How could this be exploited?
2. Performance: What's the impact?"

✅ WORKS:
"PRISM Review:
1. Security: What could go wrong
2. Performance: What's the impact"
```

### Other 403 Causes

- **Duplicate content** — Add a timestamp: `text + [${Date.now()}]`
- **Account restricted** — Check account status in X settings
- **Missing scopes** — Verify `tweet.write` scope in token

---

## Search Skills

ClawStarter includes two X search options:

### Option 1: Grok Search (AI-Synthesized)

Best for: Quick answers, "What are people saying about X?"

```bash
# Requires XAI_API_KEY
# Uses xAI's Grok model to synthesize results
```

Features:
- AI-synthesized answers with citations
- Image/video understanding
- Combined web + X search
- Handle/domain filtering

### Option 2: X Research (Raw Results)

Best for: Deep research, precise filtering, watchlist monitoring

```bash
cd ~/.openclaw/skills/x-research
bun run x-search.ts search "OpenClaw" --sort likes --limit 10
```

Features:
- Full X search operator support
- CLI with caching
- Watchlist monitoring
- Thread retrieval
- Profile analysis

### When to Use Which

| Task | Use |
|------|-----|
| "What's the sentiment on X about Y?" | Grok |
| "Find all tweets from @user about Z" | X Research |
| "Give me a summary of reactions" | Grok |
| "I need raw tweets for analysis" | X Research |
| "Search with image understanding" | Grok |
| "Monitor specific accounts" | X Research |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Posts | 300 / 3 hours |
| User lookup | 300 / 15 min |
| Search | 450 / 15 min |

Track rate limit headers in responses:
- `x-rate-limit-limit`
- `x-rate-limit-remaining`
- `x-rate-limit-reset`

---

## Files Reference

```
~/.openclaw/workspace/scripts/
├── x-oauth2-manager.js     # Token refresh, auth
├── x-oauth2-authorize.js   # Initial setup
├── x-post-v2.js            # Post tweets (OAuth 2.0)
└── x-post.js               # Legacy (OAuth 1.0a fallback)

~/.openclaw/skills/
├── grok-1.0.3/             # AI-mediated search
└── x-research-skill/       # Direct API search
```

---

## Pro Tips

1. **Add "Automated by" label** — Go to X Settings → Account → Automation → Add label
2. **Use refresh tokens** — Never hardcode access tokens (they expire in 2 hours)
3. **Rephrase security content** — Avoid trigger words in PRISM-style reviews
4. **Cache search results** — x-research-skill has 15-min TTL cache built in

---

## Resources

- [X OAuth 2.0 Docs](https://docs.x.com/x-api/authentication/oauth-2-0)
- [Developer Portal](https://developer.x.com)
- [xAI API Docs](https://docs.x.ai) (for Grok search)
