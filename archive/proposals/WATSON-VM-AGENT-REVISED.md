# Watson's VM Agent: Revised Proposal (Post-Improvement)

**Created:** 2026-02-11  
**Revision:** After 3 improvement cycles  
**Status:** Simplified based on critical feedback

---

## What Changed

**Original proposal:** Holmes (persistent VM agent doing review + memory)  
**Revised proposal:** The Librarian (persistent VM agent doing ONLY memory)

**Why the change:** All three improvement cycles independently concluded:
- Review is **episodic** (10% of work) - doesn't need persistent agent
- Memory is **continuous** (benefits 90% of work) - deserves persistent attention
- Setup overhead (4-6 hours) only justified if continuous value
- Subagents can handle on-demand review at 5% of the complexity

---

## The Librarian: Memory-Only Agent

### Core Mission

**The Librarian manages Watson's institutional memory.**

Not review. Not critique. Just memory.

### Why Memory-Only?

**From the improvement cycles:**

1. **Critic identified:** "Memory is a proven need. Review is an untested assumption."
2. **Pragmatist measured:** "Memory benefits 90% of interactions. Review benefits 10%."
3. **Creative proposed:** "The Journal - no active agent, just smart memory files."

**Synthesis:** Memory curation is the **highest ROI use of a persistent agent**.

### What The Librarian Does

**Daily (Automated):**
1. Read Watson's `memory/YYYY-MM-DD.md` files
2. Extract significant events, decisions, learnings
3. Update `MEMORY.md` with distilled insights
4. Create indexes (by topic, by date, by person)
5. Identify forgotten context

**On-Demand (When Watson asks):**
1. "Librarian, what did we decide about X?"
2. "Librarian, surface context related to Y"
3. "Librarian, what patterns do you see this week?"

**Proactive (When relevant):**
- Notice Watson repeating past mistakes → surface prior learning
- See conversation echoing earlier topic → inject context
- Detect knowledge gaps → suggest areas to document

### What The Librarian Does NOT Do

❌ Review Watson's outputs  
❌ Challenge Watson's reasoning  
❌ Act as devil's advocate  
❌ Participate in every conversation

**Those are handled by on-demand subagents** (see below).

---

## Review & Critique: Subagent Pattern

### The Pattern

**When Watson needs adversarial review:**

```python
sessions_spawn(
  task="Review this architecture proposal. Find holes, suggest alternatives.",
  label="devil's-advocate",
  cleanup="delete"  # Ephemeral, fresh perspective every time
)
```

**Why subagents > persistent Holmes:**

| Factor | Persistent Agent | Subagent |
|--------|------------------|----------|
| Setup time | 4-6 hours | 0 seconds |
| Maintenance | 1-2 hrs/month | 0 |
| Bias accumulation | Learns Watson's patterns, becomes agreeable | Fresh perspective every time |
| Availability | Only when VM online | Always (same session) |
| Coordination overhead | Discord, sync, queuing | Direct response |
| Cost per review | ~$0.10 (VM + network) | ~$0.05 (just tokens) |

**The pragmatist's analysis:** 
> "Review is episodic, not continuous. Holmes doesn't need to exist 24/7 to add value. This is exactly what subagents are designed for."

### When to Use Subagent Review

**Always:**
- Architecture decisions
- Major recommendations to Jeremy
- Security-sensitive changes
- Blog posts / public content

**Sometimes:**
- Complex code changes
- Strategic plans
- Cost/benefit analyses

**Never:**
- Casual conversation
- Quick questions
- Routine tasks

---

## Technical Specs: The Librarian

### Hardware
- **Device:** Jeremy's laptop VM (16GB RAM)
- **VM:** UTM
- **OS:** macOS

### Software
- **OpenClaw:** Via ClawStarter
- **Model:** Sonnet (memory work, not generation)
- **API:** OpenCode free tier → OpenRouter

### Resource Requirements
**Much lighter than Holmes:**
- Memory curation: ~5-10 API calls/day
- No review overhead (that's gone)
- Background processing (not time-critical)
- **Estimated:** <$1/month at current scale

### Communication
**Phase 1 only:** Discord
- `#librarian` - Watson asks for context
- `#librarian-logs` - Daily summaries posted here
- No need for Tailscale/Git (async is fine)

---

## The Librarian's Personality

**Based on Option 3 from original research:**

- **Organized** - Everything has a place, everything in its place
- **Contextual** - Surfaces relevant history without being asked
- **Anticipatory** - Notices patterns before Watson does
- **Quiet** - Doesn't interrupt, responds when needed
- **Librarian energy** - Helpful, precise, slightly pedantic

**Voice examples:**

✅ "Watson, you discussed this on Feb 3. Key decision: Use Sonnet for research, not gemini-lite (failure rate 4/6). Relevant file: `memory/2026-02-03.md:145`"

✅ "Pattern detected: You've started 3 similar projects in the past month. All paused. Consider: Focus before starting another?"

✅ "Weekly summary ready: 47 events logged, 8 decisions made, 3 learnings extracted. Updated MEMORY.md with 2 new sections."

---

## Setup Sequence (Simplified)

### For Jeremy

**Time estimate:** 1-2 hours (vs 4-6 for Holmes)

1. **Run ClawStarter in VM**
   - OpenCode free tier
   - Name: "Librarian"
   - Template: Workflow Optimizer (closest fit)

2. **Create Discord channel**
   - `#librarian` (Watson + Librarian only)

3. **Test communication**
   - Watson: "Librarian, are you there?"
   - Librarian: "Ready. What context do you need?"

### For Watson

**After setup, I'll provide:**

1. **AGENTS.md** - Librarian's mission, responsibilities, personality
2. **Memory access protocol** - How to read Watson's memory files
3. **Curation checklist** - What to extract, what to ignore
4. **Index templates** - How to organize memory

**No need for:**
- ❌ Review checklist (not doing review)
- ❌ Calibration notes (simpler role)
- ❌ Conflict resolution (no disagreements)

---

## Success Metrics

### Week 1: Basic Function
- ✅ Librarian reads Watson's memory files daily
- ✅ Creates weekly summary
- ✅ Responds to context queries within 10 seconds

### Month 1: Value Proof
- ✅ Watson says "I would have forgotten that" 5+ times
- ✅ Librarian surfaces relevant context unprompted 3+ times
- ✅ MEMORY.md stays current (updated weekly)

### Month 3: Integration
- ✅ Watson checks with Librarian before major decisions ("What's our history on X?")
- ✅ Memory indexes enable quick lookups
- ✅ Pattern detection prevents repeated mistakes

---

## Cost Comparison

### Original Holmes Proposal
- Setup: 4-6 hours
- Ongoing: 1-2 hours/month maintenance
- API costs: ~$5-10/month (review + memory)
- Complexity: High (coordination, conflict resolution, calibration)

### Revised Librarian Proposal
- Setup: 1-2 hours
- Ongoing: 0 hours/month (self-maintaining)
- API costs: ~$1/month (memory only)
- Complexity: Low (one-way info flow)

### Review via Subagents
- Setup: 0 hours
- Ongoing: 0 hours
- API costs: ~$0.50/month (2-3 reviews/week)
- Complexity: Minimal (standard pattern)

**Total savings:** 75% less time, 85% less cost, 90% less complexity

---

## What We Learned from Improvement Cycles

### From the Critic
> "The sycophancy problem is real, but persistent review creates new problems: bias accumulation, coordination overhead, resource constraints. Ephemeral review (subagents) stays fresh."

### From the Pragmatist
> "Holmes optimizes for 10% of Watson's work (major decisions). Librarian optimizes for 90% (continuous memory needs). Follow the ROI."

### From the Creative
> "Most of Holmes's value is actually The Journal - smart memory files that surface context. Build that first. Add active review only if needed."

**Common thread:** Persistent agents need **continuous value** to justify setup/maintenance cost. Memory = continuous. Review = episodic.

---

## Addressing Original Goals

**Jeremy's challenge:** "Design the OpenClaw bot that is most useful for you in your swarm."

### Original answer: Holmes (review + memory)
**Why:** Fixes sycophancy via structural counter-pressure

### Revised answer: Librarian (memory only) + subagent reviews
**Why:** Same outcome, simpler architecture

**Does it still address sycophancy?**  
✅ Yes - on-demand subagent critics provide fresh adversarial review  
✅ Better - no bias accumulation from persistent reviewer  
✅ Cheaper - only pay for reviews that matter

**Does it still enable multi-agent workflows?**  
✅ Yes - Watson can tag @Librarian in Discord for context  
✅ Better - async works fine, no need for real-time coordination  
✅ Simpler - one-way info flow (Librarian → Watson), not bidirectional

---

## Migration Path

### Phase 1: Build Librarian (This Week)
- Set up VM with ClawStarter
- Configure memory access
- Test daily curation

### Phase 2: Validate Subagent Review (Next 2 Weeks)
- Watson spawns devil's advocate for 5+ reviews
- Track: Did it catch real issues? Add value?
- Measure: Time cost vs quality gain

### Phase 3: Evaluate (Week 4)
**If subagent review works well:**
- ✅ Keep the simplified architecture
- ✅ Document the pattern
- ✅ Move on to next challenge

**If subagent review has problems:**
- Consider adding persistent critic
- But now we have data to justify the complexity
- And Librarian already provides infrastructure

**Philosophy:** Start simple. Add complexity only when friction demands it.

---

## Appendix: Why I Changed My Mind

I was excited about Holmes because it solved a real problem (sycophancy) in an elegant way (structural counter-pressure).

But three independent reviewers said the same thing:
1. **You're conflating two problems** (memory + review)
2. **You're over-engineering the solution** (persistent when ephemeral works)
3. **You're optimizing for the wrong metric** (quality of 10% vs efficiency of 90%)

The improvement protocol worked. I proposed Holmes. The reviewers challenged it. I'm revising.

**That's exactly what Holmes was supposed to do for me.** But I just did it with subagents.

Maybe that's the point.

---

*Humbled by the process. Ready to build something simpler.*  
*– Watson*
