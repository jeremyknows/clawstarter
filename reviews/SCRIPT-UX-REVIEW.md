# UX Review: openclaw-quickstart-v2.sh

**Reviewer Perspective:** Smart but non-technical user, first time using Terminal  
**Date:** 2026-02-11

---

## User Journey Issues

### 🚨 Critical Confusions

1. **Title Mismatch: "2 Questions" → Actually 3+ Questions**
   - Header says "2 Questions to Running Bot"
   - Step 2 says "Configure (2 questions)"
   - Reality: Question 1 (API Key), Question 2 (Use Case), Question 3 (Setup Type), plus optional name customization
   - **Impact:** Feels dishonest, user loses trust
   - **Fix:** Change to "3 Questions" everywhere, or make bot name part of Question 2

2. **"API Key" is Scary for Non-Technical Users**
   - Question 1 starts with "Paste API key (or Enter for guided signup)"
   - Problem: New users don't know what an API key is or why they need one
   - The guided signup helps, but only appears AFTER user hits Enter
   - **Fix:** Reframe Question 1 as: "How should your bot think?" with options:
     - Option 1: Free (no signup needed) [default]
     - Option 2: Premium AI models (60-second signup)
     - Option 3: I already have an API key

3. **"sk-or-", "sk-ant-" Format Checks are Invisible Until Wrong**
   - Script validates key formats but user doesn't know what's valid until they paste wrong thing
   - Warning appears: "That doesn't look like an OpenRouter key"
   - **Fix:** Show examples BEFORE user pastes: "Example: sk-or-v1-abc123..."

4. **Setup Type Question Lacks Context**
   - Question 3 asks "How will you run OpenClaw?"
   - Options mention "Mac User", "VM", "Dedicated Device"
   - Problem: Non-technical user doesn't understand what this affects
   - "Isolation" and "sandbox" are mentioned but not explained
   - **Fix:** Add "Why this matters:" section explaining what changes (file access, security, permissions)

### 😕 Minor Pain Points

5. **Multi-Select Format Not Obvious**
   - Question 2 says "Select all that apply — e.g., \"1,3\""
   - Many users might try spaces: "1 3" or "1, 3" (with space)
   - **Fix:** Explicitly accept multiple formats or show more examples

6. **Skill Packs Feel Like Hidden Upsells**
   - After setup "completes", suddenly "Bonus: Skill Packs" appears
   - Feels like an unexpected extra step after thinking you're done
   - **Fix:** Mention skill packs in the intro: "3 questions + optional superpowers"

7. **OpenCode vs OpenRouter Naming Confusion**
   - "OpenCode Free Tier" and "OpenRouter" sound similar
   - New user might think they're the same company
   - **Fix:** Add one-line explainers: "OpenCode (our free AI)" vs "OpenRouter (third-party, paid models)"

8. **Template Installation is Silent**
   - Script downloads templates from GitHub but doesn't explain what's happening
   - User sees: "Installing content-creator..." but doesn't know what that means
   - **Fix:** Add message: "Downloading pre-built workflows for [use case]..."

---

## Error Message Quality

### ✅ What Works
- **Visual hierarchy:** Color-coded symbols (✓, ✗, →) make success/failure clear
- **Homebrew failure:** "Homebrew installation failed" at least stops execution
- **Gateway failure:** "Gateway failed. Check: tail /tmp/openclaw/gateway.log" provides next step

### ❌ What Doesn't

| Error Scenario | Current Message | Problem | Better Alternative |
|----------------|----------------|---------|-------------------|
| Script run on Linux | "This script is for macOS only." | No guidance on what to do instead | "This script is for macOS. For other systems, see: [link to manual install]" |
| Node install fails | Generic brew error | User doesn't know if they should retry or what went wrong | "Node.js install failed. Try again? [Y/n] (Or install manually: brew install node@22)" |
| Gateway won't start | "Gateway failed. Check: tail /tmp/openclaw/gateway.log" | Non-technical user doesn't know how to run 'tail' command | "Gateway failed. View error log? [Y/n]" then show the log directly |
| Invalid API key | "Unknown key format — assuming OpenRouter" | Continues with potentially broken setup | "That key format isn't recognized. Continue anyway? [y/N]" with default to No |
| Download template fails | "Could not download X template (continuing anyway)" | Setup completes but feature is broken | "Template download failed. You can add it later with: openclaw install X. Continue? [Y/n]" |

**Rating: 6/10**  
Errors stop execution (good) but recovery guidance is minimal. Assumes user can debug via log files.

---

## Progress Communication

### ✅ Excellent
- **Step headers** with clear numbering (Step 1: Install, Step 2: Configure, Step 3: Launch)
- **Spinner** during long operations (Homebrew, Node install)
- **Check marks** (✓) create satisfying progress feeling
- **Percentage-free:** Doesn't make fake promises about "50% complete"

### ⚠️ Needs Improvement
- **Silent downloads:** When curling templates, no progress indicator
- **No time estimates:** "This takes ~5 minutes" at start, but no per-step estimates
- **Skill pack installation:** When installing ffmpeg/summarize via brew, silent for 30+ seconds
- **LaunchAgent loading:** Happens silently, user doesn't know bot is starting

**Suggested additions:**
```
Installing Node.js 22... (this takes 2-3 minutes)
[spinner]
✓ Node.js installed

Starting your bot... (first launch is slower)
[spinner]
✓ Gateway running
```

**Rating: 8/10**  
Good visual feedback, but some operations go dark for too long.

---

## Success Path

### 🎉 What Happens When Everything Works

**Final output:**
```
🎉 Done! Atlas is alive.

Dashboard: http://127.0.0.1:18789/

Try: "Hello Atlas! What can you help me with?"

Templates installed: content-creator
  → workflows/content-creator/GETTING-STARTED.md

Open dashboard now? [y/N]:
```

### ✅ Good
- Clear celebration (🎉 emoji)
- Provides next action: visit dashboard URL
- Gives example first message
- Offers to auto-open dashboard

### ❌ Missing
1. **What IS the dashboard?** User doesn't know if it's a chat interface, settings page, or what
2. **Where do I type the example message?** In Terminal? In browser? Unclear.
3. **What if dashboard doesn't load?** No troubleshooting link
4. **GETTING-STARTED.md path** shown but user doesn't know how to open it
5. **No "bookmark this" guidance** for the dashboard URL

**Better ending:**
```
🎉 Success! Atlas is running.

NEXT STEPS:
1. Open the dashboard (web interface): http://127.0.0.1:18789/
2. Click "New Chat" and say: "Hello Atlas!"
3. Your bot runs 24/7 in the background

📚 Learn more: Open ~/.openclaw/workspace/workflows/content-creator/GETTING-STARTED.md
🛑 Stop bot: openclaw gateway stop
🔧 Settings: openclaw config edit

[Opening dashboard...]
```

**Rating: 7/10**  
Clear success state, but lacks "what now?" detail for true beginners.

---

## Failure Recovery

### Scenario Testing

| What Goes Wrong | Can User Recover? | How Easy? |
|-----------------|-------------------|-----------|
| Accidentally paste wrong API key | ❌ No undo | Must re-run entire script |
| Choose wrong use case | ❌ No back button | Must Ctrl+C and restart |
| Typo in bot name | ❌ No edit | Stuck with typo or restart |
| Skill pack install fails | ⚠️ Partial | Script continues, but skill is broken silently |
| Gateway fails to start | ❌ Check logs manually | No automated retry or diagnostics |
| Dashboard won't open | ❌ No help | User left staring at error |

### Critical Issues

1. **No "Back" or "Edit" Options**
   - Once you answer a question, you're committed
   - Typo in bot name? Start over.
   - **Fix:** Add confirmation screen before Step 3:
     ```
     Review your setup:
       API: OpenCode Free Tier
       Use case: Content creation
       Bot name: Muse
       Setup: Your Mac User
     
     Looks good? [Y/n/e to edit]:
     ```

2. **No Retry Logic**
   - If Node.js install fails, script dies
   - No "Try again? [Y/n]" option
   - **Fix:** Wrap critical installs in retry loops (max 3 attempts)

3. **Config Backup But No Restore**
   - Script backs up existing `openclaw.json`
   - But if new config breaks, user doesn't know how to restore
   - **Fix:** On failure, offer: "Restore previous config? [Y/n]"

4. **Skill Pack Failures Don't Block Success**
   - If ffmpeg fails to install, script says "✓ Done!"
   - User thinks video skills work, but they don't
   - **Fix:** Track failures, show summary:
     ```
     ⚠️ Some skill packs couldn't install:
       - Media Pack (ffmpeg failed)
     
     Try manual install: brew install ffmpeg
     ```

**Rating: 3/10**  
Almost no recovery options. Users must restart from scratch for any mistake.

---

## Quick Wins

### 🚀 High Impact, Easy Fixes

1. **Fix the "2 Questions" lie** → Change to "3 Questions" (2 min fix)

2. **Add confirmation before launch** (10 min):
   ```bash
   echo "Review your choices:"
   echo "  Bot name: $bot_name"
   echo "  AI model: $default_model"
   echo "  Use case: $templates"
   if ! confirm "Start installation?"; then
     echo "Run again when ready: bash openclaw-quickstart-v2.sh"
     exit 0
   fi
   ```

3. **Simplify Question 1** (5 min):
   ```
   Question 1: Which AI should power your bot?
   
   1. Free tier (no signup) — Kimi K2.5 [RECOMMENDED]
   2. Premium models (60-sec signup) — Claude, GPT, etc.
   3. I have an API key already
   
   Choose [1-3]: 
   ```

4. **Add time estimates** (5 min):
   ```bash
   info "Installing Node.js 22... (2-3 minutes)"
   info "Installing OpenClaw... (30 seconds)"
   ```

5. **Better final message** (10 min):
   ```
   🎉 Success! $bot_name is live.
   
   WHAT TO DO NOW:
   1. I'm opening the dashboard (chat interface)
   2. Click "New Chat" in the sidebar
   3. Type: "Hello $bot_name, what can you do?"
   
   Dashboard URL (bookmark this): http://127.0.0.1:18789/
   
   Commands you'll need:
     Stop bot:    openclaw gateway stop
     Restart bot: openclaw gateway restart
     View logs:   openclaw gateway logs
   
   [Opening browser in 3 seconds... Press Ctrl+C to skip]
   ```

6. **Validate multi-select input** (10 min):
   ```bash
   # Accept: "1,2", "1, 2", "1 2", "1 3"
   use_case_input=$(echo "$use_case_input" | tr -d ' ' | tr ',' ' ')
   ```

7. **Show examples for API keys** (2 min):
   ```
   Paste your OpenRouter key (starts with sk-or-v1-...):
   ```

---

## Terminology Audit

### Jargon that Confuses Non-Technical Users

| Term Used | User Thinks | Better Alternative |
|-----------|-------------|-------------------|
| "API key" | ??? | "AI access code" or "AI provider key" |
| "LaunchAgent" | A rocket? | "Background service" |
| "Gateway" | A bridge? | "Bot engine" or just "OpenClaw" |
| "Sandbox mode" | Playing in dirt? | "File access level: Limited / Full" |
| "Templates" | Word doc? | "Pre-built workflows" or "Starter kits" |
| "Skill packs" | Video game DLC? | Actually good! Keep this. |
| "Provider" (AI context) | Internet company? | "AI service" or "AI model source" |
| "Spinning up" | ??? | "Starting" |
| "Node.js" | What's a node? | "Required software (Node.js)" |

### Acronyms Never Explained
- **VM** (Virtual Machine) — mentioned in Question 3 with no context
- **TTS** (Text-to-Speech) — in skill packs
- **TDD** (Test-Driven Development) — in Quality Pack

**Fix:** Either avoid or define on first use:
```
3. 🛠️ Build apps (coding, GitHub, APIs)
                              ↓
3. 🛠️ Build apps (coding, GitHub, web services)
```

---

## Accessibility Issues

1. **Color-only Indicators**
   - Green ✓, Red ✗, Yellow !, Cyan →
   - Symbols help, but color-blind users might struggle with red/green errors
   - **Fix:** Already uses symbols — good! Just ensure color isn't the ONLY signal.

2. **No Keyboard Shortcuts**
   - Can't press Ctrl+C to "go back" gracefully
   - **Fix:** Detect Ctrl+C and show: "Setup cancelled. Progress saved. Resume with: openclaw resume-setup"

3. **Paste Detection**
   - No indication that Terminal is waiting for paste
   - Cursor just blinks
   - **Fix:** Already shows prompt, but could add: "(Press Cmd+V to paste)"

---

## Missing Features

### Things Users Will Expect But Aren't There

1. **Preview Mode**
   - No way to see what will happen without doing it
   - **Add:** `--dry-run` flag that shows all decisions without executing

2. **Edit Existing Setup**
   - If bot is already installed, running script again overwrites everything
   - **Add:** Detect existing install, offer "Reconfigure" vs "Fresh Install"

3. **Uninstall Instructions**
   - Script installs a lot but no guidance on removal
   - **Add:** At end, show: "To uninstall later: openclaw uninstall"

4. **Logs Location**
   - Mentions `/tmp/openclaw/gateway.log` in errors but doesn't show how to view
   - **Add:** Helper: "View logs: openclaw gateway logs (or cat /tmp/openclaw/gateway.log)"

5. **Firewall Warning**
   - Script opens port 18789 but never warns about macOS firewall prompt
   - **Add:** "You may see a firewall popup — click Allow to enable dashboard access"

6. **What Happens on Reboot?**
   - LaunchAgent makes bot run at startup, but script doesn't mention this
   - **Add:** "Your bot will auto-start on reboot. To disable: openclaw autostart off"

---

## Platform-Specific Gaps

### macOS Permissions (Unaddressed)

The script installs a LaunchAgent but doesn't prepare user for:
- **Terminal permission requests:** "Terminal wants to control System Events"
- **Full Disk Access:** Might be needed depending on use case
- **Microphone access:** If using voice features
- **Accessibility access:** For iMessage automation

**Fix:** Add a "Permissions" step:
```
Step 3: Grant Permissions

Your bot may request access to:
  □ Files and Folders (for reading documents)
  □ Calendar (if you chose workflow optimization)
  □ Microphone (for voice transcription)

Click "OK" when prompted. You can change these later in:
System Settings > Privacy & Security

[Press Enter when ready]
```

---

## Verdict

**Status: Minor improvements needed — 75% ready for non-technical users**

### What's Great
- ✅ Beautiful visual design (colors, emoji, clear steps)
- ✅ Guided API signup is excellent UX innovation
- ✅ Smart defaults (just hit Enter for free tier)
- ✅ Progressive disclosure (basics first, skill packs later)
- ✅ Auto-installs dependencies (huge win vs manual setup)

### What's Blocking "Ready for Non-Technical"
- ❌ **No error recovery** — one mistake = start over
- ❌ **Title mismatch** — says 2 questions, actually 3+
- ❌ **Terminology** — assumes knowledge of APIs, VMs, sandboxing
- ❌ **Success path ambiguity** — "Dashboard URL" shown but not explained
- ⚠️ **Silent failures** — skill packs can fail without blocking success message

### Recommended Next Steps

**Priority 1 (Must Fix):**
1. Change "2 Questions" → "3 Questions" everywhere
2. Add confirmation screen before Step 3 (review all choices)
3. Rewrite final success message with explicit next steps
4. Add retry logic for critical installs (Node, OpenClaw)

**Priority 2 (Should Fix):**
5. Simplify Question 1 to avoid "API key" jargon
6. Add progress time estimates
7. Detect skill pack failures, show summary at end
8. Add "What to do if dashboard won't load" fallback

**Priority 3 (Nice to Have):**
9. Add `--dry-run` mode
10. Detect existing install, offer reconfigure option
11. Add permissions prep screen for macOS
12. Validate multi-select formats (spaces, commas)

### Estimated Work
- **Priority 1 fixes:** 2-3 hours
- **Priority 2 fixes:** 3-4 hours  
- **Priority 3 features:** 4-6 hours

**Total to "ready for non-technical":** ~10 hours of polish

---

## Final Note

This script is **impressively close** to beginner-friendly. The guided API signup is genuinely innovative. The main gap is **error recovery** — once you answer a question, you're locked in. Add a confirmation screen and some retry logic, and this becomes one of the best onboarding scripts I've seen for a technical tool.

The user journey is 80% delightful, 20% confusing. Fix the confusing 20% and you have something truly special.
