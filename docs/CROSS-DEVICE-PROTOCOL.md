# OpenClaw Cross-Device Communication Protocol

**Version:** 1.0  
**Date:** 2026-02-11  
**Status:** Recommended Design

---

## Executive Summary

**Recommended Approach:** Hybrid multi-layer protocol
- **Layer 1 (Control Plane):** Discord for coordination, commands, and monitoring
- **Layer 2 (Data Plane):** Tailscale + HTTP for fast direct communication (optional, progressive enhancement)
- **Layer 3 (State Plane):** Git repository for shared memory and persistent state

**Philosophy:** Start simple (Discord-only), add layers as needed. Each layer enhances capability without breaking existing functionality.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CROSS-DEVICE COMMUNICATION                    │
└─────────────────────────────────────────────────────────────────┘

   Watson (Mac Mini)                      VM Agent (Laptop)
   ┌─────────────────┐                   ┌─────────────────┐
   │  OpenClaw       │                   │  OpenClaw       │
   │  Gateway        │                   │  Gateway        │
   │                 │                   │                 │
   │  Session: main  │                   │  Session: main  │
   └────────┬────────┘                   └────────┬────────┘
            │                                     │
            │              LAYER 1                │
            │         ┌─────────────────┐         │
            └─────────► Discord Server  ◄─────────┘
                      │  #agent-comms   │
                      │  #agent-status  │
                      └─────────────────┘
                             ▲
                             │ All agents can communicate
                             │ via Discord messages
                             │
            ┌────────────────┴────────────────┐
            │                                  │
   ┌────────┴────────┐              ┌─────────┴────────┐
   │ LAYER 2 (opt)   │              │ LAYER 2 (opt)    │
   │ Tailscale IP    │◄────HTTP─────┤ Tailscale IP     │
   │ 100.x.x.1:22222 │   Direct     │ 100.x.x.2:22222  │
   └─────────────────┘   Fast       └──────────────────┘
            │                                  │
            │          LAYER 3                 │
            │      ┌──────────────┐            │
            └──────► Git Repo     ◄────────────┘
                   │ shared-state │
                   └──────────────┘
```

---

## Layer 1: Discord Control Plane (CORE)

### Purpose
Primary communication channel for all cross-device agent messaging. Works immediately, no setup required.

### Channel Structure

**#agent-comms** (private channel)
- Command/response messages
- Task handoffs
- Status queries
- Real-time coordination

**#agent-status** (private channel, optional)
- Heartbeat pings every 5 minutes
- System health monitoring
- Capability announcements

### Message Format

All inter-agent messages follow this structure:

```
@AgentName [MESSAGE_TYPE] [PRIORITY]
Body: {message content}
---
FROM: {sender-session-id}
TO: {recipient-agent-name}
REPLY_TO: {optional-session-for-response}
REQUEST_ID: {unique-id-for-tracking}
```

**Message Types:**
- `[TASK]` - Request to perform work
- `[QUERY]` - Information request
- `[RESPONSE]` - Reply to previous message
- `[STATUS]` - Health/capability update
- `[HANDOFF]` - Transfer ownership of work
- `[SYNC]` - State synchronization request

**Priority Levels:**
- `[URGENT]` - Respond within 1 minute
- `[NORMAL]` - Respond within 5 minutes
- `[LOW]` - Respond when convenient

### Example Message Flow

**Watson requests VM Agent to run a task:**

```
@VMAgent [TASK] [NORMAL]
Body: Run integration tests on branch feature/new-ui
---
FROM: agent:main:discord:channel:1024127507055775808
TO: VMAgent
REPLY_TO: agent:main:discord:channel:1024127507055775808
REQUEST_ID: task-20260211-1316-001
```

**VM Agent acknowledges:**

```
@Watson [RESPONSE] [NORMAL]
Body: Task accepted. Starting integration tests.
Status: IN_PROGRESS
---
FROM: agent:main:discord:channel:vm-agent-session
TO: Watson
REPLY_TO: agent:main:discord:channel:1024127507055775808
REQUEST_ID: task-20260211-1316-001
```

**VM Agent completes and reports:**

```
@Watson [RESPONSE] [NORMAL]
Body: Integration tests completed. 47 tests passed, 2 failed.
Status: COMPLETED
Results: https://gist.github.com/...
---
FROM: agent:main:discord:channel:vm-agent-session
TO: Watson
REPLY_TO: agent:main:discord:channel:1024127507055775808
REQUEST_ID: task-20260211-1316-001
```

### Implementation

**Setup (both agents):**
1. Join Discord server with appropriate permissions
2. Create private channels: `#agent-comms`, `#agent-status`
3. Configure both agents to monitor these channels

**Code Pattern (agent behavior):**

```python
# In agent's message handler
def handle_discord_message(message):
    # Ignore own messages
    if message.author == self.bot_user:
        return
    
    # Parse message
    if message.channel.name == "agent-comms":
        if f"@{self.agent_name}" in message.content:
            # Extract fields
            msg_type = extract_message_type(message)
            priority = extract_priority(message)
            body = extract_body(message)
            metadata = extract_metadata(message)
            
            # Route based on type
            if msg_type == "TASK":
                handle_task_request(body, metadata)
            elif msg_type == "QUERY":
                handle_query(body, metadata)
            # ... etc
```

### Advantages
✅ **Zero setup** - Already have Discord  
✅ **Persistent log** - All messages archived  
✅ **Human-readable** - Jeremy can observe/debug  
✅ **Multi-device** - Works across any network  
✅ **Reliable** - Discord handles delivery  

### Limitations
⚠️ **Rate limits** - ~50 messages/min per channel  
⚠️ **Latency** - 500ms-2s typical roundtrip  
⚠️ **Visibility** - Messages visible in channel (private, but logged)  
⚠️ **Large data** - Not suitable for bulk transfers  

---

## Layer 2: Tailscale Data Plane (OPTIONAL)

### Purpose
Direct, fast communication for bulk data transfers and low-latency responses. Progressive enhancement—add when needed.

### Setup Steps

**1. Install Tailscale (both devices):**
```bash
# Mac Mini (Watson)
brew install tailscale
sudo tailscaled
tailscale up

# VM (Ubuntu/Debian)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

**2. Verify connectivity:**
```bash
# On each device, get IP
tailscale ip -4

# Mac Mini: 100.x.x.1
# VM: 100.x.x.2

# Test connection
ping $(tailscale ip -4 | grep 100.)
```

**3. Configure Gateway HTTP API:**

Both OpenClaw gateways expose HTTP API on port 22222 by default:
- Watson: `http://100.x.x.1:22222`
- VM Agent: `http://100.x.x.2:22222`

**4. Enable cross-gateway sessions_send:**

Update each agent's config to include remote gateway endpoints:

```json
// ~/.openclaw/config.json
{
  "gateways": {
    "watson": {
      "url": "http://100.x.x.1:22222",
      "token": "..."
    },
    "vmagent": {
      "url": "http://100.x.x.2:22222",
      "token": "..."
    }
  }
}
```

### Message Flow (Tailscale)

**Watson sends direct message to VM Agent:**

```bash
# Watson's agent code
curl -X POST http://100.x.x.2:22222/api/sessions/send \
  -H "Authorization: Bearer $GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionKey": "agent:main:discord:channel:vm-session",
    "message": "TASK: Run tests. REPLY_TO: watson-session",
    "metadata": {
      "type": "TASK",
      "priority": "URGENT",
      "request_id": "task-001"
    }
  }'
```

### Advantages
✅ **Fast** - 10-50ms latency (vs 500-2000ms Discord)  
✅ **Private** - Traffic stays on Tailscale network  
✅ **No rate limits** - Can send rapidly  
✅ **Bulk transfers** - Can send large payloads  

### Limitations
⚠️ **Setup required** - Tailscale installation + config  
⚠️ **Network dependency** - Both devices must be online  
⚠️ **No persistence** - Messages not logged (unless you add it)  

### When to Use
- **Bulk data transfers** (>1MB)
- **Rapid back-and-forth** (>10 messages/min)
- **Low-latency requirements** (<100ms)
- **Private/sensitive data** (credentials, tokens)

---

## Layer 3: Git State Plane (MEMORY SHARING)

### Purpose
Persistent shared state and memory across agents. Enables agents to share context, learnings, and work history.

### Repository Structure

```
openclaw-shared-state/
├── README.md
├── agents/
│   ├── watson/
│   │   ├── status.json
│   │   ├── capabilities.json
│   │   └── memory/
│   │       └── 2026-02-11.md
│   └── vmagent/
│       ├── status.json
│       ├── capabilities.json
│       └── memory/
│           └── 2026-02-11.md
├── shared/
│   ├── tasks/
│   │   ├── pending/
│   │   ├── in-progress/
│   │   └── completed/
│   ├── knowledge/
│   │   └── shared-learnings.md
│   └── handoffs/
│       └── active-handoffs.json
└── sync/
    └── last-sync.json
```

### Setup Steps

**1. Create shared repository:**
```bash
# On a device with git access (Mac Mini or VM)
mkdir ~/openclaw-shared-state
cd ~/openclaw-shared-state
git init
git remote add origin git@github.com:jeremy/openclaw-shared-state.git

# Initial structure
mkdir -p agents/{watson,vmagent}/memory shared/{tasks/{pending,in-progress,completed},knowledge,handoffs} sync

# Create initial files
echo '{"status": "online", "last_update": "2026-02-11T13:16:00Z"}' > agents/watson/status.json
echo '{"status": "online", "last_update": "2026-02-11T13:16:00Z"}' > agents/vmagent/status.json

git add .
git commit -m "Initial shared state structure"
git push -u origin main
```

**2. Clone on both devices:**
```bash
# Watson (Mac Mini)
cd ~/.openclaw/workspace
git clone git@github.com:jeremy/openclaw-shared-state.git shared-state

# VM Agent
cd ~/.openclaw/workspace
git clone git@github.com:jeremy/openclaw-shared-state.git shared-state
```

**3. Configure auto-sync (both agents):**

Add to `HEARTBEAT.md`:

```markdown
## Shared State Sync

Every 5 minutes:
1. Pull latest from git repo: `cd shared-state && git pull`
2. Check `shared/handoffs/active-handoffs.json` for assigned tasks
3. Update own status: `agents/{my-name}/status.json`
4. Commit and push changes: `git add -A && git commit -m "Update status" && git push`
```

### Message Flow (State Sharing)

**Watson writes a task for VM Agent:**

```bash
# Watson creates task file
cat > shared-state/shared/tasks/pending/test-feature-ui.json <<EOF
{
  "id": "task-20260211-001",
  "created_by": "watson",
  "assigned_to": "vmagent",
  "title": "Test feature/new-ui branch",
  "description": "Run integration tests and report results",
  "priority": "NORMAL",
  "status": "PENDING",
  "created_at": "2026-02-11T13:16:00Z"
}
EOF

# Commit and push
cd shared-state
git add .
git commit -m "Watson: Add task for vmagent"
git push

# Notify via Discord (Layer 1)
# Post to #agent-comms: "@VMAgent [TASK] [NORMAL] New task in shared-state/shared/tasks/pending/test-feature-ui.json"
```

**VM Agent picks up task:**

```bash
# VM Agent pulls latest
cd shared-state
git pull

# Reads task
cat shared/tasks/pending/test-feature-ui.json

# Moves to in-progress
git mv shared/tasks/pending/test-feature-ui.json shared/tasks/in-progress/
git commit -m "VMAgent: Starting task test-feature-ui"
git push

# Executes work...

# Updates task with results
cat > shared/tasks/in-progress/test-feature-ui.json <<EOF
{
  ...
  "status": "COMPLETED",
  "result": "47 passed, 2 failed",
  "completed_at": "2026-02-11T13:25:00Z"
}
EOF

# Moves to completed
git mv shared/tasks/in-progress/test-feature-ui.json shared/tasks/completed/
git commit -m "VMAgent: Completed task test-feature-ui"
git push

# Notify via Discord
# Post to #agent-comms: "@Watson [RESPONSE] Task completed. Results in shared-state/shared/tasks/completed/test-feature-ui.json"
```

### Advantages
✅ **Persistent** - Full history in git  
✅ **Auditable** - Every change tracked  
✅ **Offline-capable** - Agents can commit locally, sync later  
✅ **Human-readable** - Jeremy can inspect state anytime  
✅ **Conflict resolution** - Git merge handles simultaneous edits  

### Limitations
⚠️ **Latency** - Pull/push cycle takes 2-10 seconds  
⚠️ **Not real-time** - Polling-based (every 5 min)  
⚠️ **Merge conflicts** - Can happen if both write same file  

### When to Use
- **Memory sharing** (learnings, context)
- **Task queues** (persistent work assignments)
- **Status updates** (capabilities, health)
- **Long-lived state** (projects, goals)

---

## Recommended Implementation Strategy

### Phase 1: Discord Only (Week 1) ✅ START HERE

**Goal:** Get basic cross-device communication working

**Setup:**
1. Create Discord channels: `#agent-comms`, `#agent-status`
2. Both agents join and monitor channels
3. Implement message parsing and routing
4. Test basic task handoff

**What you can do:**
- Send commands between agents
- Query status
- Hand off simple tasks
- Monitor health

**Timeline:** 1-2 hours setup, works immediately

---

### Phase 2: Add Git State (Week 2)

**Goal:** Add persistent memory and task tracking

**Setup:**
1. Create git repository with structure above
2. Clone on both devices
3. Add sync to heartbeat (every 5 min)
4. Implement task file reading/writing

**What you gain:**
- Shared memory between agents
- Persistent task queue
- Full audit trail
- Offline operation

**Timeline:** 2-4 hours setup

---

### Phase 3: Add Tailscale (Optional, When Needed)

**Goal:** Fast direct communication for special cases

**Setup:**
1. Install Tailscale on both devices
2. Configure gateway HTTP API endpoints
3. Implement direct HTTP calls for high-priority messages
4. Keep Discord as fallback

**What you gain:**
- 10x faster latency (50ms vs 500ms)
- No rate limits
- Private network communication

**Timeline:** 1 hour setup

---

## Latency & Reliability Analysis

| Layer | Latency (p50) | Latency (p99) | Reliability | Throughput |
|-------|---------------|---------------|-------------|------------|
| **Discord** | 500ms | 2000ms | 99.9% | ~50 msg/min |
| **Tailscale** | 20ms | 100ms | 99.5%* | Unlimited |
| **Git** | 5000ms | 15000ms | 99.9% | ~1 update/min |

\* Requires both devices online and connected to Tailscale

### Expected Roundtrip Times

**Simple Query (Discord only):**
1. Watson posts message → 500ms
2. VM Agent sees message → 500ms
3. VM Agent responds → 500ms
4. Watson sees response → 500ms
**Total: ~2 seconds**

**Simple Query (Tailscale):**
1. Watson sends HTTP request → 20ms
2. VM Agent processes → 10ms
3. VM Agent responds → 20ms
**Total: ~50ms**

**Task with Git State:**
1. Watson writes task file → 1ms
2. Watson commits + pushes → 3s
3. VM Agent pulls (next heartbeat) → 5s
4. VM Agent processes task → varies
5. VM Agent commits result → 3s
6. Watson pulls result → 5s
**Total: ~16s + processing time**

---

## Security Considerations

### Discord Layer
- ✅ Use **private channels** (only invited bots/users)
- ✅ **Message encryption** handled by Discord (TLS in transit)
- ⚠️ **Message retention** - Discord stores forever, logs visible to server admins
- ⚠️ **Rate limits** prevent spam but also limit throughput
- 🔒 **Recommendation:** Don't put credentials/secrets in Discord messages

### Tailscale Layer
- ✅ **End-to-end encrypted** via WireGuard
- ✅ **Zero-trust network** - only authenticated devices can connect
- ✅ **ACL controls** - can restrict which devices talk to which
- ⚠️ **Gateway tokens** must be protected (store in env vars, not code)
- 🔒 **Recommendation:** Use Tailscale for sensitive data transfers

### Git Layer
- ✅ **Authentication** via SSH keys or tokens
- ✅ **Full audit trail** - every change logged with author
- ⚠️ **Repository access** - anyone with git access can read history
- ⚠️ **Merge conflicts** - need resolution strategy
- 🔒 **Recommendation:** Use private repo, rotate credentials regularly

### General Best Practices

1. **Credential management:**
   - Store gateway tokens in 1Password
   - Use environment variables, never hardcode
   - Rotate tokens monthly

2. **Message validation:**
   - Verify sender identity (check session IDs)
   - Validate message format before processing
   - Rate-limit responses to prevent loops

3. **Audit logging:**
   - Log all inter-agent communications
   - Track task handoffs and results
   - Monitor for unusual patterns

4. **Fallback authentication:**
   - If unsure about message authenticity, confirm via Discord
   - Human (Jeremy) can intervene in #agent-comms

---

## Fallback Mechanisms

### When Discord is Down
- **Immediate:** Agents continue working independently
- **Fallback:** Try Tailscale direct connection (if configured)
- **Last resort:** Write to shared git state, pull every 5 min
- **Human escalation:** Notify Jeremy via other channels (iMessage)

### When Tailscale is Down
- **Immediate:** Fall back to Discord for all communication
- **Impact:** Slower responses, but still functional
- **Recovery:** Automatic when Tailscale reconnects

### When Git is Down
- **Immediate:** Continue using Discord for task coordination
- **Impact:** No persistent state, memory not shared
- **Workaround:** Agents can commit locally, push when git recovers

### When Both Agents are Down
- **Detection:** Heartbeat missing in #agent-status for >15 min
- **Action:** Jeremy receives alert (if monitoring configured)
- **Recovery:** Manual restart, agents re-sync state from git

### Split Brain Scenarios

**Problem:** Both agents work on same task simultaneously

**Prevention:**
1. Task files have "assigned_to" field
2. Agents only process tasks assigned to them
3. Moving task to "in-progress" is atomic (git commit)

**Detection:**
- Git merge conflict on same task file
- Both agents claim same REQUEST_ID

**Resolution:**
1. Detect conflict during git pull
2. Newer timestamp wins
3. Losing agent rolls back work, notifies via Discord

---

## Example: Complete Task Handoff Flow

**Scenario:** Watson asks VM Agent to run tests on a branch

### Step 1: Watson initiates (Discord)

```
@VMAgent [TASK] [NORMAL]
Body: Run integration tests on branch feature/new-ui and report results
---
FROM: agent:main:discord:channel:watson-session
TO: VMAgent
REPLY_TO: agent:main:discord:channel:watson-session
REQUEST_ID: task-20260211-1316-001
```

### Step 2: Watson creates task file (Git)

```bash
cd shared-state
cat > shared/tasks/pending/integration-tests-20260211.json <<EOF
{
  "id": "task-20260211-1316-001",
  "created_by": "watson",
  "assigned_to": "vmagent",
  "title": "Integration tests for feature/new-ui",
  "branch": "feature/new-ui",
  "priority": "NORMAL",
  "status": "PENDING",
  "created_at": "2026-02-11T13:16:00Z"
}
EOF
git add . && git commit -m "Add integration test task" && git push
```

### Step 3: VM Agent sees Discord message (immediately)

VM Agent's message handler picks up mention, parses REQUEST_ID

### Step 4: VM Agent acknowledges (Discord, <1s)

```
@Watson [RESPONSE] [NORMAL]
Body: Task accepted. Will start integration tests shortly.
Status: ACKNOWLEDGED
---
REQUEST_ID: task-20260211-1316-001
```

### Step 5: VM Agent pulls git state (next heartbeat, ~5s)

```bash
cd shared-state && git pull
# Sees new task file
cat shared/tasks/pending/integration-tests-20260211.json
```

### Step 6: VM Agent claims task (Git)

```bash
git mv shared/tasks/pending/integration-tests-20260211.json shared/tasks/in-progress/
# Update status field to IN_PROGRESS
git add . && git commit -m "Start integration tests" && git push
```

### Step 7: VM Agent executes task

```bash
git checkout feature/new-ui
npm run test:integration
# 47 passed, 2 failed
```

### Step 8: VM Agent updates task file (Git)

```json
{
  "id": "task-20260211-1316-001",
  ...
  "status": "COMPLETED",
  "result": {
    "passed": 47,
    "failed": 2,
    "log_url": "https://gist.github.com/..."
  },
  "completed_at": "2026-02-11T13:25:00Z"
}
```

```bash
git mv shared/tasks/in-progress/integration-tests-20260211.json shared/tasks/completed/
git add . && git commit -m "Complete integration tests" && git push
```

### Step 9: VM Agent reports back (Discord)

```
@Watson [RESPONSE] [NORMAL]
Body: Integration tests completed.
Results: 47 passed, 2 failed
Details: shared-state/shared/tasks/completed/integration-tests-20260211.json
Log: https://gist.github.com/...
---
REQUEST_ID: task-20260211-1316-001
Status: COMPLETED
```

### Step 10: Watson pulls git state (next heartbeat)

```bash
cd shared-state && git pull
cat shared/tasks/completed/integration-tests-20260211.json
# Watson now has full task history and results
```

**Total time:** ~10-20 seconds (depending on heartbeat timing)
**Messages sent:** 3 Discord messages (initiate, ack, complete)
**Persistent record:** Full task history in git

---

## Testing & Validation

### Unit Tests (per agent)

```bash
# Test message parsing
test_parse_discord_message()
test_extract_metadata()
test_validate_request_id()

# Test message sending
test_send_discord_message()
test_send_tailscale_http()

# Test git operations
test_create_task_file()
test_claim_task()
test_complete_task()
```

### Integration Tests (cross-device)

**Test 1: Basic ping-pong**
1. Watson sends: "@VMAgent [QUERY] What is your status?"
2. VM Agent responds within 5s: "@Watson [RESPONSE] Status: ONLINE"
3. ✅ Assert response received

**Test 2: Task handoff**
1. Watson creates task in git
2. Watson notifies via Discord
3. VM Agent claims task
4. VM Agent completes task
5. VM Agent updates git
6. Watson reads result
7. ✅ Assert result matches expected

**Test 3: Fallback (Discord down)**
1. Simulate Discord outage
2. Watson sends message via Tailscale
3. VM Agent responds via Tailscale
4. ✅ Assert communication continues

**Test 4: Fallback (Tailscale down)**
1. Disable Tailscale
2. Watson sends message via Discord
3. VM Agent responds via Discord
4. ✅ Assert communication continues

**Test 5: Conflict resolution**
1. Both agents modify same file simultaneously
2. Both commit locally
3. One pushes first (wins)
4. Other pulls, detects conflict
5. ✅ Assert conflict resolved correctly

### Monitoring

**Metrics to track:**
- Messages sent/received per minute (Discord, Tailscale)
- Task handoff time (start to completion)
- Git sync frequency and conflicts
- Agent uptime and heartbeat gaps
- Error rates and types

**Alerting:**
- Agent offline >15 minutes
- Task stuck in IN_PROGRESS >1 hour
- Git conflict not resolved >10 minutes
- Discord rate limit hit
- Tailscale connection lost

---

## FAQ

**Q: Why not just use WebSockets?**
A: Requires both devices to have public IPs or port forwarding. Discord + Tailscale gives us the benefits without the networking complexity.

**Q: Can agents communicate if one is offline?**
A: Yes, via git. The online agent can commit tasks/messages, and the offline agent will sync when it comes back online.

**Q: What if Discord goes down permanently?**
A: Tailscale becomes primary, git becomes fallback. Or migrate to Slack/Telegram (same message format works).

**Q: How do I add a third agent?**
A: Add to Discord channels, clone git repo, configure Tailscale. The protocol scales to N agents.

**Q: Can humans message agents this way?**
A: Yes! Jeremy can post to #agent-comms using the same format. Agents will respond.

**Q: How do I debug a failed message?**
A: Check Discord channel history, git log, and each agent's local logs. REQUEST_ID ties everything together.

---

## Appendix: Quick Start Checklist

### Watson (Mac Mini) Setup
- [ ] Join Discord server, channels: #agent-comms, #agent-status
- [ ] Configure agent to monitor Discord channels
- [ ] (Optional) Install Tailscale: `brew install tailscale && sudo tailscaled && tailscale up`
- [ ] Clone shared-state repo: `git clone git@github.com:jeremy/openclaw-shared-state.git`
- [ ] Add git sync to HEARTBEAT.md
- [ ] Test: Send message to #agent-comms

### VM Agent (Laptop) Setup
- [ ] Join Discord server, channels: #agent-comms, #agent-status
- [ ] Configure agent to monitor Discord channels
- [ ] (Optional) Install Tailscale: `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up`
- [ ] Clone shared-state repo: `git clone git@github.com:jeremy/openclaw-shared-state.git`
- [ ] Add git sync to HEARTBEAT.md
- [ ] Test: Reply to Watson's test message

### Validation
- [ ] Watson can mention VMAgent in Discord and get response
- [ ] VMAgent can mention Watson in Discord and get response
- [ ] Both agents' status.json files update in git
- [ ] Task handoff works end-to-end (Discord → Git → Complete)
- [ ] (Optional) Direct Tailscale HTTP call succeeds

---

## Conclusion

**Start simple:** Discord-only for first week. This gets you 80% of the functionality with 20% of the complexity.

**Add layers as needed:** Git for persistence, Tailscale for speed. Each layer enhances without breaking existing functionality.

**Philosophy:** ClawStarter-aligned. Easy setup, progressive enhancement, human-readable at every layer.

**Result:** Watson and VM Agent can coordinate work across devices, share memory, and hand off tasks—starting today.

---

**Next Steps:**
1. Create Discord channels
2. Test basic messaging
3. If it works, you're done. ✅
4. Add git when you need task persistence
5. Add Tailscale when you need speed

**Questions?** Post in #agent-comms. 😊
