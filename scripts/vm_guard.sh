#!/usr/bin/env bash
# =============================================================================
# scripts/vm_guard.sh — Agent Resource Governor
# Monitors RAM/CPU usage and prevents VM crashes during heavy tasks.
# =============================================================================
set -euo pipefail

THRESHOLD=90 # Percentage of RAM usage to trigger action
CHECK_INTERVAL=30 # seconds

echo "[VM-Guard] Starting Resource Governor (Threshold: ${THRESHOLD}%)"

while true; do
  # Calculate current RAM usage %
  MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)

  if [ "$MEM_USAGE" -gt "$THRESHOLD" ]; then
    echo "[VM-Guard] ALERT: High Memory Usage detected (${MEM_USAGE}%). Triggering cleanup..."
    
    # 1. Clear PageCache, dentries, and inodes (Requires sudo)
    sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    # 2. Identify the top memory consumer
    TOP_PROC=$(ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -n 2 | tail -n 1)
    echo "[VM-Guard] Top Consumer: $TOP_PROC"
    
    # 3. If it's a background poller, throttle it
    if echo "$TOP_PROC" | grep -qE "poll|supervise"; then
      echo "[VM-Guard] Throttling background process to save task memory..."
      PID=$(echo "$TOP_PROC" | awk '{print $1}')
      sudo renice -n 19 -p "$PID" > /dev/null || true
    fi
  fi
  
  sleep "$CHECK_INTERVAL"
done
