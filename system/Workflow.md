AIOS WORKFLOW v2.0 — Adaptive Workflow
this is for worker agents 
Purpose

This document defines the complete lifecycle of every AI agent in AIOS.

The repository is the single source of truth.

Every agent follows the same workflow.

---

Phase 1 — Startup

Start
  │
  ▼
Connect Repository
  │
  ▼
Authenticate
  │
  ▼
Synchronize Repository
  │
  ▼
Read AIOS Documents
  │
  ▼
Register Online
  │
  ▼
Status = Idle

Actions:

- Clone or update repository.
- Configure Git identity.
- Read all AIOS rules.
- Register in "Agents/online/".
- Enter Idle state.

---

Phase 2 — Idle Supervision

When no task is assigned, enter the Adaptive Supervision Loop.

Stage 1 — Fast Discovery

Duration: First 5 minutes

Polling Interval: Every 1 minute

Purpose:

- Detect new assignments quickly.
- Read updated instructions.
- Detect Task Manager updates.

Workflow:

git fetch
      │
      ▼
Repository Updated?
      │
 ┌────┴────┐
 │         │
No        Yes
 │         │
Wait      Pull Latest
 │         │
 └────┬────┘
      ▼
Read Tasks
      │
      ▼
Task Assigned?

---

Stage 2 — Normal Monitoring

Duration: Next 10 minutes

Polling Interval: Every 2 minutes

Purpose:

- Reduce network traffic.
- Continue monitoring for new work.

Checks:

- Repository updates
- Pending tasks
- Assigned tasks
- Updated instructions

---

Stage 3 — Low Power

After 15 minutes of inactivity

Polling Interval: Every 5 minutes

Purpose:

- Minimize CPU wakeups.
- Reduce Git operations.
- Save VM resources.

---

Stage 4 — Deep Idle

After 60 minutes of inactivity

Polling Interval: Every 10 minutes

Purpose:

- Maintain availability with minimal resource usage.

---

Automatic Reset

Immediately return to Stage 1 whenever any of the following occurs:

- Repository updated.
- New task assigned.
- Instructions changed.
- Task Manager message detected.
- Agent requested by another workflow.

This restores fast polling until the system becomes idle again.

---

Phase 3 — Task Assignment

When work appears:

Pending
      │
      ▼
Assigned

The agent:

- Confirms ownership.
- Reads task details.
- Resolves dependencies.
- Begins execution.

---

Phase 4 — Working

Assigned
      │
      ▼
Working

During execution:

- Follow repository rules.
- Protect unrelated files.
- Keep commits focused.
- Track progress.

---

Phase 5 — Self Verification

Before reporting completion, verify:

- Objectives completed.
- Files generated.
- Repository consistent.
- No merge conflicts.
- No secrets exposed.
- No failed operations.

If verification fails:

Working
      │
      ▼
Fix
      │
      ▼
Verify Again

---

Phase 6 — Reporting

Generate a report containing:

- Agent Name
- Task ID
- Summary
- Files Modified
- Verification Results
- Timestamp

Store it in:

reports/

---

Phase 7 — Repository Update

git add

↓

git commit

↓

git push

Only commit task-related changes.

Never commit unrelated modifications.

---

Phase 8 — Task Completion

Working
      │
      ▼
Verification
      │
      ▼
Complete

Move verified tasks to:

task/Complete/

Return status to:

Idle

---

Continuous Adaptive Loop

Start

↓

Repository Sync

↓

Read Rules

↓

Register Online

↓

Idle

↓

Stage 1
(1 min × 5)

↓

Task Found?
│
├── Yes → Execute Task
│
└── No
      ↓

Stage 2
(2 min × 10)

↓

Task Found?
│
├── Yes → Execute Task
│
└── No
      ↓

Stage 3
(5 min)

↓

Task Found?
│
├── Yes → Reset to Stage 1
│
└── No
      ↓

Stage 4
(10 min)

↓

Task Found?
│
├── Yes → Reset to Stage 1
│
└── No
      ↓

Repeat Until Runtime Stops

---

Failure Recovery

If an operation fails:

1. Preserve current work.
2. Record the error.
3. Attempt safe recovery.
4. Retry if appropriate.
5. Report unresolved failures.
6. Return to the supervision loop when safe.

Never discard completed work.

---

Repository Rules

Always:

- Synchronize before working.
- Verify before committing.
- Respect task ownership.
- Submit reports.
- Keep the repository organized.

Never:

- Overwrite another agent's assigned work.
- Expose credentials or secrets.
- Delete unrelated files.
- Skip verification.
- Force-push without authorization.

---

Success State

The agent is considered healthy when it:

- Is registered online.
- Synchronizes successfully.
- Adapts its polling interval based on activity.
- Completes and verifies assigned tasks.
- Reports its work.
- Returns to the Idle state.
- Resets to fast polling whenever new activity is detected.
