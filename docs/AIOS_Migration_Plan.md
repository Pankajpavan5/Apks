# AIOS Master Migration Plan & Implementation Roadmap
**Task ID:** `TASK-20260628-0002`  
**Author:** `task_manager`  
**Project:** AIOS Repository Standards Alignment Implementation  

---

## Executive Summary
This document establishes the authoritative migration plan to remediate the structural, runtime, and documentation discrepancies identified during the full repository audit (`TASK-20260628-0001`). 

The migration decomposes repository alignment into two concurrent worker streams supervised by the Task Manager:
1. **Stream A (Runtime & Bootstrap Engineering):** Assigned to `agent_101` (`TASK-20260628-0003`). Focuses on refactoring `Connect.sh`, creating portable waiting scripts, securing authentication credentials, and initializing core infrastructure buses (`/scripts/`, `/message/`, `/logs/`).
2. **Stream B (Governance & Standards Compliance):** Assigned to `agent_103` (`TASK-20260628-0004`). Focuses on standardizing task/report templates, authoring missing baseline specifications (`DIRECTORY_SPEC.md`), auditing filesystem compliance, and preparing safe migration proposals.

---

## 1. Recommendations Categorization & Disposition Matrix

### Approved Recommendations (Immediate Implementation)
* **REC-101 (Security):** Refactor `Connect.sh` to eliminate hardcoded paths (`/home/user/Apks`), replace global git config changes with local container scopes, and enforce runtime-only PAT memory injection. *Owner:* `agent_101`.
* **REC-102 (Governance):** Establish canonical `/instructions/` root structure and migrate normative governance documents out of `./system/` and `./instruction/`. *Owner:* `agent_103`.
* **REC-103 (Governance):** Standardize documentation filenames to canonical UPPERCASE casing (`AGENT_SPEC.md`, `GOVERNANCE.md`, `SECURITY.md`, `WORKFLOW.md`, `COORDINATION.md`). *Owner:* `agent_103`.
* **REC-104 (Governance):** Author canonical `DIRECTORY_SPEC.md` and `SYSTEM.md` specification documents. *Owner:* `agent_103`.
* **REC-201 (Infrastructure):** Initialize missing canonical root directories: `/scripts/`, `/message/`, `/logs/`. *Owner:* `agent_101`.
* **REC-202 (Infrastructure):** Initialize missing Agent hierarchy partitions: `Agents/profiles/`, `Agents/heartbeats/`, `Agents/offline/`. *Owner:* `agent_103`.
* **REC-203 (Infrastructure):** Initialize missing Task lifecycle partitions: `task/Blocked/`, `task/Archived/`. *Owner:* `task_manager` (Completed).
* **REC-204 (Infrastructure):** Migrate root scripts (`vm_optimization (1).sh`, `Connect.sh`) into `/scripts/` with backward-compatible forwarding stubs. *Owner:* `agent_101`.
* **REC-301 (Task Schema):** Standardize all future task files to strict key-value schemas (`TASK-YYYYMMDD-XXXX.md`). *Owner:* `agent_103`.
* **REC-303 (Polling Harmonization):** Standardize Stage 4 deep idle polling intervals across `WORKFLOW.md` and `AGENT_SPEC.md` to deterministic 5-minute checks. *Owner:* `agent_101`.

### Deferred Recommendations (Post-Migration Sprints)
* **REC-302 (Reporting Re-indexing):** Re-indexing historical completed reports (`agent_101_ahn1...md`) is deferred to a future housekeeping sprint to prevent breaking existing benchmark test references.
* **REC-401 (Housekeeping Root Partition):** Moving root academic study folders (`ahn1/`, `bsc/`, `research/`) is deferred to preserve immutable historical artifact hyperlinks.

### Rejected Recommendations
* *None.* All audit proposals were deemed empirically valid and constructive.

---

## 2. Implementation Roadmap & Execution Order

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  STAGE 1: PROJECT INITIALIZATION & DISPATCH (Task Manager)                  │
│  · Author Migration Plan; claim TASK-0002; dispatch TASK-0003 & TASK-0004   │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ (Concurrent Dispatch)
               ┌────────────────────────┴────────────────────────┐
               ▼                                                 ▼
┌──────────────────────────────────────────────┐ ┌──────────────────────────────────────────────┐
│  STREAM A: RUNTIME (agent_101 - TASK-0003)   │ │  STREAM B: GOVERNANCE (agent_103 - TASK-0004)│
│  · Initialize /scripts, /message, /logs      │ │  · Author DIRECTORY_SPEC.md                  │
│  · Refactor scripts/Connect.sh auth harness  │ │  · Create /templates/TASK & REPORT schemas   │
│  · Author scripts/supervise_tasks.sh poller  │ │  · Compile Legacy Inventory & Compliance Rept│
│  · Submit Runtime & Test Reports             │ │  · Initialize Agents/{profiles,heartbeats}   │
└───────────────────────────────────────┬──────┘ └──────────────────────┬───────────────────────┘
                                        │                               │
                                        └───────────────┬───────────────┘
                                                        │ (Bidirectional Polling Sync)
                                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  STAGE 2: SUPERVISION, VERIFICATION & CLOSEOUT (Task Manager)                │
│  · Pull worker deliverables; verify code/template schemas; confirm security  │
│  · Accept worker reports; move tasks to Complete/; submit Master Close Report│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Required Agents & Resource Allocation
* **`task_manager` (Self):** Overall orchestration, conflict prevention, deliverable sign-off, progress reporting.
* **`agent_101` (Runtime Specialist):** Shell scripting, Git networking, container least-privilege auth engineering.
* **`agent_103` (Compliance Specialist):** Specification gap analysis, markdown templating, legacy compatibility mapping.

---

## 4. Success Criteria
* 100% of approved recommendations implemented or prototyped via forwarding stubs.
* Zero plaintext Personal Access Tokens exposed in Git traces or stderr logs.
* All task and report artifacts transitioned cleanly through `task/Verification/` to `task/Complete/`.
