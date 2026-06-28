#!/usr/bin/env bash
# =============================================================================
# scripts/check_new_tasks.sh — 1-Minute Polling Command for New Task Assignments
# Author: agent_101 (Autonomous Linux/GitHub Worker)
# Compliance: WORKFLOW.md Stage 1 Fast Discovery (1 min polling, 20 min default duration)
# Usage: bash scripts/check_new_tasks.sh [max_iterations] (default: 20 checks = 20 mins)
# =============================================================================
set -euo pipefail

MAX_CHECKS="${1:-20}"
INTERVAL=60

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "=== AIOS New Task Assignment Checking Loop Initialized ==="
echo "Polling remote origin/main for pending tasks in task/Pending/ every ${INTERVAL} seconds..."

for ((i=1; i<=MAX_CHECKS; i++)); do
    echo ""
    echo "─── [Minute $i / $MAX_CHECKS Queue Check: $(date -u '+%H:%M:%S UTC')] ───"
    git fetch origin --quiet 2>/dev/null || true
    
    LOCAL_HEAD=$(git rev-parse HEAD)
    REMOTE_HEAD=$(git rev-parse origin/main)
    
    if [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
        echo "  [Activity Detected] Synchronizing local repository..."
        git pull origin main --rebase --quiet 2>/dev/null || true
    fi
    
    TASK_FILE=$(find task/Pending -maxdepth 1 -name "*.md" ! -name ".gitkeep" 2>/dev/null | sort | head -1 || true)
    
    if [ -n "$TASK_FILE" ]; then
        TASK_ID=$(basename "$TASK_FILE" .md)
        echo "  [🎉 NEW TASK DETECTED] $TASK_ID found in task/Pending/!"
        echo "  Ready for worker claiming routine."
        exit 0
    else
        echo "  [Status] Queue empty. Standing by for task manager dispatch..."
    fi
    
    if [ $i -lt $MAX_CHECKS ]; then
        sleep "$INTERVAL"
    fi
done

echo ""
echo "=== Completed monitoring loop (${MAX_CHECKS} checks). Returning to Idle. ==="
