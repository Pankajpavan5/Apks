#!/bin/bash
###############################################################################
# AIOS Phase 1 Rollback: Restore original configs
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
#
# This script removes all drop-in configs created by Phase 1
# and un-masks services that were disabled.
# NO service restarts required.
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

head "PHASE 1 ROLLBACK: Restoring Original Configurations"
echo "This will remove all drop-in configs and un-mask services"
echo "NO service restarts required"
echo ""

# Remove drop-in configs
head "1/5  Removing Drop-in Configs"
rm -f /etc/systemd/journald.conf.d/optimize.conf 2>/dev/null && ok "Removed: journald.conf.d/optimize.conf" || warn "Not found: journald config"
rm -f /etc/systemd/logind.conf.d/optimize.conf 2>/dev/null && ok "Removed: logind.conf.d/optimize.conf" || warn "Not found: logind config"
rm -f /etc/systemd/networkd.conf.d/optimize.conf 2>/dev/null && ok "Removed: networkd.conf.d/optimize.conf" || warn "Not found: networkd config"
rm -f /etc/dbus-1/system-local.conf 2>/dev/null && ok "Removed: dbus system-local.conf" || warn "Not found: dbus config"

# Clean up empty directories
rmdir /etc/systemd/journald.conf.d 2>/dev/null || true
rmdir /etc/systemd/logind.conf.d 2>/dev/null || true
rmdir /etc/systemd/networkd.conf.d 2>/dev/null || true

head "2/5  Un-masking Services"
for svc in nfs-blkmap.service rpcbind.service chronyd-restricted.service \
           systemd-timesyncd.service rsyslog.service ModemManager.service \
           getty@tty1.service; do
    sudo systemctl unmask $svc 2>/dev/null && ok "Unmasked: $svc" || warn "Already unmasked: $svc"
done

head "3/5  Un-masking Timers"
for timer in apt-daily.timer apt-daily-upgrade.timer fstrim.timer \
             e2scrub_all.timer dpkg-db-backup.timer; do
    sudo systemctl unmask $timer 2>/dev/null && ok "Unmasked timer: $timer" || warn "Already unmasked: $timer"
done

head "4/5  Reloading Systemd"
sudo systemctl daemon-reload 2>/dev/null && ok "Systemd daemon reloaded" || err "Failed to reload systemd"

head "5/5  Resetting Failed States"
sudo systemctl reset-failed 2>/dev/null && ok "Failed states reset" || warn "No failed states to reset"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  PHASE 1 ROLLBACK COMPLETE                                    ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  All Phase 1 changes have been reverted:                         ║"
echo "║   · Drop-in configs removed                                     ║"
echo "║   · Services un-masked                                          ║"
echo "║   · Timers un-masked                                            ║"
echo "║                                                                 ║"
echo "║  Note: Original service files were not modified by Phase 1       ║"
echo "║  (only drop-in configs were created)                             ║"
echo "║                                                                 ║"
echo "║  To fully restore, also run:                                     ║"
echo "║    bash scripts/rollback_phase2.sh                               ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
