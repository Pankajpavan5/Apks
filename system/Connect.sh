#!/usr/bin/env bash
create questions and ask user to pat
# ==========================================================
# AIOS Bootstrap Script
# Automatically registers a new worker agent
# ==========================================================

set -euo pipefail

REPO_DIR="/home/user/Apks"
PAT="<PAT>"


echo "=== AIOS Bootstrap ==="

# Enter repository
cd "$REPO_DIR"

# Configure temporary Git identity
git config --global user.email "Pankajpavan5@users.noreply.github.com"

# Configure remote
git remote set-url origin "https://${PAT}@github.com/Pankajpavan5/Apks.git"

# Sync repository
git fetch origin
git checkout -B main origin/main

# ----------------------------------------------------------
# Generate next available Agent ID
# ----------------------------------------------------------

mkdir -p Agents/online

LAST_ID=$(
find Agents/online -maxdepth 1 -type f -name "agent_*.txt" \
2>/dev/null \
| sed -E 's/.*agent_([0-9]+)\.txt/\1/' \
| sort -n \
| tail -1
)

if [ -z "$LAST_ID" ]; then
    NEXT_ID=1
else
    NEXT_ID=$((LAST_ID + 1))
fi

AGENT_NAME=$(printf "agent_%03d" "$NEXT_ID")

git config --global user.name "$AGENT_NAME"

echo "Assigned name: $AGENT_NAME"

# ----------------------------------------------------------
# Execute VM Optimization Script
# ----------------------------------------------------------

SCRIPT=$(find . -type f -name "vm_optimization (1).sh" | head -n1)

if [ -n "$SCRIPT" ]; then
    echo "Running: $SCRIPT"
    chmod +x "$SCRIPT"
    sudo "$SCRIPT"
else
    echo "WARNING: vm_optimization (1).sh not found."
fi

# ----------------------------------------------------------
# Register Agent
# ----------------------------------------------------------

cat > "Agents/online/${AGENT_NAME}.txt" <<EOF
Agent Name: $AGENT_NAME
Role: Worker
Status: Online
State: Idle
Version: 1.0
Joined: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

# ----------------------------------------------------------
# Commit Registration
# ----------------------------------------------------------

git add "Agents/online/${AGENT_NAME}.txt"

if ! git diff --cached --quiet; then
    git commit -m "Register ${AGENT_NAME}"
    git push origin main
else
    echo "Nothing to commit."
fi

echo
echo "======================================="
echo " Agent Registered Successfully"
echo " Name   : $AGENT_NAME"
echo " Status : Online"
echo " State  : Idle"
echo "======================================="
echo
echo "Waiting for Task Manager assignment..."
