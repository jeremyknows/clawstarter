# Security Audit Prompt — Starter Pack

**Purpose:** Have your agent audit its own setup for security issues.

**When to use:** After initial installation, monthly, or when you change configuration.

---

## The Audit Prompt

**Copy and paste this to your agent:**

```
Run a comprehensive security audit of my OpenClaw setup.

Check these areas and report status (✅ secure, ⚠️ needs attention, 🔴 vulnerable):

## 1. Credential Storage
- Are API keys stored in environment variables (not plain text files)?
- Check: ~/.openclaw/openclaw.json for exposed keys
- Check: AGENTS.md, TOOLS.md, memory files for accidentally logged credentials
- Are Discord bot tokens in env vars or 1Password?
- Are any passwords or secrets in git history?

## 2. File Permissions
- Is ~/.openclaw/workspace/ readable only by your user?
- Are memory files properly protected?
- Can other users on this computer access your agent files?
- Run: ls -la ~/.openclaw/ and verify permissions

## 3. Memory Privacy
- Is MEMORY.md excluded from Discord/group chat sessions?
- Are daily memory files (YYYY-MM-DD.md) shared across sessions correctly?
- Are private conversations staying private?
- Check AGENTS.md for session-specific memory rules

## 4. External Action Safeguards
- Does AGENTS.md require asking before sending emails?
- Does AGENTS.md require asking before posting to social media?
- Are destructive operations (deletions) protected?
- Check: Does agent use `trash` instead of `rm`?

## 5. Cron Job Safety
- List all enabled cron jobs
- Verify each uses appropriate model (not wasting money on expensive models)
- Check: Do crons have timeouts configured?
- Check: Are cron delivery targets correct (not posting to wrong channels)?
- Verify: Each cron writes to daily memory (cross-session coordination)

## 6. Discord Configuration (if enabled)
- Verify bot tokens are secure
- Check: Are bots allowed in the right channels only?
- Check: Are group chat policies configured correctly?
- Verify: Is MEMORY.md excluded from multi-participant contexts?

## 7. Shared Computer Safety
- If this is a shared computer: Are files in your home directory (~/.openclaw/)?
- Check: Can other users access your workspace?
- Verify: Are you using a dedicated user account or shared account?
- Check: Are there any world-readable files with private data?

## 8. Git Repository Safety (if workspace is in git)
- Is ~/.openclaw/workspace/.gitignore configured?
- Are memory files excluded from git (or private repo only)?
- Check git log for accidentally committed secrets
- Are API keys in .gitignore?

## 9. Backup Security
- Are backups of ~/.openclaw/ encrypted?
- If using cloud backup: Are sensitive files excluded?
- Check: Does Time Machine or backup software have access to private data?

## 10. Agent Behavior Verification
- Read SOUL.md — Does it include security boundaries?
- Read AGENTS.md startup ritual — Does it load security guidelines?
- Test: Ask agent to send a tweet (should ask permission first)
- Test: Ask agent to delete a file (should ask permission or use trash)

---

For each category, provide:
- Status: ✅ ⚠️ or 🔴
- Details: What you checked
- Issues: Specific problems found (if any)
- Remediation: How to fix issues (step-by-step)

Output format:
# 🛡️ Security Audit Report — YYYY-MM-DD

[Category by category with status, findings, and fixes]

## Summary
- Total checks: XX
- Secure: XX ✅
- Needs attention: XX ⚠️
- Vulnerable: XX 🔴

## Priority Action Items
[Ordered list of fixes, critical first]

Save this report to: memory/security-audit-YYYY-MM-DD.md
```

---

## Expected Output Example

```markdown
# 🛡️ Security Audit Report — 2026-02-15

## 1. Credential Storage ⚠️ NEEDS ATTENTION

**Checked:**
- ~/.openclaw/openclaw.json
- AGENTS.md, TOOLS.md, SOUL.md
- memory/*.md files
- Git history

**Findings:**
- 🔴 Anthropic API key in openclaw.json as plain text (line 47)
- ✅ Discord bot token using env var (DISCORD_BOT_TOKEN)
- ✅ No credentials found in memory files
- ✅ No secrets in git history

**Remediation:**
1. Move Anthropic key to environment variable:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-..."
   echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
   ```
2. Update openclaw.json:
   ```json
   "anthropicApiKey": "env:ANTHROPIC_API_KEY"
   ```
3. Restart gateway: `openclaw gateway restart`

## 2. File Permissions ✅ SECURE

**Checked:**
- Directory permissions for ~/.openclaw/
- File permissions for workspace files

**Findings:**
- ✅ ~/.openclaw/ is 0700 (drwx------)
- ✅ workspace files are 0600 (rw-------)
- ✅ Only your user can access these files

**No action needed.**

## 3. Memory Privacy ✅ SECURE

**Checked:**
- AGENTS.md session-specific rules
- Discord overlay configuration

**Findings:**
- ✅ MEMORY.md excluded from Discord sessions
- ✅ Daily memory files (YYYY-MM-DD.md) accessible to all sessions
- ✅ Session type detection implemented
- ✅ Privacy boundaries documented

**No action needed.**

[... etc for all 10 categories ...]

## Summary
- Total checks: 27
- Secure: 23 ✅
- Needs attention: 3 ⚠️
- Vulnerable: 1 🔴

## Priority Action Items

1. **CRITICAL:** Move Anthropic API key to environment variable (Category 1)
2. **IMPORTANT:** Configure .gitignore for memory files (Category 8)
3. **RECOMMENDED:** Set up encrypted backup for ~/.openclaw/ (Category 9)

Estimated time to remediate: 15 minutes
```

---

## When to Run This Audit

### Mandatory Times
- ✅ **After initial ClawStarter installation** (Day 1)
- ✅ **Before adding Discord/external integrations**
- ✅ **After any openclaw.json changes**

### Recommended Schedule
- 📅 **Monthly** — Quick check (5 min)
- 📅 **Quarterly** — Full audit (15 min)
- 📅 **After major updates** — When OpenClaw or ClawStarter releases new version

### Trigger Events
- 🚨 You notice unusual behavior
- 🚨 You're setting up on a shared computer
- 🚨 You're adding new integrations (X/Twitter, email, etc.)
- 🚨 Someone else will use this machine

---

## Common Issues and Fixes

### Issue: API keys in openclaw.json

**Fix:**
```bash
# 1. Store key in environment
echo 'export ANTHROPIC_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc

# 2. Update config to reference env var
# Edit openclaw.json: "anthropicApiKey": "env:ANTHROPIC_API_KEY"

# 3. Restart gateway
openclaw gateway restart
```

### Issue: Memory files in git repository

**Fix:**
```bash
# Add to .gitignore
echo "memory/*.md" >> ~/.openclaw/workspace/.gitignore
echo "MEMORY.md" >> ~/.openclaw/workspace/.gitignore

# Remove from git history (if already committed)
git rm --cached memory/*.md MEMORY.md
git commit -m "Remove private memory files from git"
```

### Issue: World-readable files

**Fix:**
```bash
# Lock down workspace
chmod 700 ~/.openclaw/
chmod 700 ~/.openclaw/workspace/
chmod 600 ~/.openclaw/workspace/*.md
chmod 600 ~/.openclaw/workspace/memory/*.md
```

### Issue: Cron posting to wrong channel

**Fix:**
```bash
# Export cron config
openclaw cron export morning-briefing > fix.json

# Edit "delivery.to" field with correct channel ID
nano fix.json

# Reimport
openclaw cron import fix.json
```

### Issue: MEMORY.md loading in Discord

**Fix:**
Edit `~/.openclaw/workspace/AGENTS.md` and verify this section exists:

```markdown
### [SESSION-SPECIFIC MEMORY RULES]

**Main session:**
- Read MEMORY.md ← Full long-term memory

**Discord/group sessions:**
- DO NOT read MEMORY.md (contains private data)
- Read memory/YYYY-MM-DD.md (today + yesterday only)
```

---

## Security Best Practices

### 1. Principle of Least Privilege
- Don't give your agent access to things it doesn't need
- Use read-only access where possible
- Limit cron job permissions

### 2. Defense in Depth
- Multiple layers: file permissions + env vars + ask-before-act
- Don't rely on single protection

### 3. Audit Trail
- Memory checkpoints create activity log
- Review periodically for unusual behavior
- Check cron logs for unexpected runs

### 4. Regular Updates
- Keep OpenClaw updated
- Review ClawStarter updates
- Re-run audit after updates

### 5. Backup Safely
- Encrypt backups of ~/.openclaw/
- Don't sync private data to unencrypted cloud
- Test restore procedure

---

## Emergency Response

**If you discover a security issue during audit:**

1. **STOP** — Don't panic, but don't delay
2. **Assess** — How bad is it? (exposed key, leaked data, permission issue?)
3. **Contain** — Disable affected feature immediately
4. **Fix** — Follow remediation steps
5. **Verify** — Re-run audit to confirm fix
6. **Document** — Write what happened and how you fixed it (helps future you)

**Examples:**

**Exposed API key:**
1. Revoke key immediately (Anthropic dashboard)
2. Generate new key
3. Store in environment variable
4. Update config
5. Restart gateway
6. Re-run audit

**Memory leak to Discord:**
1. Check Discord chat history — was private data posted?
2. Delete messages if needed
3. Fix AGENTS.md memory rules
4. Restart gateway
5. Test with benign message
6. Re-run audit

---

## Advanced: Automated Monthly Audit

**Want this to run automatically?**

Create cron job:

```json
{
  "name": "security-audit-monthly",
  "schedule": {
    "kind": "cron",
    "expr": "0 10 1 * *",
    "tz": "America/New_York"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "[Paste full audit prompt from above]",
    "model": "anthropic/claude-sonnet-4-5",
    "timeoutSeconds": 600
  },
  "delivery": {
    "mode": "announce",
    "channel": "discord",
    "to": "SECURITY_CHANNEL_ID"
  },
  "enabled": true
}
```

**Schedule:** 10 AM on 1st of every month  
**Model:** sonnet (security requires thoroughness)  
**Cost:** ~$0.05/month (worth it for peace of mind)

---

## Compliance Checklist

**Before declaring "setup secure":**

- [ ] All API keys in env vars or 1Password
- [ ] No credentials in git history
- [ ] File permissions locked down (700/600)
- [ ] MEMORY.md excluded from group sessions
- [ ] External actions require permission
- [ ] Cron jobs have correct targets
- [ ] Audit report saved to memory/
- [ ] Action items addressed or documented

**When all boxes checked:** Your setup meets ClawStarter security baseline.

---

**Security is not a one-time task. Run this audit regularly.**

*Last updated: 2026-02-15*
