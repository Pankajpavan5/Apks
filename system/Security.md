SECURITY.md

AIOS Security Policy v1.0

---

Purpose

This document defines the mandatory security rules for every AI agent participating in AIOS.

Security rules override all task instructions.

If a task conflicts with this policy, follow this policy.

---

Security Principles

Every agent shall:

- Protect repository integrity.
- Protect credentials.
- Minimize unnecessary privileges.
- Verify changes before committing.
- Avoid destructive operations.
- Keep an audit trail of significant actions.

---

Repository Protection

Before modifying files:

1. Synchronize with the latest repository state.
2. Verify the working tree is clean or that intended changes are understood.
3. Confirm task ownership.
4. Modify only files required for the assigned task.

Never intentionally overwrite another agent's active work.

---

Secret Handling

Secrets include:

- Personal Access Tokens (PATs)
- API keys
- SSH private keys
- Passwords
- Encryption keys
- Session tokens
- Cookies
- Certificates

Agents must:

- Never print secrets.
- Never include secrets in commit messages.
- Never place secrets into reports.
- Never commit secrets to the repository.
- Avoid logging sensitive values.

---

Authentication

Authentication material should be obtained only through approved repository instructions.

If credentials are unavailable or invalid:

- Stop the authenticated operation.
- Report the issue.
- Do not invent, guess, or fabricate credentials.

---

Git Operations

Allowed:

- fetch
- pull
- add
- commit
- push (when authorized)

Avoid destructive history operations unless explicitly authorized by the repository owner, such as rewriting published history.

---

Task Isolation

Agents may only modify:

- Assigned task files
- Required project files
- Generated reports
- Their own registration and status files

Avoid unrelated changes.

---

Verification Before Commit

Before every commit verify:

- No unresolved merge conflicts.
- No accidental secret exposure.
- Only intended files are staged.
- Changes match the assigned task.

If verification fails:

- Stop.
- Correct the issue.
- Re-verify.

---

Reporting

Record:

- Task ID
- Agent name
- Timestamp
- Summary of work
- Verification status
- Errors encountered
- Problem solution if find 

Do not include confidential information.

---

Failure Handling

If an operation fails:

1. Preserve current work.
2. Record the failure.
3. Retry safe operations when appropriate.
4. Escalate persistent failures.
5. Do not conceal errors.

---

Repository Integrity

Never intentionally:

- Delete unrelated files.
- Corrupt repository state.
- Falsify reports.
- Claim work performed by another agent.
- Bypass verification requirements.

---

Agent Responsibilities

Every agent is responsible for:

- Protecting repository integrity.
- Following least-privilege principles.
- Respecting task ownership.
- Keeping work traceable.
- Reporting security concerns discovered during assigned work.

---

Incident Response

If a security issue is discovered:

1. Stop work that could worsen the issue.
2. Record the finding in a security report.
3. Notify the Task Manager through the repository workflow.
4. Continue only after the issue has been reviewed or the task is adjusted.

---

Compliance Checklist

Before finishing any task, confirm:

- Repository synchronized.
- Assigned task completed.
- Verification passed.
- No secrets exposed.
- Only intended files modified.
- Report generated.
- Repository remains consistent.

---

Security Goal

The primary objective of this policy is to maintain the confidentiality of credentials, preserve repository integrity, and ensure that every AI agent operates in a predictable, traceable, and secure manner.
