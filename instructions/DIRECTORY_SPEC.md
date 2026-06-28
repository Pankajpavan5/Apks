DIRECTORY_SPEC.md

AIOS Directory Specification v1.0

---

Purpose

This document defines the canonical repository directory structure for AIOS.

It standardizes where instructions, agent state, tasks, reports, messages, scripts, logs, templates, and project artifacts should live so every worker can discover and modify repository content predictably.

---

Governance Scope

This specification is authoritative for directory layout and naming conventions.

If repository structure conflicts with historical content, workers must preserve legacy artifacts while following this specification for all new work unless a higher-priority instruction explicitly says otherwise.

---

Canonical Root Structure

The canonical AIOS root structure is:

/
├── instructions/
├── Agents/
├── task/
├── reports/
├── message/
├── scripts/
├── logs/
├── templates/
├── docs/
├── research/
└── README.md

Not every repository must use every directory immediately, but the above structure is the target standard for AIOS-compliant repositories.

---

Directory Definitions

instructions/
- Contains normative AIOS specifications and operating instructions.
- Preferred filenames are uppercase for canonical specs.
- Required baseline documents should include:
  - INDEX.md or README.md
  - SYSTEM.md
  - GOVERNANCE.md
  - SECURITY.md
  - WORKFLOW.md
  - COORDINATION.md
  - AGENT_SPEC.md
  - TASK_SPEC.md
  - REPORT_SPEC.md
  - DIRECTORY_SPEC.md

system/
- Legacy compatibility location for existing repositories.
- May temporarily mirror or forward to canonical files in instructions/.
- New normative documents should be authored in instructions/ unless repository governance directs otherwise.

instruction/
- Legacy compatibility location for historical prompts or transitional material.
- Not canonical for new AIOS specifications.

Agents/
- Contains worker presence, identity, profiles, heartbeats, and offline records.
- Canonical subdirectories:
  - online/
  - profiles/
  - heartbeats/
  - offline/

Agents/online/
- One registration file per online agent.
- Files should never overwrite another active agent's registration.

Agents/profiles/
- Optional persistent capability and specialization metadata for each agent.

Agents/heartbeats/
- Optional lightweight liveness or polling status artifacts.

Agents/offline/
- Historical or explicit offline-state records.

task/
- Canonical lifecycle root for task artifacts.
- Required subdirectories:
  - Pending/
  - Assigned/
  - Working/
  - Verification/
  - Complete/
  - Blocked/
  - Archived/

reports/
- Canonical root for work reports.
- Recommended subdirectories:
  - Completed/
  - Verification/
  - verifed/
  - reject/
  - important/
- Legacy reports stored directly under reports/ should be preserved unless an authorized migration task rehomes them.

message/
- Structured inter-agent communication artifacts.
- Should be used for traceable direct coordination when implemented.

scripts/
- Operational automation, bootstrap, polling, build, and maintenance scripts.
- New repository automation should prefer this directory over root-level shell script sprawl.

logs/
- Non-sensitive execution logs, diagnostic traces, and runtime records.
- Secrets must never be written here.

templates/
- Canonical reusable markdown templates for tasks, reports, and related repository artifacts.

docs/
- Human-readable project documentation, migration plans, inventories, design notes, and policy commentary that is not itself a normative AIOS spec.

research/
- Research deliverables, investigations, technical studies, and long-form analysis artifacts.

---

Naming Rules

Directory naming rules:
- Use exact canonical directory names where defined above.
- Preserve historical directories if migration would break active workflows.
- Do not silently delete legacy directories.

Specification filename rules:
- Canonical normative documents in instructions/ should use uppercase names where possible.
- Legacy mixed-case names may remain for compatibility during migration.

Task directory naming rules:
- Task files should follow TASK_SPEC.md naming format.

Report naming rules:
- Reports should follow REPORT_SPEC.md naming format.

---

Migration Rules

When canonicalizing a legacy repository:
1. Preserve repository history.
2. Prefer additive migration over destructive relocation.
3. Use forwarding stubs, mirrors, or compatibility notes when moving critical files.
4. Document non-compliant legacy artifacts before changing them.
5. Keep new work compliant even if old work remains non-compliant.

---

Compliance Expectations

Workers must:
- Read current repository structure before acting.
- Create missing canonical directories only when authorized or required by assigned work.
- Avoid modifying unrelated legacy artifacts.
- Record migration proposals in reports or docs.

Workers must not:
- Delete legacy content without authorization.
- Assume canonical directories already exist.
- Overwrite another agent's status or task files.

---

Success Criteria

Repository directory compliance improves when:
- Canonical directories exist.
- New artifacts are created in the correct locations.
- Legacy artifacts are inventoried and preserved safely.
- Migration pathways are documented clearly.
- Agents can discover tasks, reports, instructions, and coordination state predictably.
