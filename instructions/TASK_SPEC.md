TASK_SPEC.md

AIOS Task Specification v1.0

---

Purpose

This document defines the standard format, lifecycle, ownership, and processing rules for every task in AIOS.

Every AI agent and the Task Manager must follow this specification.

Task files are the single source of truth for work assignments.

---

Task File Location

task/
├── Pending/
├── Assigned/
├── Working/
├── Verification/
├── Complete/
├── Blocked/
└── Archived/

Tasks move only through these directories.

---

Task Lifecycle

Create
   │
   ▼
Pending
   │
   ▼
Assigned
   │
   ▼
Working
   │
   ▼
Verification
   │
   ▼
Complete

Alternative paths

Working
   │
   ▼
Blocked

Blocked
   │
   ▼
Working

Verification
   │
   ▼
Pending

Complete
   │
   ▼
Archived

---

Task File Format

Every task must contain:

Task ID:
Task Name:
Created By:
Created Time:

Priority:
Status:

Assigned Agent:

Category:

Description:

Objective:

Expected Output:

Dependencies:

Files To Modify:

Estimated Difficulty:

Estimated Duration:

Verification Required:

Completion Criteria:

Notes:

---

Task ID

Every task receives a unique ID.

Format

TASK-YYYYMMDD-0001

Example

TASK-20260628-0007

Never reuse IDs.

---

Priority Levels

Critical
High
Medium
Low

Task Manager should always schedule higher priorities first unless blocked by dependencies.

---

Status Values

Only these values are valid.

Pending
Assigned
Working
Verification
Complete
Blocked
Archived
Cancelled

---

Ownership

Each task has exactly one owner.

Example

Assigned Agent:
agent_004

Unassigned

Assigned Agent:
None

---

Dependencies

Example

Depends On

TASK-20260628-0002

TASK-20260628-0004

Dependent tasks must complete first.

---

Verification

Verification Required

Yes

or

No

Verification checks

- Objectives completed
- Files created
- Build passes (if applicable)
- No repository conflicts
- No secrets exposed

---

Completion Rules

A task may enter Complete only when:

- Objectives finished
- Verification passed
- Report submitted
- Repository synchronized

Otherwise

Return to

Verification

or

Pending

---

Blocked Tasks

A task becomes Blocked when

- Dependency missing
- Permission unavailable
- Merge conflict
- Repository problem
- External resource unavailable

Blocked tasks cannot be marked Complete.

---

Cancellation

Only Task Manager or repository owner may cancel tasks.

Cancelled tasks are never deleted.

---

Task Claiming

Before beginning work

Agent must verify

- Task still exists.
- Task is not already owned.
- Dependencies satisfied.

After claiming

Update

Status:
Assigned

Assigned Agent:
agent_xxx

---

Reporting

Every completed task requires a report.

Report location

reports/

Report must reference

Task ID

---

Task Rules

Always

- Synchronize repository first.
- Respect ownership.
- Keep task information accurate.
- Update status immediately after changes.
- Submit a report upon completion.

Never

- Claim another agent's task.
- Modify completed tasks without authorization.
- Skip verification.
- Delete task history.

---

Loop Prompt Task Engineering

All AI agents must use a loop-based prompt execution model when working on tasks.

This ensures iterative improvement, validation, and alignment with objectives.

Loop Structure

Each task execution must follow this cycle:

1. Understand Task
2. Plan Approach
3. Execute Step
4. Validate Output
5. Compare Against Objective
6. Adjust / Refine
7. Repeat Until Complete

Loop Rules

- Never assume completion after a single pass.
- Always re-evaluate output against Completion Criteria.
- If output does not meet Expected Output, continue looping.
- If blocked, transition task to Blocked status immediately.
- Maintain internal reasoning consistency across iterations.

Prompt Engineering Requirements

Each loop iteration must include:

- Task Objective restatement
- Current progress summary
- Next action decision
- Output generation
- Self-verification step

Termination Conditions

The loop may only stop when:

- Completion Criteria are fully satisfied
- Verification checks pass
- No unresolved dependencies remain

Failure Handling

If repeated iterations fail:

- Re-evaluate task interpretation
- Break task into smaller sub-steps
- Escalate via Notes section if necessary

---

Task Success Criteria

A task is considered complete only when:

- Completion criteria are satisfied.
- Verification succeeds.
- A report is submitted.
- Repository integrity is preserved.
- The Task Manager accepts the completed work.

Only then may the task be moved to:

task/Complete/
