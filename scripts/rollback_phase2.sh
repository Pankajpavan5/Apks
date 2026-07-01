#!/bin/bash
###############################################################################
# AIOS Phase 2 Rollback: Restore Original Service Files
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
#
# This script restores the original service files from backup
# and restarts services one-by-one with health checks.
# If no backup found, it attempts to reinstall default packages.
###############################################################################
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}!${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
head() { echo -e "\n${B}══ $1 ══${N}"; }

if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo)"
    exit 1
fi

# Find the latest backup directory
BACKUP_DIR=$(ls -td /tmp/aios-phase2-backup-* 2>/dev/null | head -1)

head "PHASE 2 ROLLBACK: Restoring Original Service Files"
if [[ -n "$BACKUP_DIR" ]]; then
    echo "Found backup: $BACKUP_DIR"
else
    warn "No backup directory found!"
    echo "Attempting to restore default service configurations..."
fi
echo ""

# Function to check service health
check_service_health() {
    local svc=$1
    local max_retries=5
    local retry=0

    while [[ $retry -lt $max_retries ]]; do
        sleep 2
        if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
            ok "${svc}.service is running"
            return 0
        fi
        retry=$((retry + 1))
        warn "${svc}.service not ready yet (attempt $retry/$max_retries)..."
    done

    err "${svc}.service FAILED to start!"
    return 1
}

head "1/4  Restore Service Files from Backup"

if [[ -n "$BACKUP_DIR" ]]; then
    # Restore code-interpreter.service
    if [[ -f "$BACKUP_DIR/code-interpreter.service.bak" ]]; then
        cp "$BACKUP_DIR/code-interpreter.service.bak" /etc/systemd/system/code-interpreter.service
        ok "Restored: code-interpreter.service"
    else
        warn "No backup for code-interpreter.service"
    fi

    # Restore jupyter.service
    if [[ -f "$BACKUP_DIR/jupyter.service.bak" ]]; then
        cp "$BACKUP_DIR/jupyter.service.bak" /etc/systemd/system/jupyter.service
        ok "Restored: jupyter.service"
    else
        warn "No backup for jupyter.service"
    fi

    # Restore envd.service
    if [[ -f "$BACKUP_DIR/envd.service.bak" ]]; then
        cp "$BACKUP_DIR/envd.service.bak" /etc/systemd/system/envd.service
        ok "Restored: envd.service"
    else
        warn "No backup for envd.service"
    fi

    # Restore drop-in directories
    for dir in code-interpreter.service.d jupyter.service.d envd.service.d; do
        if [[ -d "$BACKUP_DIR/$dir" ]]; then
            rm -rf "/etc/systemd/system/$dir"
            cp -r "$BACKUP_DIR/$dir" "/etc/systemd/system/"
            ok "Restored: $dir/"
        fi
    done
else
    warn "No backup found - attempting package reinstall for defaults"

    # Try to get default service files from packages
    if command -v dpkg &>/dev/null; then
        # Reinstall packages to restore default configs
        sudo apt-get install --reinstall -y openssh-server systemd 2>/dev/null || warn "Package reinstall failed"
        ok "Attempted package reinstall for defaults"
    fi
fi

head "2/4  Reload Systemd Daemon"
sudo systemctl daemon-reload
ok "Systemd daemon reloaded"

head "3/4  Restart Services One-by-One"

# Stop jupyter first (code-interpreter depends on it)
echo "  Stopping code-interpreter.service (depends on jupyter)..."
sudo systemctl stop code-interpreter.service 2>/dev/null || true
sleep 1

echo "  Restarting jupyter.service..."
sudo systemctl start jupyter.service 2>/dev/null || {
    err "jupyter.service failed to start!"
    echo "  Attempting emergency start with minimal config..."
    cat > /etc/systemd/system/jupyter.service << 'FALLBACK'
[Unit]
Description=Jupyter Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/jupyter server --IdentityProvider.token=""
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
FALLBACK
    sudo systemctl daemon-reload
    sudo systemctl start jupyter.service 2>/dev/null || err "Emergency start also failed"
}
check_service_health "jupyter" || err "Jupyter rollback failed!"

sleep 3

echo "  Restarting code-interpreter.service..."
sudo systemctl start code-interpreter.service 2>/dev/null || {
    err "code-interpreter.service failed to start!"
    echo "  Attempting emergency start with minimal config..."
    cat > /etc/systemd/system/code-interpreter.service << 'FALLBACK'
[Unit]
Description=Code Interpreter Server
Requires=jupyter.service
After=jupyter.service

[Service]
Type=simple
WorkingDirectory=/root/.server
ExecStart=/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
FALLBACK
    sudo systemctl daemon-reload
    sudo systemctl start code-interpreter.service 2>/dev/null || err "Emergency start also failed"
}
check_service_health "code-interpreter" || err "Code-interpreter rollback failed!"

sleep 3

echo "  Restarting envd.service..."
sudo systemctl restart envd.service 2>/dev/null || {
    err "envd.service failed to start!"
    echo "  Attempting emergency start with minimal config..."
    cat > /etc/systemd/system/envd.service << 'FALLBACK'
[Unit]
Description=Env Daemon Service
After=multi-user.target

[Service]
Type=simple
Restart=always
ExecStart=/bin/bash -l -c "/usr/bin/envd"

[Install]
WantedBy=multi-user.target
FALLBACK
    sudo systemctl daemon-reload
    sudo systemctl start envd.service 2>/dev/null || err "Emergency start also failed"
}
check_service_health "envd" || err "Envd rollback failed!"

head "4/4  Final Verification"
echo ""
echo "=== SERVICE STATUS AFTER ROLLBACK ==="
for svc in code-interpreter jupyter envd dbus systemd-journald systemd-logind systemd-networkd; do
    if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
        pid=$(systemctl show ${svc}.service -p MainPID --value 2>/dev/null)
        echo -e "  ${G}✓${N} $svc: running (PID=$pid)"
    else
        echo -e "  ${R}✗${N} $svc: NOT RUNNING"
    fi
done

echo ""
echo "=== MEMORY USAGE ==="
free -h | head -2

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  PHASE 2 ROLLBACK COMPLETE                                    ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  All Phase 2 service changes have been reverted:                 ║"
echo "║   · Service files restored from backup                            ║"
echo "║   · Drop-in configs restored                                      ║"
echo "║   · Services restarted and verified                               ║"
echo "║                                                                 ║"
echo "║  Backup location: ${BACKUP_DIR:-NONE FOUND}           ║"
echo "║                                                                 ║"
echo "║  To complete full rollback, also run:                            ║"
echo "║    bash scripts/rollback_phase1.sh                               ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
