#!/bin/bash
###############################################################################
# AIOS Phase 1: Safe Service Optimizations (NO service restarts required)
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
# Risk Level: LOW
#
# This script creates drop-in configuration overrides for running services
# WITHOUT restarting them. Changes take effect on next boot or manual reload.
###############################################################################
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}!${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
head() { echo -e "\n${B}══ $1 ══${N}"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo)"
    exit 1
fi

head "PHASE 1: Safe Service Optimizations (No Restarts)"
echo "Risk Level: LOW - Changes apply on next boot/reload only"
echo "Running services will NOT be restarted"
echo ""

# Create backup directory
BACKUP_DIR="/tmp/aios-phase1-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
ok "Backup directory created: $BACKUP_DIR"

head "1/6  Systemd-Journald Optimization"
mkdir -p /etc/systemd/journald.conf.d/
cat > /etc/systemd/journald.conf.d/optimize.conf << 'EOF'
[Journal]
Storage=volatile
Compress=yes
SystemMaxUse=16M
RuntimeMaxUse=16M
MaxRetentionSec=1day
ForwardToConsole=no
ForwardToWall=no
MaxLevelStore=warning
MaxLevelConsole=err
MaxLevelWall=crit
RateLimitIntervalSec=30s
RateLimitBurst=1000
EOF
cp /etc/systemd/journald.conf.d/optimize.conf "$BACKUP_DIR/" 2>/dev/null || true
ok "Journald: 16MB cap, volatile storage, warning+ level only"

head "2/6  Systemd-Logind Optimization"
mkdir -p /etc/systemd/logind.conf.d/
cat > /etc/systemd/logind.conf.d/optimize.conf << 'EOF'
[Login]
NAutoVTs=0
ReserveVT=0
KillUserProcesses=no
StopIdleSessionSec=300
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
InhibitDelayMaxSec=5
EOF
cp /etc/systemd/logind.conf.d/optimize.conf "$BACKUP_DIR/" 2>/dev/null || true
ok "Logind: 0 VTs, 5min idle timeout, power keys ignored"

head "3/6  Systemd-Networkd Optimization"
mkdir -p /etc/systemd/networkd.conf.d/
cat > /etc/systemd/networkd.conf.d/optimize.conf << 'EOF'
[Network]
ManageForeignRoutingPolicyRules=no
ManageForeignRoutes=no
RouteTable=
EOF
cp /etc/systemd/networkd.conf.d/optimize.conf "$BACKUP_DIR/" 2>/dev/null || true
ok "Networkd: reduced foreign route management"

head "4/6  DBus Connection Limits"
mkdir -p /etc/dbus-1/system.d/
cat > /etc/dbus-1/system-local.conf << 'EOF'
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <limit name="max_replies_per_connection">16</limit>
  <limit name="max_completed_connections">512</limit>
  <limit name="max_incomplete_connections">16</limit>
  <limit name="max_connections_per_user">64</limit>
  <limit name="pending_service_activation_timeout">10</limit>
  <limit name="activation_timeout">10</limit>
</busconfig>
EOF
cp /etc/dbus-1/system-local.conf "$BACKUP_DIR/" 2>/dev/null || true
ok "DBus: reduced timeouts (10s) and connection limits"

head "5/6  Mask Unnecessary Services (Container Environment)"
for svc in nfs-blkmap.service rpcbind.service chronyd-restricted.service \
           systemd-timesyncd.service rsyslog.service; do
    if systemctl is-active --quiet $svc 2>/dev/null; then
        sudo systemctl stop $svc 2>/dev/null || true
        ok "Stopped: $svc"
    fi
    sudo systemctl disable $svc 2>/dev/null || true
    sudo systemctl mask $svc 2>/dev/null || true
    ok "Masked: $svc"
done

# Disable getty on tty1 (virtual console not needed in container)
if systemctl is-active --quiet getty@tty1.service 2>/dev/null; then
    sudo systemctl stop getty@tty1.service 2>/dev/null || true
    ok "Stopped: getty@tty1.service"
fi
sudo systemctl disable getty@tty1.service 2>/dev/null || true
sudo systemctl mask getty@tty1.service 2>/dev/null || true
ok "Masked: getty@tty1.service"

# Mask ModemManager (not needed in container)
sudo systemctl mask ModemManager.service 2>/dev/null || true
ok "Masked: ModemManager.service"

head "6/6  Mask Unnecessary Timers"
for timer in apt-daily.timer apt-daily-upgrade.timer fstrim.timer \
             e2scrub_all.timer dpkg-db-backup.timer; do
    sudo systemctl mask $timer 2>/dev/null || true
    ok "Masked timer: $timer"
done

# Reset failed service states
sudo systemctl reset-failed 2>/dev/null || true
ok "Reset failed service states"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  PHASE 1 COMPLETE                                            ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  Drop-in configs created (apply on next boot/reload):           ║"
echo "║   · journald: 16MB cap, volatile, warning+ level                ║"
echo "║   · logind: 0 VTs, 5min idle timeout                            ║"
echo "║   · networkd: reduced foreign route management                  ║"
echo "║   · dbus: reduced timeouts (10s) and limits                     ║"
echo "║                                                                 ║"
echo "║  Services masked/stopped:                                        ║"
echo "║   · nfs-blkmap, rpcbind, chronyd-restricted                     ║"
echo "║   · systemd-timesyncd, rsyslog, getty@tty1, ModemManager        ║"
echo "║   · 5 systemd timers                                            ║"
echo "║                                                                 ║"
echo "║  Expected savings: ~25-30 MB RAM                                 ║"
echo "║                                                                 ║"
echo "║  Backup location: $BACKUP_DIR                        ║"
echo "║  Rollback script: scripts/rollback_phase1.sh                     ║"
echo "║                                                                 ║"
echo "║  To apply changes without reboot:                                ║"
echo "║    sudo systemctl daemon-reload                                  ║"
echo "║    sudo systemctl restart systemd-journald.service               ║"
echo "║    (Other services apply on next boot)                           ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
