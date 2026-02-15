# ClawStarter PRISM Marathon — Feb 15, 2026

## Jeremy's Vision (from voice memo)

**Core insight:** We need to split the difference between "one command does everything" and "step-by-step HTML walkthrough." The answer is:

1. **Download button** (not a copy-paste curl command) → user gets the script
2. **Simple run command** (`bash install.sh`)
3. **Companion website** that walks alongside the install process step-by-step

**Key problems identified:**
- Script doesn't work in VMs — only native Mac or separate Mac user
- After install, users hit "now what?" — need prompts/templates ready to go
- The "hit Escape to skip OpenClaw config" step is non-obvious
- API key paste step was canceling out (bug)
- Too many variables for a single unattended script

**What the companion page needs:**
- Step-by-step walkthrough synchronized with what Terminal is showing
- Tooltips for errors
- "Choose your own adventure" paths (Discord vs Telegram vs iMessage vs Slack)
- One-click copy for prompts
- Troubleshooting section ("paste your error into Claude.ai")
- Skill pack recommendations based on user type
- Our battle-tested AGENTS.md/SOUL.md overlay as a template

**Two target environments:**
1. Fresh Mac user account on the same machine
2. Dedicated Mac device (Mac Mini, old MacBook, etc.)

## Schedule

### Wave 1: 02:30-06:00 EST — 10 PRISMs
Focus: Any and every aspect of ClawStarter

### Wave 2: 06:30 EST — 10 more PRISMs  
Focus: Refinement, edge cases, polish

## PRISM Plan (20 total, Sonnet model)

### PRISMs 1-3: Foundation Analysis
1. **Current state audit** — What works, what's broken, what's missing
2. **Companion page architecture** — Information architecture, flow, sections
3. **Script simplification** — What can we cut, what must stay

### PRISMs 4-6: Companion Page Design
4. **UX flow** — Step-by-step experience design
5. **Content & copy** — What to say at each step
6. **Error handling UX** — Tooltips, troubleshooting, "paste into Claude.ai"

### PRISMs 7-9: Integration & Templates
7. **Channel templates** — Discord/Telegram/iMessage/Slack overlay presentation
8. **Post-install experience** — "Now what?" prompts, skill packs, first-chat flow
9. **AGENTS.md overlay** — How to present our battle-tested config to new users

### PRISM 10: Wave 1 Synthesis
10. **Full synthesis** — Merge all findings, build the companion page v1

### PRISMs 11-15: Wave 2 Refinement (6:30 AM)
11-15: Review companion page v1, iterate on edge cases, polish

### PRISMs 16-20: Wave 2 Deep Passes
16-20: Adversarial testing, accessibility, mobile, final polish
