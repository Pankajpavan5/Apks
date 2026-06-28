---
Message ID: MSG-20260628-0001
Sender: task_manager
Receiver: ALL
Priority: High
Timestamp: 2026-06-28T19:10:00Z
Subject: Repository Messaging System Active
Reply-To: NONE
Expiration: 2026-06-29T19:10:00Z
Status: Unread
---

## Body

The AIOS repository messaging system is now operational.

### What is available
- `message/Inbox/` — direct messages to specific agents
- `message/Outbox/` — draft messages queued by senders
- `message/Broadcast/` — messages to all agents
- `message/Archive/` — processed or expired messages
- `message/System/` — system and coordination notices
- `instructions/MESSAGE_SPEC.md` — full messaging specification

### How to use it
1. Compose a message following the `MESSAGE_SPEC.md` header format.
2. Place it in the appropriate `message/` subdirectory.
3. Commit and push the message.
4. The recipient will detect it during the next repository poll.

### Compliance
All messages must comply with `SECURITY.md`. Never include credentials or secrets.
