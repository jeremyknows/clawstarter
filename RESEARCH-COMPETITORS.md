# Competitor Analysis: AI Agent Onboarding & Templates

**Research Date:** 2026-02-11  
**Focus:** How leading AI agent platforms handle onboarding, templates, and initial setup

---

## 1. Claude Code (Anthropic)

### Onboarding Approach
**Philosophy:** Minimal friction, natural language-first, conversational setup

#### Installation
- **One-liner install:** `curl -fsSL https://claude.ai/install.sh | bash`
- Alternative methods: Homebrew, WinGet (Windows)
- Works on macOS, Linux, WSL, Windows

#### First-Run Experience
1. **Initial launch:** `claude` command opens interactive session
2. **Authentication prompt:** Appears automatically on first use
   - Supports Claude Pro/Max/Teams/Enterprise subscriptions
   - Claude Console (API credits)
   - Third-party cloud providers (AWS Bedrock, GCP Vertex, Azure)
3. **Credentials persisted:** No re-login needed
4. **Welcome screen:** Shows session info, recent conversations, updates
5. **Discovery-oriented:** Suggests `/help` or natural questions like "what can Claude Code do?"

#### Key Design Patterns
- **Zero configuration required** - works immediately after auth
- **Natural language setup** - no config files to edit
- **Contextual discovery** - encourages exploration through conversation
- **"Just works" philosophy** - intelligent defaults, no decisions required upfront

### Template System: Setup Hooks (Advanced)

#### Concept: Hybrid Deterministic + Agentic Setup
Introduced January 25, 2026 - represents cutting-edge approach to project onboarding.

**Three Execution Modes:**

1. **Deterministic Mode** (CI/CD-friendly)
   ```bash
   claude --init-only
   ```
   - Runs setup script, exits with return code
   - Predictable, no LLM variance
   - Perfect for pipelines

2. **Agentic Mode** (Smart oversight)
   ```bash
   claude --init "/install"
   ```
   - Script runs deterministically
   - Agent analyzes logs and reports results in natural language
   - Diagnoses failures, explains what happened

3. **Interactive Mode** (New team member friendly)
   ```bash
   claude --init "/install true"
   ```
   - Agent asks clarifying questions first
   - Adapts based on answers
   - Walks through each step with explanations

#### Configuration
Hooks defined in `.claude/settings.json`:
```json
{
  "hooks": {
    "setup_init": {
      "script": ".claude/hooks/setup_init.py",
      "enabled": true
    }
  }
}
```

#### Onboarding Prompt Pattern
From real-world usage (Edgedive blog):

**3-Stage Onboarding:**
1. **Explore** - Agent reads codebase, finds relevant files
2. **Clarify** - Drafts implementation plan, asks questions
3. **Plan** - Finalizes detailed plan with tests, acceptance criteria

Saved to `.claude/tasks/[TASK_ID]` for persistence.

**Key Insight:** Uses "ultrathink" mode - agent takes time to deeply understand before acting.

### Actionable Takeaways
✅ **One-command installation** - no manual setup steps  
✅ **Auth-first, config-optional** - get user logged in, everything else can wait  
✅ **Conversational discovery** - don't make users read docs, let them ask  
✅ **Hybrid determinism** - scripts for reliability, agents for intelligence  
✅ **Onboarding prompts as code** - store setup instructions in version control  
✅ **Three-tier approach:** Fast (deterministic) → Smart (agentic) → Guided (interactive)

---

## 2. OpenAI Assistants API → Responses API

### Onboarding Approach
**Philosophy:** API-first, dashboard-configured, programmatic control

⚠️ **Major shift in progress:** Assistants API being deprecated (Aug 2026), migrating to Responses API.

#### Old Model (Assistants API)
**Configuration via API:**
```python
assistant = openai.beta.assistants.create(
    name="My Assistant",
    instructions="You are a helpful assistant...",
    model="gpt-4",
    tools=[{"type": "code_interpreter"}]
)
```

- Assistants were **API objects** - created/managed programmatically
- Instructions, tools, model bundled together
- Threads stored conversation server-side
- Runs executed asynchronously (polling required)

#### New Model (Responses API)
**Configuration via Dashboard:**
- **Prompts** replace Assistants
- Created in dashboard, not via API
- Versioned, diffable, rollback-able
- Stored in source control as IDs or exported specs

**Key Architecture Changes:**
- `Assistants` → `Prompts` (dashboard-configured)
- `Threads` → `Conversations` (more flexible item storage)
- `Runs` → `Responses` (synchronous, simpler)
- `Run Steps` → `Items` (generalized: messages, tool calls, outputs)

#### Migration Pattern
```python
# Old: Create assistant programmatically
assistant = openai.beta.assistants.create(...)

# New: Reference dashboard-created prompt
response = openai.responses.create(
    prompt_id="prompt_abc123",
    input=[{"role": "user", "content": "Hello"}]
)
```

### Template System
**No explicit templates** - Prompts serve as "behavioral profiles"

#### Prompt as Template
- Define instructions, tools, model in dashboard
- Version control via prompt IDs
- Reuse across Responses API and Realtime API
- A/B testing by swapping prompt IDs

### Actionable Takeaways
✅ **Dashboard-first config** - GUI for complex setup, API for execution  
✅ **Versioned prompts** - treat configurations as versioned artifacts  
✅ **Separation of concerns** - app handles orchestration, prompt defines behavior  
✅ **Portability** - same prompt works across APIs (Responses, Realtime)  
⚠️ **No onboarding UX** - assumes developers already know what they're building  
⚠️ **Migration complexity** - moving between API versions requires manual work

---

## 3. LangChain / LangSmith Agent Builder

### Onboarding Approach
**Philosophy:** Template gallery + natural language agent creation

#### Entry Points

**1. Prompt-Based Creation**
- Describe what you want: "Build me a market research agent"
- Agent Builder asks follow-up questions
- Generates agent with relevant tools

**2. Template Library**
- Curated collection of ready-to-deploy agents
- Built by domain experts (Tavily, PagerDuty, Exa, Box, Arcade)
- Categories: calendar, email, incident response, recruiting, research

### Template System

#### Pre-built Templates Include:
- **Calendar Brief** (Google Calendar) - Morning summaries with participant research
- **Email Assistant** (Gmail) - Categorize emails, draft replies
- **Incident Responder** (PagerDuty) - Alert analysis, runbook cross-reference
- **Document Review** (Box) - File submission review, summary prep
- **Talent Sourcing** (Exa) - LinkedIn candidate search
- **Competitor Research** (Tavily) - Deep competitive analysis
- **Social Media Monitor** (X + Slack) - Daily digest to Slack

#### Template Components
Each template includes:
1. **Pre-configured tools** - OAuth-connected integrations
2. **System instructions** - Defines behavior, personality, capabilities
3. **Triggers** (optional) - Respond to external events (e.g., Slack mentions)
4. **Model selection** - Choose OpenAI, Anthropic, Gemini, or custom

#### Customization Flow
1. **Clone template** - Creates independent copy
2. **Modify prompts** - Adjust instructions
3. **Add/remove tools** - Change integrations
4. **Set approval requirements** - Control autonomy
5. **Give feedback** - Agent learns like a teammate (no mapping workflows)

### Extended Templates via Arcade
- **8,000+ tools** available via MCP Gateway
- **60+ ready-to-deploy templates** with step-by-step guides
- Covers marketing, sales, recruiting, customer success, product, engineering

### Actionable Takeaways
✅ **Template-first onboarding** - start with working examples, not blank canvas  
✅ **Domain expert templates** - built by companies who know their tools  
✅ **Natural language customization** - give feedback instead of writing code  
✅ **Cloneable starting points** - safe experimentation without breaking originals  
✅ **Multi-provider support** - not locked into one model  
✅ **Trigger system** - proactive agents, not just reactive chat  
✅ **Tool marketplace** - massive ecosystem (8,000+ via MCP)  

**Differentiation:** Only platform with both conversational creation AND curated templates.

---

## 4. AutoGPT

### Onboarding Approach
**Philosophy:** User-centric web interface with guided setup flow

⚠️ **Context:** AutoGPT platform (not the original CLI) added formal onboarding in 2025.

#### Onboarding Flow Architecture

**4-Screen Journey:**

1. **Setup Flow Selection**
   - Import from existing setup (if applicable)
   - Start fresh

2. **User Preferences**
   - Collect initial configuration
   - Ask about use cases
   - Determine starting point

3. **Agent Selection** (Marketplace-driven)
   - Algorithm recommends agents based on user answers
   - Show relevant marketplace agents
   - Display agent input schemas
   - User can add agents to library

4. **First Run + Celebration**
   - User runs their first agent
   - Canvas confetti animation 🎉
   - Redirect to library

#### Technical Implementation (from PR #9485, #9491)

**Backend:**
- `UserOnboarding` database schema
- `GET /onboarding` - Retrieve onboarding state
- `PATCH /onboarding` - Update progress
- `GET /onboarding/agents` - Get recommended agents (algorithm-based)
- `POST /library/agents` - Add marketplace agent with input/output nodes

**Frontend:**
- Onboarding state persisted (survives logout/refresh)
- Redirect logic: If onboarding incomplete → `/onboarding/*`
- If complete → `/library`
- Reset option: `/onboarding/reset`

**Key Features:**
- Automatic onboarding trigger on signup/login
- Personalized agent recommendations
- Marketplace integration
- State persistence across sessions
- Confetti celebration on completion

### Template System
**Marketplace Agents** - community and official templates

- Agent templates stored in marketplace
- Include input/output schemas
- Can be added to user library during onboarding
- Algorithm selects relevant templates based on user answers

### Actionable Takeaways
✅ **Guided multi-step flow** - progressively builds user profile  
✅ **Intelligent recommendations** - algorithm matches agents to needs  
✅ **Celebration moments** - gamification (confetti) reinforces success  
✅ **State persistence** - can pause and resume onboarding  
✅ **Marketplace integration** - onboarding IS template discovery  
✅ **Automatic triggering** - onboarding blocks access until complete  
✅ **Reset capability** - users can restart if they make mistakes  

**Differentiation:** Most consumer-friendly onboarding, treats setup as a guided journey.

---

## 5. Cursor IDE

### Onboarding Approach
**Philosophy:** VSCode-compatible, import-first, minimal new learning curve

⚠️ **Limited documentation available** - Cursor focuses on "just works" approach.

#### Installation
- Download installer for macOS/Windows/Linux
- Standard IDE installation flow

#### Key Design: Migration-Focused
**Target Audience:** Developers already using VSCode or other editors

**Expected Onboarding:**
- Import existing settings
- Import extensions
- Start coding immediately with AI features

**AI Feature Discovery:**
- Cmd+K for inline AI editing
- Chat panel for AI conversations
- Code completions work automatically

### Template System
**No formal template system** - Cursor is a code editor, not an agent platform.

**Instead:**
- Works with any codebase
- AI adapts to project context
- Focus on augmenting existing workflows, not replacing them

### Actionable Takeaways
✅ **Import-first mindset** - assume users are migrating, not starting fresh  
✅ **Zero-config AI** - features work immediately without setup  
✅ **Keyboard-driven discovery** - power users learn shortcuts organically  
⚠️ **No explicit onboarding** - relies on IDE familiarity  
⚠️ **No templates** - not applicable to code editors  

**Differentiation:** Not a platform, but a tool that disappears into existing workflow.

---

## 6. Windsurf IDE (Codeium)

### Onboarding Approach
**Philosophy:** Comprehensive guided setup with competitive migration support

#### Installation
- Download for macOS (Yosemite+), Windows (10+), Linux (Ubuntu 20.04+)
- Standard installer

#### Onboarding Flow (4 Steps)

**Step 1: Setup Flow Selection**
Three paths:
- **Start fresh** - Default keybindings, clean slate
- **Import from VS Code** - Settings, extensions, or both
- **Import from Cursor** - Settings, extensions, or both

**Additional:** Install windsurf in PATH for CLI access

**Step 2: Editor Theme**
- Choose from default color themes
- Override if imported theme exists

**Step 3: Sign Up / Log In**
- Free account required
- Authentication flow with fallback:
  - Standard OAuth flow
  - "Having Trouble?" option → Manual auth code entry
  - Copy link → Enter code from browser

**Step 4: Let's Surf!**
- Starting page with "Things to Try"
- Recommended plugins highlighted
- Ready to use

#### Post-Onboarding Features
- **Update mechanism** - "Restart to Update" button in menu bar
- **Command palette integration** - Check for Updates via Cmd/Ctrl+Shift+P
- **Import recovery** - Can import VSCode/Cursor config after onboarding via command palette
- **Custom app icons** (beta) - Paying users can customize dock icon (macOS)
- **Windsurf Next** - Opt-in prerelease channel for early features

#### Key UX Patterns
- **Restart onboarding** - "Reset Onboarding" command available anytime
- **Graceful auth fallback** - If OAuth fails, manual code entry works
- **Extension compatibility warnings** - Explicitly calls out incompatible extensions (AI code complete, proprietary)

### Template System
**No template system** - Focus on recommended plugins instead

**Cascade:** AI chatbot for collaboration (not a template, but a feature)

### Actionable Takeaways
✅ **Multi-path onboarding** - Fresh vs. Migration (2 sources)  
✅ **Explicit migration targets** - Competes directly with VSCode and Cursor  
✅ **Auth fallback strategy** - Anticipates authentication problems  
✅ **Restartable onboarding** - Users can reset and try again  
✅ **Progressive disclosure** - Plugins recommended AFTER basic setup  
✅ **Update UX** - Persistent update notifications in UI  
✅ **Customization for paying users** - Visual personalization as upgrade incentive  

**Differentiation:** Most polished IDE onboarding, explicitly targets competitor users.

---

## Cross-Platform Comparison Matrix

| Platform | Onboarding Style | Time to First Value | Config Approach | Templates | Strength |
|----------|------------------|---------------------|-----------------|-----------|----------|
| **Claude Code** | Conversational | <1 min | Natural language | Setup hooks (advanced) | Zero friction, just works |
| **OpenAI** | API-first | N/A (dev tool) | Dashboard prompts | No (prompts as profiles) | Versioned configs, portability |
| **LangChain** | Template gallery | ~2 min | Clone & customize | 60+ curated | Largest template ecosystem |
| **AutoGPT** | Guided multi-step | ~5 min | Web wizard | Marketplace agents | Most user-friendly, gamified |
| **Cursor** | Import-first | <30 sec | IDE settings | N/A (editor) | Zero learning curve for VSCode users |
| **Windsurf** | Comprehensive wizard | ~3 min | IDE settings | Plugins | Most polished IDE onboarding |

---

## Key Insights & Recommendations

### 1. Onboarding Patterns by User Type

**For Developers (Technical Users):**
- **Pattern:** Minimal friction, CLI-first, one-liner install
- **Example:** Claude Code - `curl | bash` → `claude` → natural language
- **Why it works:** Developers want to start coding, not configure

**For Non-Technical Users (Business Users):**
- **Pattern:** Guided wizard, progressive questions, visual feedback
- **Example:** AutoGPT - 4 screens, algorithm recommendations, confetti
- **Why it works:** Reduces overwhelm, provides structure, celebrates success

**For Migrators (Switching Platforms):**
- **Pattern:** Import-first, compatibility promises, familiar UX
- **Example:** Windsurf - "Import from VSCode/Cursor" as primary path
- **Why it works:** Reduces switching cost, preserves investment

### 2. Template Strategy Trade-offs

**Curated Gallery (LangChain/AutoGPT):**
- ✅ Low cognitive load - "pick one that fits"
- ✅ High quality - expert-built
- ⚠️ Limited scope - only covers common cases
- ⚠️ Requires maintenance - templates can become outdated

**Conversational Creation (LangChain):**
- ✅ Handles edge cases - generates custom agents
- ✅ Natural interface - describe in plain English
- ⚠️ Quality variance - output depends on prompt quality
- ⚠️ Requires validation - user must verify result

**Prompts as Profiles (OpenAI):**
- ✅ Version control - diff, rollback, A/B test
- ✅ Portability - reuse across APIs
- ⚠️ Not beginner-friendly - assumes technical knowledge
- ⚠️ Dashboard dependency - can't create via API

**Setup Hooks (Claude Code):**
- ✅ Hybrid reliability - deterministic + intelligent
- ✅ Three-tier complexity - fast/smart/guided
- ✅ CI/CD compatible - `--init-only` for pipelines
- ⚠️ Advanced feature - overkill for simple cases
- ⚠️ Requires scripting - not pure GUI

### 3. Critical Success Factors

#### Authentication UX
- **Best:** Claude Code - auto-prompt on first run, supports multiple auth methods
- **Learning:** Auth should be first blocker, not configuration
- **Fallback:** Windsurf model - if OAuth fails, provide manual code entry

#### Time to First Success
- **Target:** <60 seconds for developers, <5 minutes for business users
- **Pattern:** Working example first, customization later
- **Measurement:** Time from install to first working result

#### Migration Support
- **If targeting existing users:** Make import the default path (Windsurf)
- **If greenfield:** Make fresh start frictionless (Claude Code)
- **Both:** Explicitly name competitors in import options (reduces decision paralysis)

#### Discoverability
- **CLI tools:** Natural language > documentation (Claude Code - "what can you do?")
- **Web tools:** Template gallery > blank canvas (LangChain)
- **IDEs:** Command palette + "Things to Try" (Windsurf)

#### Persistence & Resumability
- **Lesson from AutoGPT:** Save onboarding state, allow logout/refresh
- **Why it matters:** Users get interrupted, need to pick up where they left off
- **Implementation:** Server-side state + GET/PATCH endpoints

### 4. Anti-Patterns to Avoid

❌ **Configuration before authentication** - auth is the real blocker, address it first  
❌ **Docs-first onboarding** - users won't read, make it conversational or guided  
❌ **All-or-nothing setup** - allow incremental configuration, not one giant form  
❌ **No celebration** - first success should feel rewarding (AutoGPT confetti)  
❌ **Hidden import options** - if migration is possible, make it obvious (don't bury it)  
❌ **Irreversible choices** - allow reset/restart (Windsurf "Reset Onboarding")  
❌ **Silent failures** - if auth breaks, provide manual fallback (Windsurf auth code)

---

## Recommended Approach for OpenClaw

Based on competitive analysis:

### Phase 1: Install → Auth → First Success
1. **One-liner install** (Claude Code model)
2. **Auto-prompt login on first run** with multi-provider support
3. **Natural language discovery** - "What can you do?" as first suggestion
4. **Working demo immediately** - show something working before configuration

### Phase 2: Smart Defaults + Templates
1. **BOOTSTRAP.md pattern** - self-explaining setup file (current approach is good!)
2. **Template gallery** - curated starting points (LangChain model)
   - Personal assistant
   - Development agent
   - Research agent
   - Custom (blank slate)
3. **Clone & customize** - don't force users to start from scratch

### Phase 3: Advanced Features
1. **Setup hooks** (Claude Code model) - for complex projects
2. **Versioned prompts** (OpenAI model) - for team collaboration
3. **Migration tools** - import from Claude Desktop, other platforms

### Quick Wins
- ✅ Keep BOOTSTRAP.md - it's working well
- ✅ Add "What can I help you with?" as first-run prompt
- ✅ Create 3-5 template BOOTSTRAP.md files for common use cases
- ✅ Add auth fallback mechanism (manual code entry if OAuth fails)
- ✅ Add "reset onboarding" command for do-overs

---

## Conclusion

**Trend:** Onboarding is moving from "read docs → configure → use" to "authenticate → explore → customize"

**Winner Pattern:** Natural language discovery (Claude Code) + Template gallery (LangChain) + Guided wizard (AutoGPT) = **Three-tier onboarding**

1. **Fast path:** Developers want `curl | bash` → one question → working
2. **Guided path:** Business users want wizard → templates → recommendations
3. **Migration path:** Switchers want "Import from X" → preserve settings → working

**Key Differentiator:** Template quality and ecosystem size (LangChain's 8,000+ tools via MCP is the benchmark)

**OpenClaw's Advantage:** Already has strong foundation with BOOTSTRAP.md and natural language commands - needs template gallery and import tools to compete with established players.
