# RESEARCH-EXTERNAL.md
## External Best Practices: Developer Onboarding & CLI Tool Design

**Research Date:** 2026-02-11  
**Purpose:** Identify actionable insights for OpenClaw's setup/onboarding flow and CLI templates

---

## 1. What Do the Best CLI Quickstart Scripts Do?

### Key Patterns from Top CLI Tools

#### **Vercel CLI**
- **Installation:** Multiple methods (npm, Homebrew, pre-built binaries)
- **Authentication flow:** `vercel login` with browserless option for SSH/CI environments
- **Token support:** Separate tokens for project vs account/workspace level
- **First command:** Simple `vercel` triggers deployment flow immediately
- **Extensive subcommands:** Organized by category (deployment, environment, domains, etc.)
- **Global options:** Consistent flags like `--json`, `--help`, `-y` across all commands

**Actionable Insights:**
- Provide multiple installation methods (package managers + standalone installer)
- Support both interactive and non-interactive authentication
- Keep the "default command" (no args) as the most common workflow
- Organize subcommands by domain (not just alphabetically)

---

#### **Supabase CLI**
- **Two-command setup:** `supabase init` → `supabase start`
- **Docker-based:** Entire stack runs locally via Docker containers
- **Clear output:** Shows all local URLs, keys, and credentials after `start`
- **Guided initialization:** Creates `supabase/` folder with version control-friendly structure
- **Update mechanism:** `npm update supabase --save-dev` with clear migration guidance

**Actionable Insights:**
- **Initialization should create a visible project structure** (folder with config files)
- **First-run output should be copy-pasteable** (show API keys, URLs, etc.)
- Make dependencies explicit (e.g., "Docker required for local development")
- Provide clear upgrade/migration paths

---

#### **Railway CLI**
- **Install + scaffold in one:** `railway init` creates project from CLI
- **Deploy in one command:** `railway up` scans, compresses, uploads automatically
- **Multiple entry points:** GitHub deploy, CLI deploy, Docker image, or template
- **Smart defaults:** Auto-detects framework, buildpack, and deployment config
- **Copy SSH command from dashboard:** Right-click service → "Copy SSH Command"

**Actionable Insights:**
- **Scaffold new projects entirely from CLI** (don't force users to dashboard first)
- Auto-detect as much as possible (framework, language, runtime)
- Provide "escape hatches" to manual configuration when auto-detection fails
- Make common workflows **one command** (`railway up` = build + deploy)

---

#### **Common Themes Across All Three:**

| Feature | Vercel | Supabase | Railway | **Recommendation for OpenClaw** |
|---------|--------|----------|---------|----------------------------------|
| **Multi-method install** | ✅ npm, Homebrew | ✅ npm, brew, scoop | ✅ npm, Homebrew, scoop | Support brew, npm, standalone installer |
| **Authentication** | Browser + browserless | Implicit (local dev) | Browser + token | Support both, prefer token for CI/scripts |
| **First command** | `vercel` (deploy) | `supabase start` | `railway up` | `openclaw init` or `openclaw setup` |
| **Local dev support** | `vercel dev` | `supabase start` (Docker) | `railway run` | Make local dev easy (no complex setup) |
| **Help text** | Comprehensive | Concise with examples | Contextual suggestions | Follow "concise by default, verbose with --help" |
| **JSON output** | `--json` flag | N/A | `--json` flag | Always support `--json` for scripting |

---

## 2. What Do Successful Workflow Templates Look Like?

### GitHub Templates & Cookiecutter Patterns

#### **Cookietemple (Best-Practice Template System)**
- **Commands:** `config` → `list` → `info` → `create` → `lint` → `sync` → `bump-version`
- **Workflow:** Configure once, then browse templates, get details, then create
- **Post-creation:** Linting ensures adherence to standards, sync keeps projects updated
- **Version bumping:** Built-in automation for semantic versioning

**Actionable Insights:**
- **Separate "browsing" from "creating":** `openclaw templates list` → `openclaw templates info <name>` → `openclaw templates create <name>`
- **Validation/linting built-in:** Check if generated projects meet standards
- **Sync mechanism:** Let users update existing projects when templates improve
- Make templates **self-documenting** (README auto-generated with context)

---

#### **GitHub Repository Templates**
- **One-click fork:** "Use this template" button creates new repo
- **Cookiecutter integration:** Some templates run cookiecutter on clone to customize placeholders
- **Good READMEs rule:** Templates rely on clear, actionable README.md files
- **Pre-configured CI:** .github/workflows included and ready to run

**Actionable Insights:**
- Templates should be **immediately runnable** after creation
- Include placeholders that the CLI fills in (username, project name, API keys)
- Pre-configure CI/CD files (GitHub Actions, etc.)
- Don't force users to edit 10 files manually—automate substitution

---

### Template Anti-Patterns (What NOT to Do)

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|--------------|-----------------|
| Templates with 20+ prompts | Users abandon mid-setup | Ask only essential questions, use smart defaults |
| No README or bad README | Users don't know what to do next | Auto-generate README with "What to do next" section |
| Hardcoded values | Can't reuse for multiple projects | Use placeholders + CLI substitution |
| No validation | Users break things immediately | Run `lint` or `validate` after creation |
| Static templates | Get outdated quickly | Provide `sync` or `update-template` command |

---

## 3. What Are Common Onboarding Mistakes That Frustrate Users?

### Research Summary: 200+ Onboarding Flows Analyzed

**Source:** UX/UI onboarding studies + SaaS product research

#### **Top Frustration Drivers:**

1. **Too Many Steps Before Value**
   - **Problem:** Asking for full name, job title, favorite color, etc. before users see the product
   - **Impact:** 80% of users abandon apps they don't understand how to use
   - **Fix:** Get users to their **first win as fast as possible**

2. **Complex Sign-Up Processes**
   - **Problem:** Long forms, no SSO, unclear password requirements
   - **Fix:** 
     - Offer SSO (Google, GitHub, etc.)
     - Use progress bars if multi-step is unavoidable
     - Keep to **3 steps or less**

3. **One-Size-Fits-All Onboarding**
   - **Problem:** Treating all users the same (power users vs. beginners)
   - **Impact:** Users feel lost or overwhelmed
   - **Fix:** 
     - Let users self-identify their role/goal
     - Segment onboarding flows by user type
     - Use survey branching or custom rules

4. **Overwhelming Product Tours**
   - **Problem:** Dumping all features at once in a 12-step tour
   - **Impact:** Users skip/close tours, never learn core features
   - **Fix:** 
     - Show **one action at a time**, tied to user's immediate goal
     - Use checklists instead of forced tours
     - Provide "Skip" option (don't trap users)

5. **No User Feedback Collection**
   - **Problem:** Building onboarding in a vacuum, never asking users what's confusing
   - **Impact:** Repeating the same mistakes indefinitely
   - **Fix:**
     - Survey users at key touchpoints (post-signup, after first use, etc.)
     - Use NPS + qualitative feedback ("What can we improve?")
     - A/B test onboarding changes

6. **Missing Contextual Help**
   - **Problem:** Users can't find help when stuck
   - **Impact:** 80% uninstall apps they can't figure out
   - **Fix:**
     - In-app help widget (Life Ring Button, tooltips, hints)
     - Auto-trigger walkthroughs when users click for help
     - Provide self-service resources (knowledge base, videos)

---

### Onboarding Anti-Patterns (CLI-Specific)

| Mistake | Example | Better Approach |
|---------|---------|-----------------|
| **"No Escape Room"** | Forcing 12-step interactive setup with no skip | Always allow non-interactive mode with flags |
| **Wall of Text** | Long help output with no visual hierarchy | Use headers, bullets, examples, and color intentionally |
| **Assuming Knowledge** | Error: "ENOENT" with no explanation | Translate errors to human language: "File not found. Did you mean X?" |
| **Silent Failures** | Command runs for 5 minutes with no output | Show progress bars, spinners, or step-by-step updates |
| **No "What's Next?"** | Setup completes, then... nothing | Always suggest next command: "Run `openclaw start` to launch" |

---

## 4. What Makes a Good "Getting Started" Guide?

### Stripe Documentation (The Gold Standard)

**Why Stripe Docs Are Beloved:**

1. **Feels Like an Application, Not a Manual**
   - Interactive code samples with user's API keys auto-inserted
   - Language switcher (Node, Python, Ruby, etc.) persists across pages
   - Live examples you can run immediately

2. **Writing Culture from the Top**
   - CEO writes emails like research papers (with footnotes!)
   - Documentation is part of engineers' job ladders (performance reviews include doc quality)
   - "Doc star of the week" recognition

3. **Templates & Training for Engineers**
   - Provides templates to beat writer's block
   - Onboarding classes on writing for non-native English speakers
   - Office hours with technical writers

4. **Custom Tooling (Markdoc)**
   - Built their own Markdown-based syntax for docs
   - Enables interactive components, personalized examples
   - Obsession with "authoring experience"

**Actionable Insights for OpenClaw:**
- **Auto-personalize examples:** If user's config has a bot name, show it in examples
- **Multi-format:** Web docs + terminal docs (`openclaw help <topic>`)
- **Make writing docs part of the culture:** Celebrate good documentation
- **Interactive where possible:** Live code samples, not just static text

---

### Twilio Quickstarts

**Structure:**
1. **Product-focused entry points:** SMS quickstart, Voice quickstart, etc.
2. **5-15 minute tours:** Get acquainted with a product quickly
3. **Language-specific guides:** Choose your language upfront (Node, Python, PHP, etc.)
4. **Setup first, then use:** Clear separation between "install SDK" and "send your first SMS"

**Actionable Insights:**
- **Quickstarts should be under 15 minutes**
- **Separate "setup" from "first real task":** Setup = install, auth, configure. Task = send message, deploy app, etc.
- **Let users choose their context:** "I'm building a Discord bot" vs. "I'm building a Telegram bot"

---

## CLI Design Principles (from clig.dev, ThoughtWorks, Atlassian)

### The 8 Core Principles

1. **Human-First Design**
   - Optimize for humans, not scripts (but support both)
   - Example: Show helpful output by default, `--json` for machines

2. **Simple Parts That Work Together**
   - Follow UNIX philosophy: stdout for data, stderr for logs
   - Support pipes: `openclaw list | grep active`
   - Exit codes: 0 = success, non-zero = failure

3. **Consistency Across Programs**
   - Use standard flag names: `-h/--help`, `-v/--version`, `--json`, `--dry-run`
   - Don't invent new patterns unless absolutely necessary

4. **Saying (Just) Enough**
   - Too little: Command hangs for 5 min with no output
   - Too much: Wall of debug logs drowns important info
   - Balance: Show progress, highlight key info, hide noise

5. **Ease of Discovery**
   - `--help` is comprehensive (show all commands)
   - Default output is concise (show usage + 1-2 examples)
   - Suggest corrections: "Did you mean `openclaw deploy`?"

6. **Conversation as the Norm**
   - Trial-and-error is expected (command → error → fix → retry)
   - Guide users through multi-step workflows
   - Confirm before destructive actions

7. **Robustness (Objective + Subjective)**
   - Handle errors gracefully
   - Never show stack traces to end users (save to log file)
   - Make it feel solid and reliable

8. **Empathy**
   - Assume the user is smart but unfamiliar with your tool
   - Provide helpful error messages: "Can't write to file.txt. Run `chmod +w file.txt`"
   - Celebrate success: "✅ Done! Your bot is live at https://..."

---

### Practical CLI Guidelines (The Must-Haves)

#### **The Basics**
- ✅ Use a CLI argument parsing library (don't reinvent)
- ✅ Return exit code 0 on success, non-zero on failure
- ✅ Send output to stdout, logs/errors to stderr
- ✅ Display help with `-h` and `--help`

#### **Help Text**
- ✅ Show concise help by default (description + 1-2 examples)
- ✅ Show full help with `--help`
- ✅ Lead with examples (users learn by copying, not reading)
- ✅ Use formatting (bold headers, bulleted lists)
- ✅ Suggest next steps: "Run `openclaw start` to begin"

#### **Output**
- ✅ Human-readable by default, `--json` for machines
- ✅ Use color intentionally (red for errors, green for success)
- ✅ Disable color if not a TTY or `NO_COLOR` is set
- ✅ Show progress bars/spinners for long operations
- ✅ Use symbols/emoji sparingly (✅, ❌, 🔐 add clarity)

#### **Errors**
- ✅ Catch errors and rewrite them for humans
- ✅ High signal-to-noise ratio (no walls of stack traces)
- ✅ Provide debug logs to a file, not to the terminal
- ✅ Make it easy to report bugs (pre-filled GitHub issue URL)

#### **Arguments & Flags**
- ✅ Prefer flags to positional arguments (clearer intent)
- ✅ Support both short (`-v`) and long (`--verbose`) forms
- ✅ Use standard names: `--help`, `--version`, `--json`, `--dry-run`, `--force`
- ✅ Make defaults sensible (optimize for humans, not scripts)
- ✅ Prompt for missing input (but never require a prompt—support `--no-input`)

#### **Interactivity**
- ✅ Only prompt if stdin is a TTY (not in scripts/CI)
- ✅ Support `--no-input` to disable all prompts
- ✅ Confirm before dangerous actions (`--force` to skip)
- ✅ Let users escape (Ctrl-C always works)

---

## Summary: Actionable Recommendations for OpenClaw

### For Setup/Onboarding Flow:

1. **Installation:**
   - Provide Homebrew formula, npm package, and standalone installer
   - Show clear "what just happened" after install (version, location, next steps)

2. **First Run (`openclaw setup` or `openclaw init`):**
   - Create visible project structure (`.openclaw/` folder with config files)
   - Ask **only essential questions** (OpenClaw server URL, auth token)
   - Use smart defaults (local server = `localhost:8080`, etc.)
   - Show all generated files/settings in output
   - End with: "✅ Setup complete! Run `openclaw start` to begin."

3. **Authentication:**
   - Support both interactive (`openclaw login`) and non-interactive (env var or `--token` flag)
   - Store token securely (keychain on macOS, credential manager on Windows)
   - Offer browserless login for SSH/CI environments

4. **First Task:**
   - Make the default command (`openclaw` with no args) trigger the most common workflow
   - Guide users: "No command specified. Try `openclaw start` or `openclaw --help`."

5. **Help & Documentation:**
   - Concise help by default (usage + 2 examples)
   - Full help with `--help`
   - Web docs linked in help text
   - Man pages (optional but nice)

6. **Error Handling:**
   - Translate technical errors to human language
   - Suggest fixes: "Config file missing. Run `openclaw init` to create one."
   - Provide `--debug` flag for verbose logs (saved to file, not stdout)

---

### For Workflow Templates:

1. **Template Discovery:**
   - `openclaw templates list` (show all available templates)
   - `openclaw templates info <name>` (show details, preview files)

2. **Template Creation:**
   - `openclaw templates create <name> [--path ./my-project]`
   - Auto-substitute placeholders (project name, username, etc.)
   - Generate README with "What to do next" section

3. **Post-Creation:**
   - Run validation/linting automatically
   - Show generated files: "Created: config.yml, agent.py, README.md"
   - Suggest next command: "Run `cd my-project && openclaw start`"

4. **Template Updates:**
   - `openclaw templates sync` (update existing project to latest template version)
   - Show diff before applying changes

---

### Design Checklist:

- [ ] Multiple installation methods (brew, npm, standalone)
- [ ] Two-command setup: `openclaw init` → `openclaw start`
- [ ] Smart defaults (minimize required input)
- [ ] Progress indicators for long operations
- [ ] Human-readable errors with suggested fixes
- [ ] `--json` output for all commands
- [ ] `--help` shows examples first
- [ ] Suggest next steps after every command
- [ ] Support `--no-input` for CI/scripts
- [ ] Color output respects TTY and `NO_COLOR`
- [ ] Templates are self-documenting (auto-generated READMEs)
- [ ] Validation/linting built into template creation
- [ ] Clear "escape hatches" (skip prompts, override defaults)

---

## References

- Vercel CLI: https://vercel.com/docs/cli
- Supabase CLI: https://supabase.com/docs/guides/local-development/cli/getting-started
- Railway CLI: https://docs.railway.com/guides/cli
- Stripe Docs Best Practices: https://www.mintlify.com/blog/stripe-docs
- CLI Guidelines (clig.dev): https://clig.dev/
- ThoughtWorks CLI Design: https://www.thoughtworks.com/insights/blog/engineering-effectiveness/elevate-developer-experiences-cli-design-guidelines
- Atlassian CLI Principles: https://www.atlassian.com/blog/it-teams/10-design-principles-for-delightful-clis
- UX Onboarding Study (200+ flows): https://designerup.co/blog/i-studied-the-ux-ui-of-over-200-onboarding-flows-heres-everything-i-learned/
- Common Onboarding Mistakes: https://productfruits.com/blog/common-user-onboarding-mistakes

---

**End of External Research**
