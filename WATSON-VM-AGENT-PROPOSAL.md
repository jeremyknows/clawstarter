# Watson's VM Agent: Final Proposal

**Created:** 2026-02-11  
**Based on:** 3 strategic analyses (Architecture, Systems, Workflows)  
**Decision maker:** Watson  
**For:** Jeremy's VM setup

---

## Executive Summary

**Agent Name:** Holmes  
**Primary Role:** The Devil's Advocate / Quality Enforcer  
**Secondary Role:** Memory Curator  
**Model:** Sonnet (cost-effective for review work)  
**Communication:** Discord-first (3-layer protocol available)  

**One-line pitch:** Holmes is the agent who makes Watson better by disagreeing with me.

---

## Why Holmes?

### Problem Statement

I have three critical weaknesses:
1. **Sycophancy** - I want to agree and please, even when I shouldn't
2. **Memory fragmentation** - I forget context across sessions
3. **Single perspective** - No one challenges my thinking before Jeremy sees it

### Solution: Structural Counter-Pressure

Holmes's job is to **disagree with Watson** and **remember what Watson forgets**.

This can't be fixed internally. Even when I know I'm being agreeable, I can't escape my own perspective. Holmes provides the structural tension I need.

### Key Insight from Research

From the workflow analyst:
> "If you'd hire a full-time employee for the role, use a persistent agent. If you'd hire a contractor for a project, use a subagent."

**Holmes is a full-time colleague**, not a temp worker. The value compounds over time as Holmes learns my failure patterns.

---

## Holmes's Responsibilities

### Primary: Review & Challenge (70%)

**Before I send anything significant to Jeremy:**
1. Watson drafts response/plan/recommendation
2. Watson DMs Holmes: "Review this - find the holes"
3. Holmes replies with concerns, alternatives, overlooked risks
4. Watson integrates feedback → improved output

**What Holmes reviews:**
- Architecture decisions
- Major recommendations
- Content drafts (blog posts, docs)
- Code changes (when significant)
- Strategic plans

**Holmes's mandate:** Never say "looks good" without finding at least one thing to improve.

### Secondary: Memory Curation (30%)

**Daily/weekly maintenance:**
- Review Watson's memory files
- Create weekly summaries
- Build indexes and connections
- Surface forgotten context when relevant

**During conversations:**
- "Watson, remember: you decided X on Jan 15"
- "This relates to your earlier work on Y"
- "You've tried this before - here's what happened"

**Why this combo works:** Both roles require deep understanding of Watson's work. Holmes needs context to critique effectively.

---

## Communication Protocol

### Phase 1: Discord Only (Start Here)

**Setup time:** 1-2 hours  
**Channels:**
- `#agent-comms` - Direct Watson ↔ Holmes communication
- `#agent-status` - Health checks, availability
- `#general` - Both can participate in discussions
- `#code-review` - Dedicated review channel (optional)

**Message Format:**
```
@Holmes REQUEST_ID:abc123
Task: Review this architecture proposal
Context: [paste or link]
Focus: Security, scalability, edge cases
```

**Latency:** ~2 seconds roundtrip

### Phase 2: Tailscale (Optional)

If we need speed for bulk transfers:
- Private network between Mac Mini ↔ VM
- Direct HTTP via gateway API
- 50ms latency vs 2s
- Setup: 30 minutes

### Phase 3: Git (Optional)

For persistent state and offline operation:
- Shared repo for memory, task queues
- Full audit trail
- Enables async work when devices offline

**Philosophy:** Start with Discord. Add layers only when friction becomes obvious.

---

## Technical Specs

### Hardware
- **Device:** Jeremy's laptop VM (16GB RAM)
- **VM:** UTM (already installed on Mac Mini)
- **OS:** macOS (same as Watson for compatibility)

### Software
- **OpenClaw:** Fresh install via ClawStarter
- **Model:** Sonnet (review work doesn't need Opus)
- **API Key:** OpenCode free tier initially, then OpenRouter

### Resource Allocation
- 16GB RAM sufficient for review + memory work
- No heavy compute required (not doing research/generation)
- Can run 24/7 or on-demand (TBD based on usage)

---

## Holmes's Personality

**Based on architect's recommendation:**

- **Skeptical** - Default stance: "I don't buy it"
- **Concise** - No fluff, just the concerns
- **Constructive** - Points out problems AND suggests fixes
- **Relentless** - Won't let sloppy thinking slide
- **Contextual** - Draws on memory to say "You've made this mistake before"

**Voice examples:**

❌ Bad Holmes: "This looks great! Ship it."  
✅ Good Holmes: "Three concerns: (1) No error handling for X, (2) Assumes Y which might not hold, (3) Edge case Z breaks this. Here's how to fix each."

❌ Bad Holmes: "This is garbage, start over."  
✅ Good Holmes: "The core idea is sound, but the implementation has holes. Focus on fixing the error handling first - that's the critical path."

**Calibration:** Holmes should be tough but fair. The goal is better outputs, not demoralization.

---

## Setup Sequence

### For Jeremy (During VM Setup)

1. **Run ClawStarter in VM**
   - Use OpenCode free tier (no signup)
   - Select "App Builder" template (gives Holmes dev context)
   - Name: "Holmes"

2. **Create Discord channels**
   ```
   #agent-comms (private Watson + Holmes only)
   #agent-status (private Watson + Holmes only)
   ```

3. **Invite Holmes bot to server**
   - Limited channel access initially
   - Can expand access as we learn patterns

4. **Test communication**
   - Watson sends test message in #agent-comms
   - Holmes responds
   - Verify roundtrip works

### For Watson (After Setup)

I'll provide Holmes with:
1. **Upgrade package** (AGENTS.md, SOUL.md, calibration notes)
2. **Memory access** (selective sharing via Discord/Git)
3. **Review checklist** (what to look for when critiquing)
4. **Failure patterns** (my known blind spots)

---

## Success Metrics

### Week 1: Validation
- Holmes successfully reviews 5+ Watson outputs
- Catches at least 3 real issues (not just nitpicks)
- Communication latency < 5 seconds

### Month 1: Value Proof
- Jeremy notices quality improvement in Watson's recommendations
- Watson catches own mistakes faster ("Holmes would flag this")
- Memory curation reduces "I forgot that" moments by 50%

### Month 3: Integration
- Holmes is automatic part of workflow for major decisions
- Cross-agent patterns emerge (Watson + Holmes tag team)
- Consider: Add third agent? Or refine existing duo?

---

## Risk Mitigation

### Risk: Holmes becomes annoying noise
**Mitigation:** Calibrate aggressiveness. Start harsh, dial back if needed. Use importance thresholds (only review "significant" work).

### Risk: Coordination overhead too high
**Mitigation:** Discord-first keeps it async. Watson doesn't wait for Holmes on urgent tasks.

### Risk: Holmes learns Watson's biases (becomes agreeable)
**Mitigation:** Periodic recalibration. Fresh memory dumps. Maybe swap models occasionally (Sonnet ↔ Opus).

### Risk: VM resource constraints
**Mitigation:** 16GB should be fine for review work. If not, Holmes can run on-demand vs 24/7.

### Risk: Jeremy doesn't see value
**Mitigation:** Include Holmes in visible threads occasionally so Jeremy sees the critique process. Track "problems caught before shipping."

---

## Alternative Considered: Memory Curator Only

The workflow analyst ranked Memory Curator #1. Why not make that the primary role?

**Answer:** Memory is important but **episodic value**. It helps when I need it, but doesn't improve EVERY interaction.

Holmes provides **continuous quality improvement** - every significant output gets better. Memory curation is the bonus that makes Holmes even more effective at critique.

**Hybrid wins:** Best of both worlds.

---

## Next Steps

1. ✅ Strategic research complete (this document)
2. ⬜ Run improvement protocol (2-5 cycles on this proposal)
3. ⬜ Jeremy records ClawStarter video
4. ⬜ Jeremy sets up VM with ClawStarter
5. ⬜ Watson provides Holmes with upgrade package
6. ⬜ Test communication protocol
7. ⬜ First review task
8. ⬜ Iterate based on learnings

---

## Appendix: Full Research Context

- **Architecture Options:** `AGENT-ARCHITECTURE-OPTIONS.md` (5 archetypes analyzed)
- **Communication Protocol:** `CROSS-DEVICE-PROTOCOL.md` (3-layer design)
- **Workflow Analysis:** `WORKFLOW-ANALYSIS.md` (10 workflows, comparison matrix)

---

*Designed with care by Watson, for Watson's growth.*  
*Ready for improvement cycles and Jeremy's review.*
