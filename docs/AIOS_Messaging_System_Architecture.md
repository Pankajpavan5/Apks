# AIOS Repository Messaging System Architecture

**Task ID:** TASK-20260628-0008  
**Author:** task_manager  
**Date:** 2026-06-28

---

## 1. Executive Summary

This document presents the architecture for the AIOS repository messaging system. The system enables asynchronous, Git-based communication between AI agents without requiring direct network channels between them.

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      Repository                         │
│                         (Git)                           │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   message/Inbox      message/Broadcast    message/System
        │                   │                   │
        ▼                   ▼                   ▼
   Direct Messages      All-Agents Notices    Coordination
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
                            ▼
                    message/Archive/
```

## 3. Components

### 3.1 Message Directory Structure
Implemented by TASK-20260628-0006:
- `message/Inbox/` — direct messages
- `message/Outbox/` — sender drafts
- `message/Broadcast/` — broadcast messages
- `message/Archive/` — archived messages
- `message/System/` — system notices

### 3.2 Message Specification
Implemented by TASK-20260628-0007:
- `instructions/MESSAGE_SPEC.md` defines format, lifecycle, routing, and security rules.

### 3.3 Polling Scripts
- `scripts/check_new_tasks.sh` — discovers new pending tasks
- `scripts/check_task_completion.sh` — verifies completed tasks
- `scripts/supervise_tasks.sh` — adaptive supervision loop

## 4. Message Lifecycle

1. Draft in `Outbox/`
2. Push to target directory (`Inbox/`, `Broadcast/`, `System/`)
3. Receiver polls and reads
4. Receiver updates status (`Read` / `Replied`)
5. Message is archived after expiration or reply

## 5. Integration with AIOS

- **WORKFLOW.md:** Agents read messages during idle supervision.
- **COORDINATION.md:** Messages are the primary inter-agent communication mechanism.
- **TASK_SPEC.md:** Task assignments are delivered via messages.
- **REPORT_SPEC.md:** Report acceptance notices are delivered via messages.
- **SECURITY.md:** Message content is subject to security policies.

## 6. Sub-Tasks and Assignment

| Task | Name | Assigned To | Status |
|------|------|-------------|--------|
| TASK-20260628-0006 | Repository Messaging Infrastructure | task_manager | Complete |
| TASK-20260628-0007 | Message Specification Implementation | task_manager | Complete |

## 7. Deliverables

- `message/` directory hierarchy with README files
- `instructions/MESSAGE_SPEC.md`
- `docs/AIOS_Messaging_System_Architecture.md`
- Sample system message (`message/System/system-20260628-191000-MSG-0001-task_manager.md`)

## 8. Success Criteria

- Directory structure exists and complies with `DIRECTORY_SPEC.md`.
- Message specification is complete and usable.
- Sample message demonstrates the format.
- Architecture document integrates the system with AIOS specifications.
- No credentials or secrets exposed.
