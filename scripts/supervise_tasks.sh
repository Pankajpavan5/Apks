#!/usr/bin/env bash
# Canonical AIOS Adaptive Supervision Polling Script v2.0
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"
echo "=== AIOS Adaptive Supervision Poller Active ==="
INTERVAL=60
while true; do
    git fetch origin
    LOCAL_HEAD=$(git rev-parse HEAD)
    REMOTE_HEAD=$(git rev-parse origin/main)
    if [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
        git pull origin main
        INTERVAL=60
    fi
    PENDING=$(find task/Assigned -maxdepth 1 -name "*.md" | grep -v ".gitkeep" || true)
    if [ -n "$PENDING" ]; then exit 0; fi
    sleep "$INTERVAL"
done
