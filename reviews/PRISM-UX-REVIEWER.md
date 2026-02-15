# Prism Review: UX Reviewer

**Script:** openclaw-quickstart-v2.4-SECURE.sh  
**Reviewed:** 2026-02-11  
**Reviewer:** UX Subagent

## Verdict: UX MAINTAINED (with minor degradation risks)

The security hardening maintains the core user experience while adding protective guardrails. However, several error paths now expose technical details that could confuse non-technical users.

---

## Security vs UX Tradeoffs

### ✅ Good Tradeoffs (Security without UX cost)
- **Keychain storage**: Invisible to happy path users — keys stored securely without extra steps
- **Input validation**: Prevents edge-case failures by catching bad inputs early
- **Template checksums**: Happens silently in background, no user impact when working
- **Secure file permissions**: Completely transparent to users

### ⚠️ Problematic Tradeoffs (Security impacts UX)

1. **Keychain prompts** (HIGH RISK)
   - First-time keychain access may trigger macOS password prompts
   - Script doesn't warn users this might happen
   - No guidance if keychain access is denied

2. **Verbose security messaging** (MEDIUM)
   - Success screen now lists 5 technical security features:
     ```
     Security enhancements active:
     → API keys stored in macOS Keychain (not environment)
     → All inputs validated against strict allowlists
     → Files created with secure permissions (600)
     → Template downloads verified via SHA256
     → LaunchAgent plist validated by plutil
     ```
   - **Issue:** Terms like "allowlists," "SHA256," "plutil," "600" are jargon bombs
   - **User reaction:** "Wait, should I know what these mean? Did I do something wrong?"

3. **Checksum verification messages**
   - Download phase shows: `⚠️ No checksum defined for: X` (when checksums missing)
   - `CHECKSUM MISMATCH!` with hex strings
   - **Issue:** Scary technical error for what might be a network hiccup

---

## Error Message Quality

### 🟢 Good Error Messages

| Error | Message | Why It's Good |
|-------|---------|---------------|
| Bot name too short | "Bot name must be 2-32 characters" | Clear constraint, actionable |
| Invalid bot name format | "Bot name must start with a letter and contain only letters, numbers, hyphens, and underscores" | Explains the rules |
| Menu selection | "Selection '99' is out of range (1-3)" | Shows what's allowed |

### 🔴 Poor Error Messages

| Error | Message | Problem |
|-------|---------|---------|
| API key invalid | "API key contains invalid characters" | **Doesn't say which characters or why** |
| Keychain failure | `die "Config generation failed security validation"` | **No recovery guidance, no explanation** |
| Download fails | `fail "❌ Download failed: $url"` | **Doesn't suggest retry, check network, or contact support** |
| Template corrupted | `warn "⚠️ Cached template corrupted, re-downloading..."` | Good it auto-recovers, but **users wonder why it was corrupted** |
| Checksum mismatch | Shows hex strings in terminal | **Meaningless to non-technical users** |

### 🟡 Missing Error Guidance

**Keychain errors** have NO user-facing help:
- What if keychain access is denied?
- What if `security` command fails?
- Script just dies with generic message

**Example bad flow:**
```
User denies keychain access
→ Script fails with "Config generation failed security validation"
→ User has no idea what went wrong or how to fix it
```

**Should be:**
```
❌ Could not store API key in Keychain
   This might happen if you denied system access.
   
   To fix:
   1. Run the script again
   2. When macOS asks for keychain access, click "Allow"
   3. You may need to enter your Mac password
   
   Still stuck? Email setup@openclaw.ai
```

---

## Success Path Clarity

### ✅ What's Still Good
- "🎉 Done! {Name} is alive." — clear win state
- Dashboard URL shown prominently: `http://127.0.0.1:18789/`
- Helpful first command: `"Hello {Name}! What can you help me with?"`
- Gateway status confirmed: "Gateway running ✓"

### ⚠️ What's Degraded
- **Security details clutter the success message**
  - 5 technical bullet points about security features
  - Users scan for "what do I do next?" — these bullets distract from that
  - **Fix:** Move security details to a `--verbose` flag or docs link

- **Gateway token warning** (NEW)
  - Script prints: `"Gateway Token: {long-hex-string}"`
  - Says: `"Save this — you need it for the dashboard"`
  - **Problem:** Comes mid-flow, interrupts momentum
  - **UX issue:** Users don't know WHEN they'll need it or WHERE to save it
  - **Suggestion:** Generate token silently, show it in dashboard UI on first visit

---

## Free Tier Experience

### ✅ Zero-Friction Onboarding Preserved

**The good:**
- OpenCode free tier is still the **default path** (press Enter to skip API key)
- "no signup needed" messaging intact
- Flow: Enter → Enter → Enter → Running bot (3 touches for free tier)

**Question count:**
- ✅ Script says "3 Questions" consistently (Step 2 header + welcome screen)
- This matches updated behavior (was "2 Questions" in original review)

**Jargon check:**
- "API key" — necessary, but explained ("need one? I'll help you get one")
- "OpenCode free tier" — clear, contrasts with paid options
- **NEW:** "OpenRouter," "Anthropic" — brand names, acceptable
- **NEW:** "Keychain" — appears in error paths only, could confuse

### ⚠️ Slight Friction Added
- **Validation strictness** might reject valid-seeming names
  - User types `"My Bot"` → rejected (space not allowed)
  - User types `"bot-2024"` → rejected (must start with letter)
  - **Impact:** Extra retries = frustration

---

## New Jargon Introduced

### 🔴 High-Jargon Terms (Users Won't Know)

| Term | Where It Appears | User Knows? | Fix |
|------|------------------|-------------|-----|
| **Keychain** | Error messages, success screen | ❌ Some Mac users don't know Keychain | "Secure storage (macOS Keychain)" |
| **allowlists** | Success screen | ❌ Technical term | Remove from user-facing text |
| **SHA256** | Success screen, errors | ❌ Cryptography term | "Security check" or hide entirely |
| **plutil** | Success screen | ❌ Mac developer tool | Remove from user-facing text |
| **permissions (600)** | Success screen | ❌ Unix file mode | Remove or say "secure file permissions" |
| **LaunchAgent** | Success screen, errors | 🟡 Some Mac users know | Keep (Mac-specific term) |
| **plist** | Errors | 🟡 Mac term | Keep with context |

### 🟢 Acceptable Terms (Contextual or Necessary)
- **API key** — explained in flow
- **Dashboard** — web UI, obvious
- **OpenRouter, Anthropic** — brand names, clear from context
- **Gateway** — explained ("Gateway running")

### 🟡 Borderline Terms
- **Template checksum** — appears in verbose output, could confuse
- **Sandbox mode** — internal, not surfaced to users (good!)
- **Security level** — internal, mapped to user-friendly questions (good!)

---

## Quick Wins (Easy UX Improvements)

### 1. Simplify Success Message (5 min)
**Remove technical security bullets from success screen:**

**Current:**
```
🎉 Done! Atlas is alive.

Dashboard: http://127.0.0.1:18789/

Security enhancements active:
→ API keys stored in macOS Keychain (not environment)
→ All inputs validated against strict allowlists
→ Files created with secure permissions (600)
→ Template downloads verified via SHA256
→ LaunchAgent plist validated by plutil
```

**Better:**
```
🎉 Done! Atlas is alive.

Dashboard: http://127.0.0.1:18789/

Try: "Hello Atlas! What can you help me with?"

🔒 This installation uses enhanced security.
   Details: https://openclaw.ai/docs/security
```

### 2. Add Keychain Guidance (10 min)
**Before first keychain write, print:**
```
→ Storing API key securely...
  (macOS may ask for your password — this is normal)
```

**On keychain failure:**
```
❌ Could not access secure storage (Keychain)

This usually means:
• You clicked "Deny" when macOS asked for access
• Your Keychain is locked

To fix: Run this script again and click "Allow" when prompted.
Still stuck? Visit https://openclaw.ai/setup-help
```

### 3. Improve API Key Validation Error (2 min)
**Current:** `"API key contains invalid characters"`

**Better:** `"API key contains special characters that aren't allowed. It should be letters, numbers, and dashes only (like sk-or-abc123)."`

### 4. Hide Security Details by Default (5 min)
**Only show SHA256/checksum details when downloads fail.**
- Happy path: Silent verification
- Failure path: `"Download verification failed. This might be a network issue. Retrying... (1/3)"`

### 5. Gateway Token Flow (15 min)
**Don't print token mid-setup.**
- Generate silently
- Store in Keychain
- Dashboard shows token on first visit with "Save this" tooltip
- **Benefit:** No mid-flow distraction

---

## Stress Test Scenarios

### Scenario 1: User Denies Keychain Access
**Current behavior:** Script crashes with `"Config generation failed security validation"`

**User sees:** Nothing helpful

**Should show:**
```
❌ Setup failed: Could not store API key securely

OpenClaw needs permission to use macOS Keychain (secure storage).

To fix:
1. Run the script again
2. When macOS prompts for keychain access, click "Allow"
3. Enter your Mac password if asked

This is a one-time setup step.
```

### Scenario 2: User Enters Invalid Bot Name
**Current behavior:** Works well! Shows clear error and loops for retry.

**User experience:** ✅ Good

### Scenario 3: Template Download Fails
**Current behavior:** Shows checksum error with hex strings

**User sees:** Technical error, unclear what to do

**Should show:**
```
❌ Could not download template files

This might be:
• Network connectivity issue
• GitHub is temporarily down

Retrying in 3 seconds... (1/3)

[If all retries fail]
Setup can continue without templates.
You can add them later with: openclaw templates install
```

### Scenario 4: User Has Unusual Home Path
**Current behavior:** Validation rejects paths with spaces or special chars

**User sees:** `"HOME contains forbidden characters"` 

**Problem:** Their username might have a space (legit on macOS)

**Should:** Either support it or show helpful error:
```
❌ Your Mac username contains special characters

OpenClaw needs a standard path like /Users/john
Your path: /Users/john smith

To fix: Create a new Mac user with a simple name (letters only)
or install in a VM.

Need help? https://openclaw.ai/setup-help
```

---

## Recommendation

### 🟢 SHIP with Quick Wins 1-3 applied

**Rationale:**
- Core UX is intact: free tier path, clear questions, working defaults
- Security benefits outweigh minor UX friction
- Most issues are edge-case error paths, not happy path

**Critical fixes before ship:**
1. **Add keychain guidance** (Quick Win #2) — prevents silent failures
2. **Simplify success message** (Quick Win #1) — reduces jargon overload
3. **Improve API key error** (Quick Win #3) — helps when validation fails

**Can ship without (but should fix soon):**
- Gateway token flow improvement (Quick Win #5)
- Advanced error recovery for download failures
- Support for usernames with spaces

---

## Overall Assessment

**UX Grade:** B+ (was A- before security hardening)

**What works:**
- Free tier path preserved (no API key required)
- Question count accurate ("3 Questions")
- Success state clear (dashboard URL, next steps)
- Validation prevents edge-case bugs

**What hurts:**
- Technical jargon in success screen (SHA256, allowlists, plutil, 600)
- Keychain errors lack recovery guidance
- Some validation errors are vague ("invalid characters" — which ones?)

**User perspective:**
> "Setup worked great! Saw some technical stuff at the end that I didn't understand, but my bot is running. If I had gotten an error about 'Keychain' I'd be lost."

**Security team perspective:**
> "We hardened everything but forgot users aren't security engineers. Error messages assume technical literacy."

---

## Action Items

**Before Merge:**
- [ ] Quick Win #1: Simplify success message (remove jargon)
- [ ] Quick Win #2: Add keychain guidance (proactive + error)
- [ ] Quick Win #3: Improve API key validation error

**Post-Merge (v2.4.1):**
- [ ] Quick Win #4: Hide SHA256 details unless errors occur
- [ ] Quick Win #5: Move gateway token to dashboard UI
- [ ] Add error recovery for download failures (retry loop)
- [ ] Test with non-technical users (3-5 people)

**Documentation:**
- [ ] Create https://openclaw.ai/setup-help with common errors
- [ ] Add Keychain troubleshooting page
- [ ] Document what "security enhancements" actually mean (for curious users)

---

**Final Verdict:** Security is solid, UX is mostly preserved. Apply Quick Wins 1-3 and ship. Monitor support requests for keychain issues.
