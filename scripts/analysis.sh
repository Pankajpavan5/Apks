#!/usr/bin/env bash
# Correct-spelling alias for the user's canonical /anylasis command.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/anylasis.sh" "$@"
