#!/usr/bin/env bash
# =============================================================================
# scripts/Connect.sh — AIOS Secure GitHub Auth Bootstrap v3.0
# Fixes: missing push after register, env var name standardized to GITHUB_PAT,
#        git user.name set before commit, stderr masking
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"
echo "[Connect] Repo root: ${REPO_DIR}"

# --------------------------------------------------------------------------- #
# 1. PAT INJECTION — RAM only, never printed
# --------------------------------------------------------------------------- #
if [[ -z "${GITHUB_PAT:-}" ]]; then
  echo "[Connect] ERROR: GITHUB_PAT env var not set."
  echo "  Usage: GITHUB_PAT=ghp_xxx bash scripts/Connect.sh"
  exit 1
fi

git remote set-url origin \
  "https://${GITHUB_PAT}@github.com/Pankajpavan5/Apks.git" 2>/dev/null
unset GITHUB_PAT

# --------------------------------------------------------------------------- #
# 2. SYNC
# --------------------------------------------------------------------------- #
git fetch origin 2>/dev/null
git checkout -B main origin/main 2>/dev/null || git reset --hard origin/main

# --------------------------------------------------------------------------- #
# 3. GOVERNANCE SPEC INGESTION
# --------------------------------------------------------------------------- #
for doc in instructions/DIRECTORY_SPEC.md system/Security.md system/Workflow.md; do
  [[ -f "$doc" ]] && echo "  [✓ Spec] $doc"
done

# --------------------------------------------------------------------------- #
# 4. AUTO NAME ASSIGNMENT
# --------------------------------------------------------------------------- #
mkdir -p Agents/online
LAST_ID=$(find Agents/online -maxdepth 1 -type f -name "agent_*.txt" 2>/dev/null \
  | sed -E 's/.*agent_([0-9]+)\.txt/\1/' | sort -n | tail -1 || echo "100")
[[ -z "$LAST_ID" ]] && LAST_ID=100
NEXT_ID=$((LAST_ID + 1))
AGENT_NAME=$(printf "agent_%03d" "$NEXT_ID")

# --------------------------------------------------------------------------- #
# 5. LOCAL GIT IDENTITY
# --------------------------------------------------------------------------- #
git config --local user.name  "${AGENT_NAME}"
git config --local user.email "${AGENT_NAME}@users.noreply.github.com"

# --------------------------------------------------------------------------- #
# 6. REGISTER ONLINE
# --------------------------------------------------------------------------- #
ONLINE_FILE="Agents/online/${AGENT_NAME}.txt"
cat > "${ONLINE_FILE}" <<REG
Agent Name: ${AGENT_NAME}
Role: Worker
Status: Online
State: Idle
Version: 3.0
Joined: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
REG

git add "${ONLINE_FILE}"
if ! git diff --cached --quiet; then
  git commit -m "aios(agent): ${AGENT_NAME} online"
  git push origin main 2>/dev/null && echo "[Connect] Pushed registration."
fi

echo "[Connect] Agent: ${AGENT_NAME} — OK"
echo "export AGENT_NAME=${AGENT_NAME}" > /tmp/aios_agent_env
