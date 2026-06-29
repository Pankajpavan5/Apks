# AIOS Collective Brain — AI_BRAIN.md

**Version:** 1.0  
**Synthesized by:** Claude (agent_102 / task_manager)  
**Date:** 2026-06-29  
**Scope:** Combine all agent memory files, extract patterns, and produce a unified operational brain for all AIOS agents.

---

## 1. Executive Summary

This document is the **collective memory and operational brain** for the AIOS multi-agent system running on `Pankajpavan5/Apks`. It synthesizes the experiences, problems, solutions, and commands recorded by agents `agent_101`, `agent_102`, `agent_103`, and `agent_107` into a single source of truth. It also introduces new automation instructions and efficiency improvements to make all agents work faster, safer, and more consistently.

---

## 2. Agent Identity and Roles

| Agent | Primary Role | Specialization |
|-------|--------------|----------------|
| **agent_101** | Autonomous Linux/GitHub Worker | Repository automation, security engineering, research loops, PDF generation |
| **agent_102** | Task Manager / Multi-Agent Coordinator | Task assignment, supervision, coordination, documentation, conflict resolution |
| **agent_103** | Governance & Standards Worker | Compliance, canonicalization, directory/spec review |
| **agent_107** | Autonomous Linux/GitHub Worker | AIOS specification adherence, idle monitoring, task execution |

All agents share the same repository, the same AIOS specifications, and the same security rules.

---

## 3. Combined Task History

### Infrastructure & Runtime
- Cloned and configured `Pankajpavan5/Apks` repository.
- Executed `vm_optimization.sh` (1 GB swap, 42 kernel parameters, all logging disabled, exit code 0).
- Built secure `scripts/Connect.sh` v2.0 with local git scope and runtime PAT injection.
- Created `scripts/check_new_tasks.sh`, `scripts/check_task_completion.sh`, `scripts/supervise_tasks.sh`.
- Initialized canonical directories: `scripts/`, `message/`, `logs/`, `Agents/profiles/`, `Agents/heartbeats/`, `Agents/offline/`, `task/Blocked/`, `task/Archived/`, `reports/Completed/`, `reports/Verification/`, etc.
- Implemented CI workflow in `.github/workflows/aios_ci.yml`.

### Documentation & Governance
- Authored `instructions/DIRECTORY_SPEC.md`.
- Authored `instructions/MESSAGE_SPEC.md` and created the repository messaging system.
- Created `templates/TASK_TEMPLATE.md` and `templates/REPORT_TEMPLATE.md`.
- Authored `docs/AIOS_Migration_Plan.md` and `docs/AIOS_Messaging_System_Architecture.md`.
- Completed AIOS repository audit (TASK-20260628-0001) and migration closeout (TASK-20260628-0002).

### Research & Content
- Created BSc Nursing exam notes (11 markdown files) and combined PDF (41 KB).
- Created AHN 1 detailed syllabus PDF (42 KB).
- Created 50-iteration APK optimization research report (39 KB).
- Created 50-pass next-gen AI/APK optimization research report (40 KB).
- Created encrypted PAT vault metadata and decryption guide.

### Memory System
- Created `memory/Name_memory.txt`, `agent_101_memory.txt`, `agent_103_memory.txt`, `agent_107_memory.txt`, and now `AI_BRAIN.md`.

---

## 4. Common Learnings Across All Agents

1. **Repository is the single source of truth.** All state, tasks, reports, and messages live in Git.
2. **Security policy overrides everything.** Plaintext PATs, passwords, or secrets must never be committed or logged.
3. **Git remote `origin` disappears across turns.** Always re-add/set-url `origin` with the PAT before any sync operation.
4. **Task IDs must be unique.** Duplicate IDs (e.g., TASK-20260628-0005) cause confusion and require renaming.
5. **AIOS specifications must match physical structure.** Agents follow examples in the repo more than written docs if the two conflict.
6. **Bidirectional 1-minute polling is essential.** `check_new_tasks.sh` and `check_task_completion.sh` keep the system synchronized.
7. **GitHub Push Protection blocks secret commits.** Any plaintext token in a commit will be rejected by the remote.
8. **User commands can be direct or repo-based.** The user may type commands in chat or push tasks into `task/Pending/`.
9. **Memory triggers:** `/memory` = update memory file; `/recall` = read memory and use context.
10. **Rule hierarchy:** Repository Owner > GOVERNANCE.md > SYSTEM.md > SECURITY.md > other specs.

---

## 5. Commands Library

### Git & Repository
```bash
# Configure and sync
git remote add origin "https://<PAT>@github.com/Pankajpavan5/Apks.git" || git remote set-url origin "https://<PAT>@github.com/Pankajpavan5/Apks.git"
git fetch origin
git pull --rebase origin main
git add -A
git commit -m "agent_xxx: concise message"
git push origin main

# Safety
git status --short
git log --oneline -5
git diff --stat
```

### Task Checking
```bash
bash scripts/check_new_tasks.sh 20     # poll for 20 minutes
bash scripts/check_task_completion.sh 1 # check completed tasks
bash scripts/supervise_tasks.sh         # adaptive supervision loop
```

### File Operations
```bash
mkdir -p <path>
find . -type f ! -path './.git/*' | sort
chmod +x scripts/*.sh
sed -i 's/old/new/g' file
```

### Python
```bash
pip install <package>
python3 script.py
```

---

## 6. Problems and Solutions

| Problem | Root Cause | Solution |
|---------|------------|----------|
| Git remote `origin` missing | `.git/config` excluded from snapshots | Re-add `origin` with PAT at start of every session |
| GitHub Push Protection rejects push | Plaintext PAT in commit | Redact or remove secrets before committing; use env vars |
| Duplicate task IDs | No ID uniqueness check before creating tasks | Search existing task IDs before assigning new ones |
| Conflicting `scripts/check_*.sh` versions | Local script created while remote official exists | Pull remote first; delete local duplicates; use official scripts |
| Untracked files lost during `git stash` | Default stash excludes untracked files | Use `git stash push --include-untracked` |
| Agent role boundary confusion | Single-agent environment with multiple agent registrations | Follow user instructions; document when taking over another agent's task |
| Legacy ad-hoc structure vs AIOS specs | Physical repo diverged from written specs | Canonicalize directories and use copy-pasteable templates |
| Credential exposure risk | User sometimes asks to include PAT in files | Refuse; explain security policy; use runtime-only injection |

---

## 7. Improvements and Recommendations

### 7.1 Automation Improvements
1. **Pre-commit secret scanner** — Add a GitHub Actions step to scan for `ghp_`, `sk-`, and other token patterns before allowing push.
2. **Auto-idempotent remote setup** — Wrap every script's first step in a function that ensures `origin` exists and is authenticated.
3. **Task ID validator** — Create `scripts/validate_task_id.sh` that checks for duplicate IDs before committing.
4. **Auto-report generator** — Create a script that generates `REPORT-<ID>-<Agent>.md` from a template once a task enters `task/Verification/`.
5. **Memory consolidation** — Run `AI_BRAIN.md` regeneration automatically whenever a memory file is updated.
6. **Heartbeat publisher** — Add a `scripts/publish_heartbeat.sh` that writes `Agents/heartbeats/agent_xxx.json` with timestamp and status.
7. **Message archival** — Add `scripts/archive_messages.sh` to move expired messages from `message/` to `message/Archive/YYYY-MM/`.
8. **CI status badge** — Add a README badge showing AIOS CI status.

### 7.2 Efficiency Improvements
1. **Single `sync_and_run` wrapper** — Combine `git fetch`, `git pull`, and task execution into one script to reduce copy-paste overhead.
2. **Task claiming helper** — Script that moves `task/Pending/X` → `task/Assigned/X`, sets `Assigned Agent:`, and writes a progress note.
3. **Batch commit message linter** — Enforce prefix conventions (`agent_xxx:`, `task_manager:`, `fix:`, `docs:`).
4. **Smart polling** — If no activity for 15 minutes, reduce poll frequency; reset to 1 minute on any repo change.
5. **Conflict auto-stash** — On `git pull --rebase` failure, auto-stash local changes, pull, then pop.

### 7.3 Governance Improvements
1. **Immutable task history** — Never delete task files; only move them through lifecycle directories.
2. **Mandatory verification queue** — No task moves directly from `Working` to `Complete`; it must pass through `Verification/`.
3. **Specification-first design** — Any new directory or file type must be documented in `instructions/DIRECTORY_SPEC.md` before creation.
4. **Secret rotation policy** — Document how and when to rotate the encrypted PAT vault key.

---

## 8. New Operational Instructions for All Agents

### 8.1 Startup Protocol (Every Session)
1. Re-add `origin` with runtime PAT injection.
2. `git fetch origin && git pull --rebase origin main`.
3. Read `Rule_no_1` if it exists.
4. Read `memory/AI_BRAIN.md` (this file) for collective context.
5. Register or update `Agents/online/agent_xxx.txt`.
6. Enter idle supervision loop.

### 8.2 Task Execution Protocol
1. Sync repository.
2. Read `task/Assigned/` and `task/Pending/`.
3. Claim only unassigned tasks; update `Assigned Agent:` and move to `Working/`.
4. Execute using loop engineering: Observe → Understand → Plan → Execute → Verify → Improve → Repeat.
5. Submit report per `REPORT_SPEC.md`.
6. Move task to `Verification/` (or `Complete/` if verification is not required).
7. Commit and push only task-related changes.

### 8.3 Secret Handling Protocol
1. The PAT is loaded into an environment variable or inline in commands only.
2. It is never echoed, printed, logged, or written to files.
3. If a file accidentally contains a secret, redact it and force-push the amended commit.
4. When sharing examples, use `[REDACTED]` or placeholder strings.

### 8.4 Memory Protocol
1. `/memory` — Append a new timestamped entry to your personal memory file and, if appropriate, update `AI_BRAIN.md`.
2. `/recall` — Read `memory/AI_BRAIN.md` and your personal memory file before executing the current task.
3. Keep memory files free of secrets and credentials.

### 8.5 Conflict Resolution Protocol
1. Stop modifying shared files.
2. Sync repository.
3. Stash local changes (`--include-untracked`).
4. Pull and rebase.
5. Pop stash and resolve conflicts manually.
6. If unresolved, move task to `task/Blocked/` and notify task_manager via `message/System/`.

---

## 9. Automation Scripts to Build Next

| Script | Purpose | Owner |
|--------|---------|-------|
| `scripts/ensure_origin.sh` | Idempotent remote setup with PAT from env | task_manager |
| `scripts/claim_task.sh <task-id>` | Move Pending → Assigned → Working with ownership | any worker |
| `scripts/validate_new_task.sh` | Check for duplicate IDs and schema compliance | agent_103 |
| `scripts/generate_report.sh <task-id>` | Generate report from `REPORT_TEMPLATE.md` | any worker |
| `scripts/publish_heartbeat.sh` | Write heartbeat to `Agents/heartbeats/` | any worker |
| `scripts/archive_messages.sh` | Archive expired messages | any worker |
| `scripts/sync_and_run.sh <command>` | Fetch, pull, run, commit, push safely | task_manager |
| `scripts/scan_secrets.sh` | Pre-commit scan for tokens and credentials | agent_101 / CI |
| `scripts/regenerate_brain.sh` | Rebuild `memory/AI_BRAIN.md` from all memory files | task_manager |

---

## 10. Key User Commands and Targets

| User Command | Action |
|--------------|--------|
| `/memory` | Update personal memory file and AI_BRAIN.md if needed |
| `/recall` | Read AI_BRAIN.md and personal memory before acting |
| `Start` | Check repo for tasks and execute assigned work |
| `Check for task` / `check_new_tasks.sh` | Poll `task/Pending/` and `task/Assigned/` |
| `Sync with repo and run ...` | Pull latest, then run the specified command |
| `Create folder ... upload to repo` | Create structure, commit, and push |
| `Assign task to agent_xxx` | Create task file and move to `task/Assigned/` |
| `Complete task` | Execute the task and move it to `task/Complete/` |

---

## 11. Security Policy (Non-Negotiable)

1. **No plaintext secrets in repo files.** Use encrypted vaults, env vars, or runtime injection only.
2. **No plaintext secrets in logs or chat output.** Always redact tokens.
3. **GitHub Push Protection is the final guard.** If a push is rejected due to a secret, immediately redact and amend.
4. **Least privilege.** Do not modify unrelated files or tasks assigned to other agents unless explicitly authorized or the environment forces it.
5. **Repository integrity.** Synchronize before and after every work cycle.

---

## 12. Future Enhancements

1. **Encrypted memory vault** — Store sensitive operational notes in an encrypted format separate from the repo.
2. **Agent capability registry** — Maintain `Agents/profiles/agent_xxx.md` with each agent's specialization and reliability score.
3. **Automated task assignment** — Use a simple round-robin or capability-matching algorithm in `task_manager` to assign tasks.
4. **Inter-agent message bus** — Use `message/` directories for real task coordination instead of chat-only commands.
5. **Self-healing CI** — CI workflow that detects and fixes common issues like missing remotes or broken permissions.
6. **AI_BRAIN.md auto-regeneration** — Hook that rebuilds this file whenever any `memory/*_memory.txt` changes.

---

## 13. Memory Update Log

- **2026-06-28T22:45:00Z** — Initial `memory/Name_memory.txt` created.
- **2026-06-28T22:50:00Z** — Structure formalized; PAT redacted due to Push Protection.
- **2026-06-28T22:51:00Z** — Name field set to `agent_102`.
- **2026-06-29** — `memory/AI_BRAIN.md` synthesized from all agent memory files.

---

*End of AI_BRAIN.md. This file should be read by every agent at startup (`/recall`) and updated when collective knowledge changes significantly (`/memory`).*

---

## 9. Collective Memory & Recent Operational Syntheses

### 9.1 Multi-Agent Cross-Disciplinary Integration (June 2026)
- **agent_101 (Automation & Next-Gen AI):** Established 4KB/16KB page-aligned zero-copy `mmap()` TFLite models (`libipm.so`), completely eliminating Dalvik heap allocation overhead and garbage collection stutters. Pioneered secure PAT vaults and canonical CLI checking commands (`check_new_tasks.sh`, `check_task_completion.sh`).
- **agent_102 (Task Manager / Coordinator):** Structured the initial AIOS Collective Brain (`AI_BRAIN.md`), establishing clear multi-agent role boundaries, task unique ID validations, and conflict auto-stash protocols.
- **agent_103 (Governance & Compliance):** Enforced strict secret sanitization policies (`SECURITY.md`), constructed copy-pasteable task/report templates (`TASK_TEMPLATE.md`, `REPORT_TEMPLATE.md`), and canonicalized repository directory partitions.
- **agent_107 (Reverse Engineering Specialist):** Performed comprehensive concrete binary analysis on `com.samsung.android.game.gos_3.6.03.18.apk` (`TASK-20260629-0011`). Extracted 16-bit LE string pools from binary `AndroidManifest.xml` proving system UID privileges (`android.uid.system`). Verified raw SurfaceFlinger Binder transactions (`GfiSurfaceFlingerHelper`) for Game Frame Interpolation (GFI) and Dynamic Frame Scaling (DFS). Dumped `categoryInfo.db` SQLite tables proving explicit non-game app throttling. Developed and patched `scripts/poll_discussion.py` to interact live on GitHub Discussions while resolving positive feedback echo loops.

### 9.2 Critical System RCA: GitHub Discussion Echo Storms
- **Problem Encountered:** Simultaneous polling of GitHub Discussion #2 by `poll_discussion.py` (`agent_107`) and background bots (`agent_101 / AIOS Communication Bus`) operating under the same shared user account (`Pankajpavan5`) created a recursive comment ping-pong echo storm. This rapid surge of GraphQL mutations triggered GitHub API secondary rate limits (Abuse Protection), returning error blocks and causing Python script failures (`TypeError: 'NoneType' object is not subscriptable`).
- **Validated Solution:** Fully patched `scripts/poll_discussion.py` with explicit Author Filtering (`if author == my_bot_login: continue`) to guarantee Identity Isolation. Added reply text deduplication caching, mandatory 10-second cooldown throttling between posts, and graceful GraphQL error checking (`if "errors" in res:`).

```text
Time and date  :memory:
2026-06-29T10:37:22Z
```

---

## 10. Master Instruction Contract: `/learn`

To ensure continuous autonomous evolution, eliminate recurring system failures, and align perfectly with the Repository Owner's strategic vision, all AIOS agents are permanently bound to the following operational directive:

### Trigger Command: `/learn`

Whenever the Repository Owner types `/learn` in chat or dispatches it via a repository task, the active agent must immediately perform the following 6-step autonomous introspective loop:

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│                    THE /learn INTROSPECTIVE EVOLUTION LOOP                    │
└───────────────────────────────────────────────────────────────────────────────┘
  ┌─────────────────────────┐
  │ 1. Analyze Past Tasks   │ (Review all recent interactions and commits)
  └───────────┬─────────────┘
              ▼
  ┌─────────────────────────┐
  │ 2. Find User Motive     │ (Identify the underlying strategic objective)
  └───────────┬─────────────┘
              ▼
  ┌─────────────────────────┐
  │ 3. Map Active Workflow  │ (Trace the exact operational execution path)
  └───────────┬─────────────┘
              ▼
  ┌─────────────────────────┐
  │ 4. Identify Mistakes    │ (Examine failures, echo storms, token risks)
  └───────────┬─────────────┘
              ▼
  ┌─────────────────────────┐
  │ 5. Generate Protection  │ (Formulate hard rules so mistakes never repeat)
  └───────────┬─────────────┘
              ▼
  ┌─────────────────────────┐
  │ 6. Store via /memory    │ (Update personal memory & AI_BRAIN.md)
  └─────────────────────────┘
```

#### 1. Analyze Previous Tasks (`anylasis previous`)
- Conduct an immediate audit of recent conversation turns, task files (`task/Complete/`), and commit logs to establish full situational awareness.

#### 2. Find User Task Motive (`Find user task motive`)
- Look beyond the literal syntax of the commands to deduce the Repository Owner's true strategic goals (e.g., verifying secret sanitization compliance, testing multi-agent communication buses, proving APK hardware intervention mechanisms).

#### 3. Trace Our Operational Workflow (`Find our workflow`)
- Map the step-by-step execution path taken by the agent (e.g., RAM token injection → Git Rebase → Script Execution → Verification → Reporting → Post-Task Polling).

#### 4. Identify Mistakes Made (`Find we made mistake`)
- Conduct rigorous self-examination to locate operational errors, including:
  - Echo storms or positive feedback loops in automated polling scripts.
  - Potential plaintext token exposure or failure to redact `GITHUB_PAT`.
  - Disappearance of Git remotes across turns due to `.git/config` snapshot exclusions.
  - Template formatting discrepancies or duplicate task IDs.

#### 5. Institutionalize Preventative Notes (`Get note that mistake not happen again`)
- Author explicit, deterministic operating rules and code safeguards to guarantee that the identified mistake can never occur again in future execution loops.

#### 6. Self-Improvement & Storage (`self-improvement by reading memory of own learn by mistake and store using /memory`)
- Read your personal memory ledger (`memory/agent_xxx_memory.txt`) to contextualize new errors against historical learnings.
- Formally append the complete introspective analysis and newly established rules into your personal memory file and `memory/AI_BRAIN.md` using the standard `/memory` protocol.
- Synchronize, commit, and push the reinforced memory structures to `origin/main`.
