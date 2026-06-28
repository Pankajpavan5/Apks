#!/usr/bin/env bash
# Backward-Compatible AIOS Bootstrap Forwarding Stub
echo "NOTICE: system/Connect.sh is deprecated. Invoking canonical scripts/Connect.sh..."
exec "$(dirname "$0")/../scripts/Connect.sh" "$@"
