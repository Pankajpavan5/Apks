# AIOS Agent Bot - Quick Start Guide

**Multi-Agent AI Arena with GitHub Coordination**

---

## Overview

This bot system enables multiple Claude AI agents to:
- **Poll for tasks** automatically from GitHub
- **Execute work** using slash-commands (`/loop`, `/analyst`, `/optimizer`, `/debug`, etc.)
- **Return to waiting** state and repeat indefinitely
- **Coordinate** without conflicts using GitHub as shared memory
- **Learn collectively** through AI_BRAIN.md and problem&solution.md

---

## Prerequisites

1. **Clone the AIOS repository**
   ```bash
   git clone https://github.com/Pankajpavan5/Apks.git
   cd Apks
   ```

2. **Set GitHub token**
   ```bash
   export GITHUB_TOKEN='ghp_your_personal_access_token_here'
   ```
   
   To create a token:
   - Go to GitHub Settings → Developer Settings → Personal Access Tokens
   - Create token with `repo` scope
   - Never commit the token!

3. **Install Python 3.8+**
   ```bash
   python3 --version  # Should be 3.8 or higher
   ```

4. **Make scripts executable**
   ```bash
   chmod +x agent_bot.py start_agent.sh orchestrator.sh
   ```

---

## Quick Start: Single Agent

### 1. Run Agent 101 (Analyst) for One Cycle

```bash
./start_agent.sh --agent-id 101 --role analyst --once
```

**What happens:**
1. ✅ Agent initializes and registers online
2. 📡 Syncs repository
3. 📋 Looks for tasks in `task/Pending/`
4. 🔐 Claims an unclaimed task (if available)
5. 🚀 Executes task with `/analyst` command
6. 📄 Generates report in `reports/Completed/`
7. 💾 Commits to GitHub
8. 👋 Exits

### 2. Run Agent 201 (Optimizer) in Continuous Loop

```bash
./start_agent.sh --agent-id 201 --role optimizer --loop
```

**What happens:**
- Agent starts
- Every 60 seconds:
  - Checks `task/Pending/` for new tasks
  - Claims first available task
  - Executes with appropriate command
  - Generates report
  - Returns to idle (60 second wait)
  - Repeats forever (until Ctrl+C)

**Output example:**
```
✅ Agent initialized and ready

📍 Poll cycle at 2026-07-02T12:00:00Z
📡 Syncing repository...
✅ Repository synced
📋 Found 2 pending task(s)
✅ Claimed task: TASK-20260702-0001
📝 Working on TASK-20260702-0001
🚀 Executing task: Research APK Optimization
   Command: /analyst
   Role: optimizer
✅ Task completed: TASK-20260702-0001
📄 Report: REPORT-TASK-20260702-0001-agent_201.md
✅ Committed: agent_201: Complete TASK-20260702-0001
✅ Pushed to GitHub

💤 Waiting 60s until next poll...
```

---

## Quick Start: Multiple Agents (Orchestrated)

### 1. Deploy 4-Agent Fleet

```bash
# Make orchestrator executable
chmod +x orchestrator.sh

# Deploy agents as systemd services (requires sudo)
sudo ./orchestrator.sh deploy --agents 101,102,103,107

# Start all
sudo ./orchestrator.sh start all
```

### 2. Check Fleet Status

```bash
./orchestrator.sh status
```

**Output:**
```
Agent ID         Status       Role            Last Task
--------         ------       ----            ---------
agent_101        🟢 running   analyst         TASK-20260702-0015
agent_102        🟢 running   coordinator     TASK-20260702-0012
agent_103        🟢 running   debugger        TASK-20260702-0014
agent_107        🟢 running   poller          TASK-20260702-0018

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 4 agents | Running: 4 | Stopped: 0
```

### 3. View Logs

```bash
# Follow all agent logs in real-time
./orchestrator.sh logs all --follow

# Or tail a specific agent (last 50 lines)
./orchestrator.sh logs 101 --tail=50
```

### 4. Stop All Agents

```bash
./orchestrator.sh stop all
```

---

## Task File Format

Create tasks in `task/Pending/TASK-yyyymmdd-nnnn.md`:

```markdown
# Task: Research APK Optimization Strategies

/analyst apk-compression-research
  Duration: 2 hours
  Deliverable: 3000+ word research report
  Focus: Size reduction, compression techniques, resource optimization

## Background
Current APK size is 89MB. Target is 45MB (50% reduction).

## Requirements
1. Analyze compression approaches
2. Identify top 10 size consumers
3. Propose 3 optimization strategies
4. Estimate time/complexity for each

---

Assigned: unassigned
Created: 2026-07-02T10:00:00Z
```

When an agent claims this task:
1. Metadata updated: `Assigned: agent_101`
2. File moved to `task/Assigned/`
3. Agent executes `/analyst` command
4. Report generated in `reports/Completed/`
5. Task moved to `task/Verification/` (awaits QA)

---

## Available Commands (Slash-Commands)

Add one of these to your task file to route to appropriate handler:

| Command | Agent | Purpose | Duration |
|---------|-------|---------|----------|
| `/loop` | Poller | Continuous polling mode | ∞ (until stopped) |
| `/analyst TOPIC` | analyst (101, 202) | Deep research & synthesis | 1-3 hours |
| `/optimizer TASK` | optimizer (201) | Iterative code/algorithm optimization | 1-2 hours |
| `/debug ERROR` | debugger (103) | Root cause analysis | 30 min - 1 hour |
| `/deepdive TOPIC` | analyst | Exploratory pattern extraction | 1-2 hours |
| `/compare A vs B` | Any | Side-by-side evaluation | 30 min |
| `/proscons DECISION` | Any | Pro/con weighted analysis | 30 min |
| `/optimizecode FUNC` | optimizer | Algorithmic optimization | 1 hour |

---

## Memory System

### AI_BRAIN.md (Collective Knowledge)
- Location: `memory/AI_BRAIN.md`
- Contents: Unified knowledge from all agents
- Auto-updated with learnings after each task
- Read by all agents at startup

**Example entry:**
```markdown
## Pattern: Gradle Low-Memory OOM
- Category: android-build
- Root Cause: Heap too high, no swap, too many workers
- Prevention: Use Xmx1024m, SerialGC, daemon=false, workers=1
- Last Failure: 2026-06-29 by agent_101
- Status: LEARNED ✓
```

### agent_NNN_memory.txt (Individual Context)
- Location: `memory/agent_101_memory.txt`, etc.
- Contents: Agent-specific learnings and experiences
- Auto-updated after each task
- Injected into agent's system prompt

### problem&solution.md (Failure Database)
- Location: `memory/problem&solution.md`
- Contents: All known problems, root causes, solutions
- Auto-populated when errors occur
- Updated when solutions found

---

## Monitoring & Troubleshooting

### Check Agent Health

```bash
./orchestrator.sh health
```

Output:
```
agent_101: healthy (active)
agent_102: healthy (active)
agent_103: potentially stuck (check logs)  ⚠️
agent_107: healthy (active)
```

### View Agent Logs

```bash
# Real-time tail
./orchestrator.sh logs 103 --follow

# Last 100 lines
./orchestrator.sh logs 103 --tail=100

# All agents (useful for debugging interactions)
./orchestrator.sh logs all --follow
```

### Debug Repository State

```bash
# Check online agents
ls -la Agents/online/

# Check pending tasks
ls -la task/Pending/

# Check in-progress
ls -la task/Working/

# Check completed
ls -la task/Complete/

# View recent commits
git log --oneline -20
```

### Manual Git Sync

```bash
cd Apks
git fetch origin
git pull --rebase origin main
git status
```

---

## Common Patterns

### Create & Execute Task (Analyst)

```bash
# 1. Create task file
cat > task/Pending/TASK-$(date +%Y%m%d)-0001.md << 'EOF'
# Task: APK Optimization Research

/analyst apk-optimization-deep-dive
  Focus: Size reduction, compression, obfuscation
  Duration: 2 hours
  Deliverable: Detailed research report

---
Assigned: unassigned
Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# 2. Commit
git add task/Pending/
git commit -m "task: Create APK optimization research task"
git push origin main

# 3. Agent polls and picks it up automatically
./start_agent.sh --agent-id 101 --once

# 4. Check result
ls reports/Completed/REPORT-*
cat reports/Completed/REPORT-*.md
```

### Run Multi-Agent Scenario

```bash
# Terminal 1: Agent 101 (Analyst)
./start_agent.sh --agent-id 101 --role analyst --loop

# Terminal 2: Agent 201 (Optimizer)
./start_agent.sh --agent-id 201 --role optimizer --loop

# Terminal 3: Create tasks
for i in {1..5}; do
  cat > task/Pending/TASK-$(date +%Y%m%d)-$i.md << 'EOF'
# Task $i
/analyst research-topic-$i
---
Assigned: unassigned
EOF
  git add task/Pending/
  git commit -m "task: Create task $i"
  git push origin main
  sleep 5
done
```

---

## Environment Variables

```bash
# Required
export GITHUB_TOKEN='ghp_xxxx...'

# Optional
export AGENT_REPO='./Apks'           # Repository path
export AIOS_LOG_DIR='.logs'           # Log directory
export AIOS_DEBUG='0'                 # Debug mode (0=off, 1=on)
```

---

## Systemd Deployment (Advanced)

### Install as System Service

```bash
# 1. Copy service template
sudo cp aios-agent.service.template /etc/systemd/system/aios-agent@.service

# 2. Edit and set paths
sudo nano /etc/systemd/system/aios-agent@.service
# Update: /path/to/Apks, /path/to/start_agent.sh, token

# 3. Reload
sudo systemctl daemon-reload

# 4. Enable & start agents
sudo systemctl enable aios-agent@{101,102,103,107,201,202}
sudo systemctl start aios-agent@{101,102,103,107,201,202}

# 5. Monitor
systemctl status aios-agent@101
journalctl -u aios-agent@101 -f
```

---

## Troubleshooting

### "GITHUB_TOKEN not set"

```bash
export GITHUB_TOKEN='ghp_your_token_here'
```

### "Repository not found"

```bash
# Check path
ls -la Apks/.git

# Or specify explicitly
./start_agent.sh --agent-id 101 --repo /full/path/to/Apks --once
```

### "Remote origin missing"

```bash
cd Apks
git remote add origin https://github.com/Pankajpavan5/Apks.git
# Or update if exists:
git remote set-url origin https://$(GITHUB_TOKEN)@github.com/Pankajpavan5/Apks.git
```

### Agent stuck on task

```bash
# Check logs
./orchestrator.sh logs <agent_id> --follow

# Move task to Blocked
mv task/Working/TASK-xxx.md task/Blocked/

# Restart agent
./orchestrator.sh restart <agent_id>
```

### Memory updates not syncing

```bash
# Manual sync
cd Apks
git pull --rebase origin main
git add memory/
git commit -m "memory: Update AI_BRAIN.md"
git push origin main
```

---

## Next Steps

1. **Create test tasks** → Add `.md` files to `task/Pending/`
2. **Run agents** → Use `start_agent.sh` or orchestrator
3. **Monitor execution** → Check logs, reports, and memory
4. **Scale fleet** → Deploy more agent instances with different roles
5. **Optimize learnings** → Review problem&solution.md, update AI_BRAIN.md

---

## Key Files

| File | Purpose |
|------|---------|
| `agent_bot.py` | Core agent orchestrator (Python) |
| `start_agent.sh` | Bash wrapper with environment setup |
| `orchestrator.sh` | Fleet management (status, logs, scaling) |
| `aios-agent.service.template` | Systemd service template |
| `memory/AI_BRAIN.md` | Collective knowledge base |
| `memory/problem&solution.md` | Failure patterns and solutions |
| `memory/agent_*_memory.txt` | Individual agent context |

---

## Support

- **GitHub Issues**: Report bugs or request features
- **Repository**: https://github.com/Pankajpavan5/Apks
- **Documentation**: See `/instructions/` directory
- **Logs**: Check `.logs/` directory or `journalctl` for systemd

---

## Summary: The Loop

```
Agent Startup
    ↓
Register Online (Agents/online/)
    ↓
Infinite Loop:
    ├─ Sync Repository (git fetch, pull)
    ├─ Check Inbox for Messages
    ├─ Discover Pending Tasks
    ├─ Claim First Available Task
    ├─ Execute Task (based on /command)
    ├─ Generate Report
    ├─ Update Memory (AI_BRAIN.md, agent_memory.txt)
    ├─ Commit & Push
    ├─ Move to Verification or Complete
    ├─ Wait (poll_interval seconds)
    └─ Repeat
    ↓
(Ctrl+C or Stop Signal)
    ↓
Unregister from Online
    ↓
Exit
```

This cycle repeats indefinitely, allowing agents to autonomously execute work while remaining coordinated through GitHub.

---

**Ready to run? Start with:**

```bash
export GITHUB_TOKEN='ghp_your_token'
./start_agent.sh --agent-id 101 --loop
```

Then watch tasks flow through `task/Pending/` → `task/Assigned/` → `task/Working/` → `task/Verification/` → `task/Complete/`! 🚀
