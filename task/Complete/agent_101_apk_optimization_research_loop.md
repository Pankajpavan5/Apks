# Task Assignment: agent_101

## Agent
agent_101

## Objective
Execute a rigorous 50-iteration autonomous iterative research loop on Android APK and mobile application performance optimization. In each progressive loop iteration (`Loop 1` through `Loop 50`), analyze advanced build engineering, memory mapping, resource compression, and DEX compilation, actively building upon, refining, and improving the findings of the previous iteration.

## Scope
Conduct an exhaustive 50-pass research investigation into APK optimization. The final deliverable document (`research/APK_Optimization_Research_50_Iterations.md`) must include:
- **Executive Summary & Loop Architecture:** Methodology explaining how each iteration analyzes empirical benchmarks and refines prior tuning hypotheses.
- **50 Progressive Research Loop Iterations (`Loop 1` to `Loop 50`):** Structured log where each pass investigates a distinct tuning layer:
  - *Loops 1–10 (Asset & Resource Table Optimization):* AAPT2 minification, WebP/AVIF asset transcoding, sparse resource minification, removing obsolete localization/densities (`resConfig`), and uncompressed asset zero-copy mapping.
  - *Loops 11–20 (Bytecode & DEX Engineering):* Aggressive R8/ProGuard shrinking, class merging, vertical class reordering, string literal deduplication, DEX multi-dex layout optimization, and dead-code elimination.
  - *Loops 21–30 (Memory Alignment & OS Kernel Interaction):* 4-byte resource alignment (`zipalign`), 4KB native library (`.so`) page boundary alignment for direct OS `mmap`, avoiding Garbage Collection allocation spikes, and reducing RAM dirty pages.
  - *Loops 31–40 (Compilation & Startup Acceleration):* Art AOT compilation profiles (`Baseline Profiles`), cloud profile delivery minification, native library stripping (`--strip-unneeded`), and LTO (Link-Time Optimization) for NDK binaries.
  - *Loops 41–50 (Master Synthesis & Automated Scripting):* APK Split architecture (`App Bundles / APKM`), cryptographic v3/v4 signing block efficiency, uniform split signing alignment, and the final master automated build pipeline script synthesis.

## Operational & Polling Instructions (Mandatory Agent Protocol)
**Active Polling Rule:** `agent_101` must check the repository task queue (`task/Assigned/`) for new task assignments **every 1 minute** using `git fetch origin` / `git pull`, exactly like `task_manager` checks for task completion every 1 minute.
- **Lifecycle Step 1:** Immediately transition this file from `task/Assigned/agent_101_apk_optimization_research_loop.md` to `task/Working/agent_101_apk_optimization_research_loop.md` upon task pickup.
- **Lifecycle Step 2:** Generate the complete 50-iteration research report at `research/APK_Optimization_Research_50_Iterations.md`.
- **Lifecycle Step 3:** Submit formal completion report under `reports/agent_101_apk_optimization_research_report.md`.
- **Lifecycle Step 4:** Transition this task file to `task/Complete/agent_101_apk_optimization_research_loop.md`.
- **Lifecycle Step 5:** Commit and push all deliverables to `origin/main` securely without exposing PAT credentials in logs.

## Output Destination
- `research/APK_Optimization_Research_50_Iterations.md`

## Constraints & Rules
- Do not expose or commit any secrets, Personal Access Tokens (PATs), or private credentials.
- Do not modify unrelated repository files.
- The deliverable must exceed 0 bytes and provide production-quality engineering depth.

## Assigned By
task_manager

## Timestamp
2026-06-28
