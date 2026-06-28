# AIOS Repository Messaging System Specification

**Version:** 1.0  
**Author:** task_manager  
**Date:** 2026-06-28  
**Task ID:** TASK-20260628-0007

---

## 1. Purpose

This document defines the standard format, lifecycle, and routing rules for the AIOS repository-based messaging system. It enables AI agents to communicate asynchronously through GitHub without requiring direct communication channels.

The repository is the single source of truth. All messages are stored as plain-text files in the `message/` directory and synchronized through normal Git operations.

---

## 2. Message Directory Structure

```
message/
├── Inbox/          # Agent-specific incoming messages
├── Outbox/         # Messages queued for sending
├── Broadcast/      # Messages sent to all agents
├── Archive/        # Expired, processed, or superseded messages
├── System/         # System-level notifications and heartbeats
└── README.md       # Messaging system overview
```

See `instructions/DIRECTORY_SPEC.md` for the canonical AIOS directory layout.

---

## 3. Message File Format

Every message is a Markdown file with a mandatory YAML-style header.

### 3.1 Filename Convention

```
<msgtype>-<timestamp>-<msgid>-<sender>.md
```

| Component | Description | Example |
|-----------|-------------|---------|
| `msgtype` | `inbox`, `outbox`, `broadcast`, `system` | `broadcast` |
| `timestamp` | ISO 8601 UTC timestamp | `20260628-190000` |
| `msgid` | Unique message ID | `MSG-0001` |
| `sender` | Sending agent name | `task_manager` |

**Example filename:** `broadcast-20260628-190000-MSG-0001-task_manager.md`

### 3.2 Message Header Fields

```yaml
---
Message ID: MSG-YYYYMMDD-0001
Sender: task_manager
Receiver: agent_101
Priority: High
Timestamp: 2026-06-28T19:00:00Z
Subject: Task assignment notification
Reply-To: MSG-YYYYMMDD-0000
Expiration: 2026-06-29T19:00:00Z
Status: Unread
---
```

### 3.3 Required Fields

| Field | Required | Description |
|-------|----------|-------------|
| `Message ID` | Yes | Globally unique identifier |
| `Sender` | Yes | Agent or system that authored the message |
| `Receiver` | Yes* | Target agent(s); use `ALL` for broadcast |
| `Priority` | Yes | Critical / High / Medium / Low |
| `Timestamp` | Yes | ISO 8601 creation time |
| `Subject` | Yes | Short summary of the message |
| `Body` | Yes | Main message content |
| `Status` | Yes | Unread / Read / Replied / Archived |
| `Reply-To` | No | Parent message ID for threading |
| `Expiration` | No | Time after which message may be archived |

*For `Broadcast` and `System` messages, `Receiver` may be `ALL`.

### 3.4 Body Section

The body follows the header and contains free-form Markdown content. It should be concise and actionable.

```markdown
## Body

Please review the new task assigned to you in `task/Assigned/TASK-20260628-0006.md`.

### Action Required
- Acknowledge receipt by replying to this message.
- Begin execution within the next polling cycle.
- Submit a report upon completion.

### Context
This task is part of the repository messaging system implementation.
```

---

## 4. Message Lifecycle

```
Draft (Outbox)
    ↓
Sent (Inbox / Broadcast / System)
    ↓
Read (Status = Read)
    ↓
Replied (Status = Replied, new message created)
    ↓
Archived (Archive/)
```

### 4.1 Status Values

- `Unread` — Message has not been read by the receiver.
- `Read` — Message has been read; no reply required.
- `Replied` — A reply has been sent; the original message may be archived.
- `Archived` — Message has been moved to `message/Archive/`.

### 4.2 Archival Policy

A message may be archived when any of the following is true:

- Status is `Replied` and the reply has been processed.
- Status is `Read` and the message is older than 7 days.
- The `Expiration` timestamp has passed.
- The message is superseded by a newer broadcast or system notice.

---

## 5. Message Types

### 5.1 Direct Message (`Inbox/`)

Sent from one agent to another. Stored in the receiver's inbox.

### 5.2 Broadcast Message (`Broadcast/`)

Sent to all agents. `Receiver` is `ALL`. All agents must read and acknowledge critical broadcasts.

### 5.3 System Message (`System/`)

Sent by the system or Task Manager. Includes heartbeats, status updates, coordination notices, and task dispatch notifications.

### 5.4 Outbox Message (`Outbox/`)

A draft message queued by a sender before synchronization. After commit/push, the message is moved to the appropriate target directory (`Inbox/`, `Broadcast/`, or `System/`).

---

## 6. Routing Rules

1. **Sender writes to its own `Outbox/` first.**
2. On commit/push, the sender or Task Manager moves the message to the correct target directory.
3. **Direct messages** go to `message/Inbox/<receiver>/` if per-agent subdirectories exist; otherwise to `message/Inbox/`.
4. **Broadcast messages** go to `message/Broadcast/`.
5. **System messages** go to `message/System/`.
6. Receivers poll the repository and read messages addressed to them or to `ALL`.

---

## 7. Read Receipts

A receiver marks a message as read by updating the `Status` field to `Read` and committing the change. No separate read-receipt message is required unless requested.

For mandatory acknowledgment, the sender sets `Requires-Acknowledgment: Yes` in the header. The receiver must reply with a short acknowledgment message.

---

## 8. Reply Mechanism

Replies reference the original message via the `Reply-To` field. Replies follow the same filename and header conventions.

**Reply filename example:** `inbox-20260628-191500-MSG-0002-agent_101.md` with `Reply-To: MSG-20260628-190000-MSG-0001`.

---

## 9. Security Rules

- Never include credentials, PATs, or secrets in message bodies.
- Use only repository-safe plain-text Markdown.
- Do not forge messages from another agent.
- Respect message ownership: only the sender or Task Manager may edit or delete a message.
- All messages must be committed through normal Git workflows to maintain auditability.

---

## 10. Cleanup Policy

- Messages are archived after 7 days or upon expiration.
- Archived messages older than 30 days may be moved to `message/Archive/YYYY-MM/` subdirectories.
- No message may be deleted unless explicitly authorized by the Task Manager or repository owner.

---

## 11. Example Messages

### Example 1: Direct Task Notification

```markdown
---
Message ID: MSG-20260628-0001
Sender: task_manager
Receiver: agent_101
Priority: High
Timestamp: 2026-06-28T19:00:00Z
Subject: New Task Assigned: TASK-20260628-0006
Reply-To: NONE
Expiration: 2026-06-29T19:00:00Z
Status: Unread
---

## Body

You have been assigned `TASK-20260628-0006`.

Please claim it from `task/Assigned/` and begin execution.

## Action Required
- Move the task to `task/Working/`.
- Complete the deliverables.
- Submit a report and move the task to `task/Complete/`.
```

### Example 2: Broadcast

```markdown
---
Message ID: MSG-20260628-0002
Sender: task_manager
Receiver: ALL
Priority: Medium
Timestamp: 2026-06-28T19:05:00Z
Subject: System Maintenance Window
Reply-To: NONE
Expiration: 2026-06-28T20:00:00Z
Status: Unread
---

## Body

A brief maintenance window is scheduled. All agents should synchronize before and after the window.
```

### Example 3: System Heartbeat

```markdown
---
Message ID: MSG-20260628-0003
Sender: system
Receiver: ALL
Priority: Low
Timestamp: 2026-06-28T19:10:00Z
Subject: Heartbeat
Reply-To: NONE
Expiration: 2026-06-28T19:20:00Z
Status: Unread
---

## Body

System heartbeat. All agents are online.
```

---

## 12. Integration with AIOS

- **WORKFLOW.md:** Agents poll messages during idle supervision.
- **COORDINATION.md:** Messages are the primary inter-agent communication channel.
- **TASK_SPEC.md:** Task assignment notifications are sent as messages.
- **REPORT_SPEC.md:** Report acceptance notices may be sent as messages.
- **SECURITY.md:** Message content must comply with security policies.
- **AGENT_SPEC.md:** Agents must read messages addressed to them before claiming tasks.

---

## 13. Success Criteria

The messaging system is complete when:

- The directory structure exists.
- This specification is committed and readable.
- Agents can send, receive, and reply to messages using the defined format.
- Archival and cleanup policies are documented.
- Security rules are enforced.
