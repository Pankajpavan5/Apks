REPORT_SPEC.md

AIOS Report Specification v1.0

---

Purpose

This document defines the standard reporting format for all AIOS agents.

Every completed, failed, blocked, or cancelled task must produce a report.

Reports provide a permanent audit trail, support coordination, and enable continuous improvement.

---

Report Location

reports/
├── Completed/
├── Verification/
├── verifed/
├── reject/
└── important/

Every report must be stored in the appropriate directory.

---

Report Naming

Format

REPORT-<TaskID>-<AgentName>.md

Example

REPORT-TASK-20260628-0007-agent_004.md

---

Report Template

Report ID:

Task ID:

Task Name:

Agent Name:

Agent Role:

Repository Branch:

Start Time:

End Time:

Duration:

Task Status:
(Completed / Failed / Blocked / Cancelled)

Priority:

Objective:

Summary:

Work Performed:

Files Created:

Files Modified:

Files Deleted:

Commands Executed:

Tests Performed:

Verification Results:

Repository Status:

Problems Encountered:

Root Cause:

Solution Applied:

Remaining Issues:

Recommendations:

Dependencies Discovered:

Performance Notes:

Security Checks:

Lessons Learned:

Next Suggested Task:

Confidence Level:

Timestamp:

---

Verification

Before submitting a report verify:

- Task objectives achieved.
- Expected output generated.
- Files validated.
- Repository synchronized.
- No unresolved conflicts.
- No secrets exposed.

---

Problem Reporting

If problems occur record:

- Error message
- Root cause
- Recovery steps
- Final outcome

Never hide failures.

---

Learning Capture

Every report should include:

- What worked well.
- What should be improved.
- Suggested workflow optimizations.
- Potential automation opportunities.
- Knowledge useful for future agents.

This allows AIOS to improve over time.

---

Security Reporting

Confirm:

- No credentials exposed.
- No sensitive files committed.
- Repository integrity preserved.
- Security policy followed.

---

Metrics

Record:

- Time spent
- Files changed
- Verification count
- Retry count
- Problems solved
- Remaining blockers

These metrics help the Task Manager optimize future assignments.

---

Task Manager Responsibilities

The Task Manager must review every report and:

- Verify completion.
- Confirm verification results.
- Update task status.
- Archive accepted reports.
- Return incomplete work for revision when necessary.

---

Report Rules

Always:

- Be factual.
- Be complete.
- Include evidence where appropriate.
- Reference the correct Task ID.
- Record both successes and failures.

Never:

- Fabricate results.
- Omit known problems.
- Include confidential information.
- Claim another agent's work.

---

Continuous Improvement

Every completed report should answer:

1. What was requested?
2. What was delivered?
3. What problems occurred?
4. How were they solved?
5. What remains?
6. What can future agents improve?

Reports are not only historical records—they are a knowledge base that helps AIOS become more reliable and efficient over time.

---

Success Criteria

A report is considered complete when:

- All required fields are filled.
- Verification results are included.
- Problems and solutions are documented.
- Lessons learned are captured.
- The Task Manager accepts the report.

Only after report acceptance may the associated task remain in:

task/Complete/
