#!/bin/bash
###############################################################################
# AIOS Phase 0: Pre-flight System Health Check
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
# Risk Level: NONE (Read-only operations)
#
# This script checks system health BEFORE running any optimizations.
# If any critical check fails, the optimization process should be halted.
###############################################################################
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}!${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
head() { echo -e "\n${B}══ $1 ══${N}"; }

SCORE=0
TOTAL=0
CRITICAL_FAIL=false

check() {
    local desc="$1"
    local result="$2"
    local critical="${3:-false}"
    TOTAL=$((TOTAL + 1))
    if [[ "$result" == "pass" ]]; then
        SCORE=$((SCORE + 1))
        ok "$desc"
    else
        err "$desc"
        if [[ "$critical" == "true" ]]; then
            CRITICAL_FAIL=true
        fi
    fi
}

head "PHASE 0: Pre-flight System Health Check"
echo "Risk Level: NONE (Read-only operations)"
echo "This check MUST pass before running optimization phases"
echo ""

head "1/6  Root Access Check"
if [[ $EUID -eq 0 ]]; then
    check "Running as root" "pass" "true"
else
    check "Running as root" "fail" "true"
fi

head "2/6  Systemd Availability"
if command -v systemctl &>/dev/null; then
    check "systemctl available" "pass" "true"
else
    check "systemctl available" "fail" "true"
fi

head "3/6  Critical Services Running"
CRITICAL_SERVICES=(code-interpreter jupyter envd dbus systemd-networkd)
for svc in "${CRITICAL_SERVICES[@]}"; do
    if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
        check "$svc.service running" "pass" "true"
    else
        check "$svc.service running" "fail" "true"
    fi
done

head "4/6  Filesystem Write Access"
if touch /tmp/aios_write_test 2>/dev/null; then
    rm -f /tmp/aios_write_test
    check "/tmp writable" "pass" "true"
else
    check "/tmp writable" "fail" "true"
fi

if sudo touch /etc/aios_write_test 2>/dev/null; then
    sudo rm -f /etc/aios_write_test
    check "/etc writable (sudo)" "pass" "true"
else
    check "/etc writable (sudo)" "fail" "true"
fi

head "5/6  Memory Availability"
TOTAL_MEM=$(free -m | awk '/^Mem:/ {print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/ {print $7}')
echo "  Total RAM: ${TOTAL_MEM}MB"
echo "  Available RAM: ${AVAIL_MEM}MB"

if [[ $AVAIL_MEM -ge 512 ]]; then
    check "Sufficient RAM available (${AVAIL_MEM}MB >= 512MB)" "pass" "true"
else
    check "Sufficient RAM available (${AVAIL_MEM}MB < 512MB)" "fail" "true"
fi

head "6/6  Disk Space"
DISK_AVAIL=$(df -m / | awk 'NR==2 {print $4}')
echo "  Available disk: ${DISK_AVAIL}MB"

if [[ $DISK_AVAIL -ge 1024 ]]; then
    check "Sufficient disk space (${DISK_AVAIL}MB >= 1024MB)" "pass" "true"
else
    check "Sufficient disk space (${DISK_AVAIL}MB < 1024MB)" "fail" "true"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  PRE-FLIGHT CHECK RESULTS                                         ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"

PERCENTAGE=$((SCORE * 100 / TOTAL))
echo "║  Score: ${SCORE}/${TOTAL} checks passed (${PERCENTAGE}%)                          ║"

if [[ "$CRITICAL_FAIL" == "false" ]] && [[ $PERCENTAGE -ge 80 ]]; then
    echo "║  Status: ✅ READY FOR OPTIMIZATION                                  ║"
    echo "║                                                                 ║"
    echo "║  Next steps:                                                     ║"
    echo "║    Phase 1 (Safe):    bash scripts/phase1_safe_optimizations.sh  ║"
    echo "║    Phase 2 (Restart): bash scripts/phase2_service_optimizations.sh║"
    echo "║    Phase 3 (Verify):  bash scripts/phase3_verification.sh        ║"
    echo "║                                                                 ║"
    echo "║  Or run all phases:   bash scripts/run_all_phases.sh             ║"
else
    echo "║  Status: ❌ NOT READY - Fix issues before proceeding              ║"
    echo "║                                                                 ║"
    if [[ "$CRITICAL_FAIL" == "true" ]]; then
        echo "║  CRITICAL failures detected. Do NOT proceed with optimization. ║"
    else
        echo "║  Non-critical issues detected. Review before proceeding.       ║"
    fi
fi

echo "╚═══════════════════════════════════════════════════════════════════╝"

if [[ "$CRITICAL_FAIL" == "true" ]] || [[ $PERCENTAGE -lt 80 ]]; then
    exit 1
fi
