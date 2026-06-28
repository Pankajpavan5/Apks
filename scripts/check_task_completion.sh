#!/usr/bin/env bash
# =============================================================================
# scripts/check_task_completion.sh — 1-Minute Polling Command for Task Completion
# Author: task_manager
# Purpose: Standalone CLI checking command for worker task completion in Complete/
# Usage: bash scripts/check_task_completion.sh [max_iterations]
# =============================================================================
set -euo pipefail

MAX_CHECKS="${1:-5}"
INTERVAL=60

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "=== AIOS Worker Task Completion Checking Loop Initialized ==="
echo "Polling remote origin/main for verified deliverables in task/Complete/ every ${INTERVAL} seconds..."

for ((i=1; i<=MAX_CHECKS; i++)); do
    echo ""
    echo "─── [Minute $i / $MAX_CHECKS Audit Check: $(date -u '+%H:%M:%S UTC')] ───"
    git fetch origin --quiet 2>/dev/null || true
    
    LOCAL_HEAD=$(git rev-parse HEAD)
    REMOTE_HEAD=$(git rev-parse origin/main)
    
    if [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
        echo "  [Activity Detected] Synchronizing local repository..."
        git pull origin main --rebase --quiet 2>/dev/null || true
    fi
    
    COMPLETED=$(find task/Complete -maxdepth 1 -name "*.md" ! -name ".gitkeep" 2>/dev/null || true)
    
    if [ -n "$COMPLETED" ]; then
        echo "  [✓ VERIFIED COMPLETED TASKS DETECTED]"
        echo "$COMPLETED" | sed 's/^/    · /'
        exit 0
    else
        echo "  [Status] No newly completed tasks detected. Workers active..."
    fi
    
    if [ $i -lt $MAX_CHECKS ]; then
        sleep "$INTERVAL"
    fi
done

echo ""
echo "=== Completed supervision cycle (${MAX_CHECKS} checks). ==="
