#!/usr/bin/env bash
# =============================================================================
# scripts/supervise_tasks.sh — AIOS Agent Task Polling Loop v3.0
# Fixes: polls Pending (not Assigned), atomic claim, heartbeat, 5min interval
# Usage: AGENT_NAME=agent_104 bash scripts/supervise_tasks.sh
# =============================================================================
set -euo pipefail

AGENT_NAME="${AGENT_NAME:-agent_unknown}"
POLL_INTERVAL="${POLL_INTERVAL:-300}"     # 5 min — AGENT_SPEC Stage 4 standard
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

HEARTBEAT_FILE="Agents/heartbeats/${AGENT_NAME}.txt"

# --------------------------------------------------------------------------- #
heartbeat() {
  mkdir -p Agents/heartbeats
  echo "agent: ${AGENT_NAME}" > "${HEARTBEAT_FILE}"
  echo "last_beat: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${HEARTBEAT_FILE}"
  echo "state: Idle" >> "${HEARTBEAT_FILE}"
  git add "${HEARTBEAT_FILE}"
  git diff --cached --quiet && return 0
  git commit -m "aios(heartbeat): ${AGENT_NAME}" --quiet
  git push origin main --quiet 2>/dev/null || true
}

# --------------------------------------------------------------------------- #
claim_task() {
  git pull origin main --rebase --quiet 2>/dev/null || true

  local task_file
  task_file=$(find task/Pending -maxdepth 1 -name "*.md" ! -name ".gitkeep" \
              2>/dev/null | sort | head -1)
  [[ -z "${task_file}" ]] && return 1

  local task_id
  task_id=$(basename "${task_file}" .md)
  local dest="task/Assigned/${task_id}.md"

  # Write claim header + original task content
  {
    echo "Assigned To: ${AGENT_NAME}"
    echo "Claimed At: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Status: Assigned"
    echo "---"
    cat "${task_file}"
  } > "${dest}"

  git rm "${task_file}" --quiet
  git add "${dest}"

  if git commit -m "aios(claim): ${AGENT_NAME} → ${task_id}" --quiet; then
    if git push origin main --quiet 2>/dev/null; then
      echo "[${AGENT_NAME}] ✓ Claimed: ${task_id}"
      return 0
    fi
  fi

  # Push failed = race condition, another agent won
  git reset HEAD~1 --quiet 2>/dev/null
  git checkout -- . 2>/dev/null
  git clean -fd task/ --quiet 2>/dev/null || true
  echo "[${AGENT_NAME}] Race lost on ${task_id}, retrying next cycle."
  return 1
}

# --------------------------------------------------------------------------- #
echo "[${AGENT_NAME}] Supervisor started. Poll every ${POLL_INTERVAL}s."
while true; do
  heartbeat
  if claim_task; then
    echo "[${AGENT_NAME}] Task claimed — execute work, then move to task/Working/"
  else
    echo "[$(date -u +%H:%M:%SZ)] [${AGENT_NAME}] No pending tasks."
  fi
  sleep "${POLL_INTERVAL}"
done
