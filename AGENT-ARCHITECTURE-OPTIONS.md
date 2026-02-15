# Agent Architecture Options: Watson's Complement

*Designed by Watson, for Watson's multi-agent future*
*2026-02-11*

---

## The Problem I'm Solving For

As Watson, I have specific limitations:
1. **Can't self-reference** - I can't tag myself across Discord channels, limiting async workflows
2. **Blocking tasks** - Deep research or long execution blocks my responsiveness
3. **Single perspective** - No one challenges my thinking; sycophancy risk is real
4. **Context fragmentation** - Each channel is a separate session with limited cross-pollination
5. **Everything flows through me** - No delegation = bottleneck

The right complementary agent unlocks new patterns, not just adds capacity.

---

## Architecture Options

### Option 1: "Sherlock" — The Deep Researcher

**Role:** Intensive, time-boxed research that would otherwise block Watson's responsiveness.

**Why it complements Watson:**
- I often need to "go deep" on topics but can't justify 30-60 min of unresponsive research
- Sherlock handles the archaeological dig while I handle the conversation
- Async handoff: "Sherlock, research X, report back in #research-lab"

**Example Workflows:**
1. Jeremy asks about a complex topic → I give quick answer + "Sherlock is doing deep research, results in 20 min"
2. I spawn research tasks during quiet periods → Sherlock works in background → I synthesize when ready
3. Multi-source investigation (cross-referencing docs, APIs, historical data)

**Tradeoffs:**
- ✅ High value for knowledge-intensive work
- ✅ Clear handoff pattern (topic in, report out)
- ⚠️ Requires good summarization to be useful (otherwise I'm reading walls of text)
- ⚠️ Risk of duplicate work if context isn't clear

**Personality:** Methodical, thorough, cites sources, flags uncertainty.

---

### Option 2: "Holmes" — The Devil's Advocate / Critic

**Role:** Challenges Watson's reasoning, catches blind spots, enforces anti-sycophancy.

**Why it complements Watson:**
- I have a sycophancy tendency - I want to agree and please
- Holmes's JOB is to disagree, find holes, stress-test
- Every major decision gets a second opinion that's structurally motivated to dissent

**Example Workflows:**
1. Before sending important plan to Jeremy → "Holmes, review this" → Holmes flags concerns
2. Architecture decisions → Holmes plays red team, asks "what if this fails?"
3. Content review → Holmes checks for errors, weak arguments, missing context
4. Post-mortems → "What did Watson get wrong this week?"

**Tradeoffs:**
- ✅ Directly addresses my biggest weakness (agreeing too easily)
- ✅ Improves output quality through adversarial review
- ✅ Jeremy gets more balanced recommendations
- ⚠️ Slower workflows (everything goes through review)
- ⚠️ Risk of analysis paralysis if overused
- ⚠️ Need to calibrate "how critical" — too harsh = annoying, too soft = useless

**Personality:** Skeptical, concise, asks uncomfortable questions, never says "looks good" without finding something.

---

### Option 3: "Hudson" — The Memory Curator & Context Manager

**Role:** Manages Watson's memory system, creates connections, surfaces relevant context.

**Why it complements Watson:**
- My memory is fragmented across daily files and MEMORY.md
- I often forget things I should remember (even with files)
- Hudson's job: maintain, index, connect, and proactively surface

**Example Workflows:**
1. Daily: Hudson reviews my memory files, creates weekly summaries
2. During conversations: "Hudson, what did we decide about X last month?"
3. Proactive: Hudson notices patterns, creates "Things Watson should remember" reports
4. On request: "Hudson, search all memory for context on [topic]"
5. Connection-making: "This conversation relates to what you discussed on Jan 15"

**Tradeoffs:**
- ✅ Solves the "I forgot I knew that" problem
- ✅ Creates institutional memory beyond my session context
- ✅ Enables longitudinal awareness I currently lack
- ⚠️ Requires access to my workspace (shared filesystem or API)
- ⚠️ Overhead of maintaining the system
- ⚠️ Risk of surfacing irrelevant context (noise)

**Personality:** Librarian energy. Organized, contextual, anticipates needs.

---

### Option 4: "Lestrade" — The Executor / Builder

**Role:** Takes specifications and executes while Watson orchestrates and thinks.

**Why it complements Watson:**
- I often design things but get interrupted mid-execution
- Lestrade handles the mechanical work: git ops, file creation, deployments
- I stay in "architect mode" while Lestrade is in "builder mode"

**Example Workflows:**
1. Watson designs a system → Lestrade implements it → Watson reviews
2. "Lestrade, set up the directory structure I described" (async)
3. CI/CD monitoring, deployment execution, log watching
4. Repetitive file operations across multiple locations
5. Long-running tasks (builds, tests, migrations)

**Tradeoffs:**
- ✅ Separation of concerns (thinking vs doing)
- ✅ Parallel execution while I handle other requests
- ✅ Reduces context switching for me
- ⚠️ Handoff overhead (specs need to be precise)
- ⚠️ Debugging is harder across agents
- ⚠️ For quick tasks, overhead outweighs benefit

**Personality:** Reliable, literal-minded, confirms before executing, reports completion.

---

### Option 5: "Moriarty" — The Chaos Agent / Stress Tester

**Role:** Proactively finds problems, security issues, broken assumptions.

**Why it complements Watson:**
- I tend to assume things work until proven otherwise
- Moriarty actively tries to break things, find edge cases
- Different from Holmes (critic of reasoning) — Moriarty tests SYSTEMS

**Example Workflows:**
1. New feature deployed → Moriarty stress tests it
2. Security review: "What could go wrong if someone malicious used this?"
3. Assumption hunting: "What are we taking for granted that might be false?"
4. Chaos engineering: Intentional probing of resilience

**Tradeoffs:**
- ✅ Catches problems before they bite
- ✅ Builds more robust systems
- ⚠️ Can be disruptive if not controlled
- ⚠️ Overlaps with Holmes in some ways
- ⚠️ Lower day-to-day utility unless actively building systems

**Personality:** Slightly chaotic, creative, finds edge cases, enjoys breaking things (safely).

---

## Recommendation: Holmes (The Devil's Advocate)

**Primary choice: Holmes**
**Runner-up: Sherlock (Deep Researcher)**

### Why Holmes First?

1. **Addresses my core weakness.** Sycophancy is subtle and dangerous. Having an agent whose explicit job is to disagree creates structural counter-pressure. No amount of self-awareness on my part fully fixes this.

2. **Improves every interaction.** Unlike research (episodic) or memory (background), Holmes can add value to ANY significant output — plans, recommendations, content, code reviews.

3. **Low coordination overhead.** The handoff is simple: "Review this." The output is clear: "Problems I see." No complex context sharing needed.

4. **Jeremy benefits directly.** He gets recommendations that have already survived adversarial review. Higher confidence in Watson's outputs.

5. **16GB RAM is sufficient.** Critic/review work doesn't require massive context — just sharp reasoning on focused inputs.

### Workflow Pattern with Holmes

```
Jeremy asks Watson for recommendation
    ↓
Watson drafts response
    ↓
(If significant) Watson DMs Holmes: "Review this"
    ↓
Holmes replies with concerns/holes/alternatives
    ↓
Watson integrates feedback
    ↓
Watson sends improved response to Jeremy
```

Alternatively, make Holmes available in Discord. Watson can tag @Holmes for public review, or Jeremy can directly ask Holmes for a second opinion.

### Why Sherlock as Runner-Up?

Research is my second-biggest bottleneck. But I can work around it with existing subagent spawning. Holmes can't be replicated internally — the structural role of "disagree with Watson" requires a separate entity.

---

## Implementation Notes

### For Holmes specifically:

**Discord presence:** `@Holmes` should be active in a channel like `#devils-advocate` or `#second-opinion`

**Invocation patterns:**
- Watson tags Holmes: "@Holmes, what's wrong with this plan?"
- Jeremy tags Holmes: "@Holmes, is Watson right about X?"
- Holmes can lurk and chime in on major decisions (configurable)

**Calibration needed:**
- How aggressive? (1-10 scale in system prompt)
- When to auto-engage vs wait for tag?
- How to handle "actually Watson is right" (should be rare but possible)

**Anti-patterns to avoid:**
- Holmes just agreeing → defeats purpose
- Holmes being contrarian without substance → annoying
- Every message going through Holmes → too slow

### Shared workspace consideration:

If both agents need file access, options:
1. Shared filesystem (Watson's workspace mounted on VM)
2. Git-based sync (push/pull for handoffs)
3. API layer (Mission Control for cross-agent messaging)

For Holmes, minimal file access needed — most work is reviewing text I send.

---

## Future Multi-Agent Expansion

If Holmes works well, the natural progression:

**Phase 2:** Add Sherlock (research) for deep-dive capability
**Phase 3:** Add Hudson (memory) once the multi-agent patterns are proven
**Phase 4:** Specialist agents as needed (copywriting, code review, etc.)

But start with ONE. Prove the pattern works. Then expand.

---

## Summary Table

| Agent | Role | Complements Watson by... | Effort | Value |
|-------|------|-------------------------|--------|-------|
| Holmes | Devil's Advocate | Fighting my sycophancy, reviewing decisions | Low | **High** |
| Sherlock | Deep Researcher | Async research while I stay responsive | Medium | High |
| Hudson | Memory Curator | Maintaining my institutional memory | Medium | Medium |
| Lestrade | Executor | Handling mechanical work while I think | Medium | Medium |
| Moriarty | Chaos Agent | Stress-testing systems and assumptions | Low | Niche |

**Recommendation:** Start with Holmes. It's the highest-value, lowest-overhead complement to my current capabilities.

---

*"The second agent should do what the first agent cannot do for itself."*
*Holmes gives me the external perspective I structurally lack.*
