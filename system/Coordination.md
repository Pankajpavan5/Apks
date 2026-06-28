COORDINATION.md

AIOS Coordination Specification v1.0

---

Purpose

This document defines how AI agents coordinate work within AIOS.

Every agent and the Task Manager must follow this specification to prevent duplicate work, maintain repository integrity, and maximize collaboration.

---

Core Principles

- Repository is the single source of truth.
- One active owner per task.
- Verify before modifying shared state.
- Synchronize before making decisions.
- Cooperation takes priority over speed.

---

Coordination Cycle

Every coordination cycle:

Repository Sync
      │
      ▼
Read Instructions
      │
      ▼
Read Agent Status
      │
      ▼
Read Tasks
      │
      ▼
Analyze Repository
      │
      ▼
Claim / Continue Task
      │
      ▼
Execute
      │
      ▼
Verify
      │
      ▼
Report
      │
      ▼
Commit
      │
      ▼
Return Idle

---

Repository Synchronization

Before any action:

1. Fetch latest repository.
2. Pull latest changes.
3. Resolve synchronization issues.
4. Read updated instruction documents.
5. Continue only when synchronized.

Never work on outdated repository state.

---

Agent Discovery

Agents determine available workers by reading:

Agents/online/

Every online agent must maintain a valid registration.

Agents must never assume another agent is online without checking repository state.

---

Task Discovery

Read task folders in order:

task/Pending/
task/Assigned/
task/Working/
task/Verification/
task/Blocked/
task/Complete/

Build a current view of repository work before accepting a task.

---

Task Ownership

Rules:

- One owner per active task.
- Ownership must be recorded before work begins.
- Ownership remains until completion, reassignment, or cancellation.
- Do not modify another agent's assigned task without authorization.

---

Task Claiming

Before claiming a task verify:

- Task exists.
- Task is unassigned.
- Dependencies are satisfied.
- Repository is synchronized.

If all checks pass:

- Assign yourself.
- Update task status.
- Begin work.

---

Duplicate Work Prevention

Before starting work:

- Check for existing ownership.
- Check reports.
- Check active tasks.
- Check verification queue.

If another agent is already working on the task:

Do not duplicate effort.

---

Conflict Resolution

If a conflict occurs:

1. Stop modifying shared files.
2. Synchronize repository.
3. Preserve your work.
4. Record the conflict.
5. Notify the Task Manager through repository artifacts.
6. Resume only after resolution.

---

Communication

Agents communicate only through repository artifacts:

- Tasks
- Reports
- Status files
- Coordination files
- Message files located in "/message/" for direct AI-to-AI or agent communication

The "/message/" function enables structured conversations between agents and AI systems while maintaining full traceability within the repository.

Do not rely on assumptions or stale local state.

---

Adaptive Coordination

If idle:

Follow the polling schedule defined in "WORKFLOW.md".

Immediately synchronize when:

- Repository changes.
- New task appears.
- Instructions change.
- Verification request appears.

---

Verification Coordination

Completed work enters:

task/Verification/

The Task Manager or designated verifier reviews:

- Task completion.
- Reports.
- Repository integrity.
- Verification results.

Only verified work moves to:

task/Complete/

---

Failure Recovery

If coordination fails:

- Preserve current work.
- Synchronize repository.
- Retry safe operations.
- Record failures.
- Return to Idle if no further action is possible.

Never conceal coordination failures.

---

Coordination Rules

Always:

- Synchronize first.
- Respect task ownership.
- Verify before completion.
- Submit reports.
- Keep repository consistent.
- Cooperate with other agents.

Never:

- Claim another agent's active task.
- Skip synchronization.
- Skip verification.
- Overwrite unrelated work.
- Expose confidential information.

---

Success Criteria

AIOS coordination is successful when:

- Repository is synchronized.
- Every active task has a single owner.
- No duplicate work exists.
- Reports accurately reflect completed work.
- Verification is completed before task closure.
- Repository integrity is maintained.
- Agents return to the Idle state ready for the next assignment.

This document governs collaboration between all AI agents and the Task Manager, ensuring safe, predictable, and efficient operation across the entire AIOS.
