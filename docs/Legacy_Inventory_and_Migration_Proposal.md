# Legacy Inventory and Safe Migration Proposal

## Purpose
This document inventories repository artifacts that do not fully match the canonical AIOS structure and proposes safe migration pathways that preserve compatibility and repository history.

## Legacy Inventory

### 1. Specification Location Drift
- `system/` currently contains the operative AIOS specification set.
- `instruction/` exists as a separate singular directory with historical bootstrap prompt material.
- `instructions/` did not exist previously and has now been initialized for canonical forward-looking standards work.

**Impact:** Workers may read different instruction roots depending on which document they trust first.

**Safe Migration Path:**
- Keep `system/` as compatibility source during migration.
- Add canonical documents to `instructions/`.
- In a future authorized task, mirror or forward core files from `instructions/` and explicitly designate the canonical source of truth.

### 2. Mixed Specification Naming
- Existing files under `system/` use mixed naming such as `Readme.md`, `Agent_spec.md`, and uppercase variants like `TASK_SPEC.md`.

**Impact:** Automated readers expecting uniform casing may fail or duplicate reads.

**Safe Migration Path:**
- Standardize future canonical filenames in `instructions/`.
- Keep legacy names in place until compatibility stubs or mirrored copies are approved.

### 3. Root-Level Script Sprawl
- `vm_optimization (1).sh` remains in the repository root.
- New operational polling scripts were created under `scripts/`, but historical script placement is inconsistent.
- `system/Connect.sh` is still a legacy bootstrap entry point.

**Impact:** Bootstrap logic is fragmented and may encourage unsafe or duplicate automation paths.

**Safe Migration Path:**
- Consolidate future automation in `scripts/`.
- Replace legacy entry points with forwarding stubs once approved.
- Avoid deleting root-level scripts until downstream references are inventoried.

### 4. Report Location Inconsistency
- Historical reports exist directly under `reports/`.
- Canonical report subdirectories now also exist: `Completed/`, `Verification/`, `important/`, `reject/`, `verifed/`.

**Impact:** Report discovery is inconsistent, especially for automated verification tools.

**Safe Migration Path:**
- Store new reports using the formal naming convention.
- Preserve historical reports in place unless a separate housekeeping task re-indexes them.
- Optionally add an index file mapping legacy reports to normalized categories.

### 5. Task Naming Inconsistency
- Historical task files in `task/Complete/` use narrative names such as `agent_101_create_bsc_nursing_notes.md`.
- Newer tasks follow `TASK-YYYYMMDD-XXXX.md` naming.

**Impact:** Automated task inventory and lifecycle tracking must handle two naming systems.

**Safe Migration Path:**
- Enforce canonical naming for all new tasks.
- Preserve historical task files unchanged.
- Create migration notes or cross-reference indexes if future tooling requires uniform IDs.

### 6. Agent Subdirectory Gaps
- `Agents/profiles/`, `Agents/heartbeats/`, and `Agents/offline/` were absent and are now initialized.

**Impact:** Prior workers could not store canonical profile or heartbeat state.

**Safe Migration Path:**
- Keep the newly created directories.
- Introduce templates or conventions for heartbeat/profile files in a future task.

### 7. Structural Mismatch with Readme Examples
- `system/Readme.md` references canonical structures such as `/instructions/`, `/message/`, and `/logs/`, but not all were present or populated in the actual repository state.

**Impact:** Workers may assume directories exist and fail when they do not.

**Safe Migration Path:**
- Initialize missing canonical directories only through authorized tasks.
- Update canonical documentation to distinguish between required, optional, and transitional directories.

### 8. Sensitive Credential Demonstration Artifacts
- `encrypted_pat.md` includes credential-related demonstration material and code snippets referencing local secret handling.
- `setup-report.md` historically included an abbreviated PAT reference.

**Impact:** Security posture is weakened if workers copy patterns carelessly or restate secret material.

**Safe Migration Path:**
- Preserve the files for historical context.
- Avoid reproducing secret-like values in reports.
- In a future security-hardening task, sanitize explanatory examples while retaining instructional value.

## Migration Principles
1. Preserve backward compatibility.
2. Prefer additive migration over renames or deletions.
3. Do not move historical artifacts without explicit authorization.
4. Keep all new artifacts compliant with the latest canonical templates.
5. Use stubs, indexes, and compatibility notes before disruptive restructuring.

## Recommended Next Migration Steps
1. Author canonical `SYSTEM.md` under `instructions/`.
2. Mirror or forward the remaining core AIOS specs into `instructions/`.
3. Standardize `scripts/Connect.sh` and convert `system/Connect.sh` into a safe forwarding stub.
4. Initialize `message/` and `logs/` when authorized.
5. Create a legacy report index and task index for automated tooling.
6. Plan a dedicated compatibility sprint for casing normalization and specification source-of-truth unification.

## Conclusion
The repository is partially compliant and improving. The safest path forward is controlled, documented migration that preserves historical artifacts while requiring all future work to align with canonical AIOS directory and template standards.
