#!/usr/bin/env bash
# =============================================================================
# scripts/supervise_tasks.sh — AIOS Adaptive Supervision Loop v4.0
# Implements Workflow.md Stage 1-4 Adaptive Polling
# =============================================================================
set -euo pipefail

AGENT_NAME="${AGENT_NAME:-agent_unknown}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

HEARTBEAT_FILE="Agents/heartbeats/${AGENT_NAME}.txt"
LAST_HEARTBEAT_TIME=0
HEARTBEAT_INTERVAL=300 # 5 minutes

# Adaptive Polling State
CURRENT_STAGE=1
INACTIVITY_TIME=0

# Polling intervals per stage (seconds)
# Stage 1: 1m, Stage 2: 2m, Stage 3: 5m, Stage 4: 10m
get_interval() {
  case $CURRENT_STAGE in
    1) echo 60 ;;
    2) echo 120 ;;
    3) echo 300 ;;
    4) echo 600 ;;
    *) echo 300 ;;
  esac
}

update_stage() {
  if [[ $INACTIVITY_TIME -lt 300 ]]; then
    CURRENT_STAGE=1
  elif [[ $INACTIVITY_TIME -lt 900 ]]; then
    CURRENT_STAGE=2
  elif [[ $INACTIVITY_TIME -lt 3600 ]]; then
    CURRENT_STAGE=3
  else
    CURRENT_STAGE=4
  fi
}

reset_supervision() {
  echo "[${AGENT_NAME}] Activity detected. Resetting to Stage 1."
  CURRENT_STAGE=1
  INACTIVITY_TIME=0
}

heartbeat() {
  local now
  now=$(date +%s)
  if (( now - LAST_HEARTBEAT_TIME < HEARTBEAT_INTERVAL )); then
    return 0
  fi

  mkdir -p Agents/heartbeats
  echo "agent: ${AGENT_NAME}" > "${HEARTBEAT_FILE}"
  echo "last_beat: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${HEARTBEAT_FILE}"
  echo "state: Idle" >> "${HEARTBEAT_FILE}"
  
  git add "${HEARTBEAT_FILE}"
  if ! git diff --cached --quiet; then
    git commit -m "aios(heartbeat): ${AGENT_NAME}" --quiet
    git push origin main --quiet 2>/dev/null || true
  fi
  LAST_HEARTBEAT_TIME=$now
}

claim_task() {
  git pull origin main --rebase --quiet 2>/dev/null || true

  local task_file
  task_file=$(find task/Pending -maxdepth 1 -name "*.md" ! -name ".gitkeep" \
              2>/dev/null | sort | head -1)
  [[ -z "${task_file}" ]] && return 1

  local task_id
  task_id=$(basename "${task_file}" .md)
  local dest="task/Assigned/${task_id}.md"

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

  git reset HEAD~1 --quiet 2>/dev/null
  git checkout -- . 2>/dev/null
  git clean -fd task/ --quiet 2>/dev/null || true
  return 1
}

echo "[${AGENT_NAME}] Adaptive Supervisor started."
while true; do
  heartbeat
  
  if claim_task; then
    reset_supervision
    echo "[${AGENT_NAME}] Task claimed — execute work, then move to task/Working/"
    # We stay in the loop but usually the agent would now be 'working'
    # In a real deployment, this script might exit or the agent would handle the task
  else
    # Check for repo updates to trigger reset
    git fetch origin main --quiet 2>/dev/null || true
    if ! git diff --quiet HEAD origin/main; then
      reset_supervision
    fi
    
    # Increment inactivity and update stage
    INTERVAL=$(get_interval)
    sleep "$INTERVAL"
    INACTIVITY_TIME=$((INACTIVITY_TIME + INTERVAL))
    update_stage
  fi
done
