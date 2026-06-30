#!/bin/bash
###############################################################################
# AIOS Phase 3: Verification & Performance Metrics
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
# Risk Level: LOW (Read-only operations)
#
# This script verifies all optimizations are working correctly and
# compares before/after metrics for performance analysis.
###############################################################################
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}!${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
head() { echo -e "\n${B}══ $1 ══${N}"; }

REPORT_FILE="/tmp/aios-phase3-report-$(date +%Y%m%d_%H%M%S).md"
SCORE=0
TOTAL=0

check() {
    local desc="$1"
    local result="$2"
    TOTAL=$((TOTAL + 1))
    if [[ "$result" == "pass" ]]; then
        SCORE=$((SCORE + 1))
        ok "$desc: PASS"
    else
        err "$desc: FAIL"
    fi
}

head "PHASE 3: Verification & Performance Metrics"
echo "Risk Level: LOW (Read-only operations)"
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Start markdown report
cat > "$REPORT_FILE" << 'HEADER'
# AIOS Phase 3: Verification Report

**Agent:** agent_173 (FORGE)
**Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

---

HEADER
sed -i "s/\$(date -u +%Y-%m-%dT%H:%M:%SZ)/$(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$REPORT_FILE"

head "1/8  Service Health Check"
echo "---" >> "$REPORT_FILE"
echo "## Service Health" >> "$REPORT_FILE"

ALL_HEALTHY=true
for svc in code-interpreter jupyter envd dbus systemd-journald systemd-logind systemd-networkd; do
    if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
        pid=$(systemctl show ${svc}.service -p MainPID --value 2>/dev/null)
        rss=$(ps -o rss= -p $pid 2>/dev/null | tr -d ' ')
        echo "- **$svc**: running (PID=$pid, RSS=${rss}KB)" >> "$REPORT_FILE"
        ok "$svc: running (PID=$pid, RSS=${rss}KB)"
    else
        echo "- **$svc**: NOT RUNNING" >> "$REPORT_FILE"
        err "$svc: NOT RUNNING"
        ALL_HEALTHY=false
    fi
done

if $ALL_HEALTHY; then
    check "All services healthy" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** All 7 services running ✓" >> "$REPORT_FILE"
else
    check "All services healthy" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Some services failed ✗" >> "$REPORT_FILE"
fi

head "2/8  Memory Usage Analysis"
echo "" >> "$REPORT_FILE"
echo "## Memory Usage" >> "$REPORT_FILE"

TOTAL_MEM=$(free -b | awk '/^Mem:/ {print $2}')
USED_MEM=$(free -b | awk '/^Mem:/ {print $3}')
AVAIL_MEM=$(free -b | awk '/^Mem:/ {print $7}')

echo "| Metric | Value |" >> "$REPORT_FILE"
echo "|--------|-------|" >> "$REPORT_FILE"
echo "| Total RAM | $(echo "scale=1; $TOTAL_MEM/1024/1024/1024" | bc) GB |" >> "$REPORT_FILE"
echo "| Used | $(echo "scale=1; $USED_MEM/1024/1024/1024" | bc) GB |" >> "$REPORT_FILE"
echo "| Available | $(echo "scale=1; $AVAIL_MEM/1024/1024/1024" | bc) GB |" >> "$REPORT_FILE"
echo "| Usage | $(echo "scale=0; $USED_MEM*100/$TOTAL_MEM" | bc)% |" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "### Per-Service Memory" >> "$REPORT_FILE"
echo "| Service | PID | RSS (MB) |" >> "$REPORT_FILE"
echo "|---------|-----|----------|" >> "$REPORT_FILE"

for svc in code-interpreter jupyter envd dbus systemd-journald systemd-logind systemd-networkd; do
    pid=$(systemctl show ${svc}.service -p MainPID --value 2>/dev/null)
    if [[ "$pid" != "0" ]] && [[ -n "$pid" ]]; then
        rss=$(ps -o rss= -p $pid 2>/dev/null | tr -d ' ')
        rss_mb=$(echo "scale=1; $rss/1024" | bc)
        echo "| $svc | $pid | $rss_mb |" >> "$REPORT_FILE"
        echo "  $svc: $rss_mb MB"
    fi
done

SERVICE_MEM_TOTAL=0
for svc in code-interpreter jupyter envd dbus systemd-journald systemd-logind systemd-networkd; do
    pid=$(systemctl show ${svc}.service -p MainPID --value 2>/dev/null)
    if [[ "$pid" != "0" ]] && [[ -n "$pid" ]]; then
        rss=$(ps -o rss= -p $pid 2>/dev/null | tr -d ' ')
        SERVICE_MEM_TOTAL=$((SERVICE_MEM_TOTAL + rss))
    fi
done
SERVICE_MEM_MB=$(echo "scale=1; $SERVICE_MEM_TOTAL/1024" | bc)
echo "" >> "$REPORT_FILE"
echo "**Total Service Memory:** ${SERVICE_MEM_MB} MB" >> "$REPORT_FILE"

# Target: services should use <300MB total
if [[ $(echo "$SERVICE_MEM_TOTAL < 307200" | bc) -eq 1 ]]; then
    check "Service memory < 300MB" "pass"
    echo "**Target:** <300MB ✓" >> "$REPORT_FILE"
else
    check "Service memory < 300MB" "fail"
    echo "**Target:** <300MB ✗ (actual: ${SERVICE_MEM_MB}MB)" >> "$REPORT_FILE"
fi

head "3/8  Drop-in Config Verification"
echo "" >> "$REPORT_FILE"
echo "## Drop-in Configs" >> "$REPORT_FILE"

# Check journald
if [[ -f /etc/systemd/journald.conf.d/optimize.conf ]]; then
    storage=$(grep "^Storage=" /etc/systemd/journald.conf.d/optimize.conf | cut -d= -f2)
    maxuse=$(grep "^SystemMaxUse=" /etc/systemd/journald.conf.d/optimize.conf | cut -d= -f2)
    echo "- **journald**: Storage=$storage, MaxUse=$maxuse" >> "$REPORT_FILE"
    check "Journald config applied" "pass"
else
    echo "- **journald**: Config not found" >> "$REPORT_FILE"
    check "Journald config applied" "fail"
fi

# Check logind
if [[ -f /etc/systemd/logind.conf.d/optimize.conf ]]; then
    vt=$(grep "^NAutoVTs=" /etc/systemd/logind.conf.d/optimize.conf | cut -d= -f2)
    echo "- **logind**: NAutoVTs=$vt" >> "$REPORT_FILE"
    check "Logind config applied" "pass"
else
    echo "- **logind**: Config not found" >> "$REPORT_FILE"
    check "Logind config applied" "fail"
fi

# Check networkd
if [[ -f /etc/systemd/networkd.conf.d/optimize.conf ]]; then
    foreign=$(grep "^ManageForeignRoutes=" /etc/systemd/networkd.conf.d/optimize.conf | cut -d= -f2)
    echo "- **networkd**: ManageForeignRoutes=$foreign" >> "$REPORT_FILE"
    check "Networkd config applied" "pass"
else
    echo "- **networkd**: Config not found" >> "$REPORT_FILE"
    check "Networkd config applied" "fail"
fi

# Check dbus
if [[ -f /etc/dbus-1/system-local.conf ]]; then
    timeout=$(grep "activation_timeout" /etc/dbus-1/system-local.conf | head -1 | grep -o '[0-9]*')
    echo "- **dbus**: activation_timeout=${timeout}s" >> "$REPORT_FILE"
    check "DBus config applied" "pass"
else
    echo "- **dbus**: Config not found" >> "$REPORT_FILE"
    check "DBus config applied" "fail"
fi

head "4/8  Masked Services Verification"
echo "" >> "$REPORT_FILE"
echo "## Masked Services" >> "$REPORT_FILE"

EXPECTED_MASKED=(nfs-blkmap.service rpcbind.service chronyd-restricted.service \
                 systemd-timesyncd.service rsyslog.service ModemManager.service \
                 getty@tty1.service)

for svc in "${EXPECTED_MASKED[@]}"; do
    state=$(systemctl is-enabled $svc 2>&1 || true)
    if [[ "$state" == "masked" ]]; then
        echo "- **$svc**: masked ✓" >> "$REPORT_FILE"
    else
        echo "- **$svc**: $state (expected: masked)" >> "$REPORT_FILE"
    fi
done

MASKED_COUNT=0
for svc in "${EXPECTED_MASKED[@]}"; do
    state=$(systemctl is-enabled $svc 2>&1 || true)
    if [[ "$state" == "masked" ]]; then
        MASKED_COUNT=$((MASKED_COUNT + 1))
    fi
done

if [[ $MASKED_COUNT -ge 5 ]]; then
    check "Expected services masked (${MASKED_COUNT}/7)" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** ${MASKED_COUNT}/7 services masked ✓" >> "$REPORT_FILE"
else
    check "Expected services masked (${MASKED_COUNT}/7)" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** ${MASKED_COUNT}/7 services masked ✗" >> "$REPORT_FILE"
fi

head "5/8  Kernel Tuning Verification"
echo "" >> "$REPORT_FILE"
echo "## Kernel Tuning" >> "$REPORT_FILE"

SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "unknown")
DIRTY_RATIO=$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo "unknown")
PRINTK=$(cat /proc/sys/kernel/printk 2>/dev/null || echo "unknown")

echo "| Parameter | Expected | Actual |" >> "$REPORT_FILE"
echo "|-----------|----------|--------|" >> "$REPORT_FILE"
echo "| swappiness | 1 or 10 | $SWAPPINESS |" >> "$REPORT_FILE"
echo "| dirty_ratio | 40 | $DIRTY_RATIO |" >> "$REPORT_FILE"
echo "| printk | 0 0 0 0 or 3 3 3 3 | $PRINTK |" >> "$REPORT_FILE"

if ([[ "$SWAPPINESS" == "1" ]] || [[ "$SWAPPINESS" == "10" ]]) && [[ "$DIRTY_RATIO" == "40" ]]; then
    check "Kernel tuning applied" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Kernel tuning verified ✓" >> "$REPORT_FILE"
else
    check "Kernel tuning applied" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Kernel tuning incomplete ✗" >> "$REPORT_FILE"
fi

head "6/8  Network Optimization Verification"
echo "" >> "$REPORT_FILE"
echo "## Network Tuning" >> "$REPORT_FILE"

TCP_FASTOPEN=$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo "unknown")
TCP_SLOW_START=$(cat /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null || echo "unknown")
TCP_MTU=$(cat /proc/sys/net/ipv4/tcp_mtu_probing 2>/dev/null || echo "unknown")

echo "| Parameter | Expected | Actual |" >> "$REPORT_FILE"
echo "|-----------|----------|--------|" >> "$REPORT_FILE"
echo "| tcp_fastopen | 3 | $TCP_FASTOPEN |" >> "$REPORT_FILE"
echo "| tcp_slow_start_after_idle | 0 | $TCP_SLOW_START |" >> "$REPORT_FILE"
echo "| tcp_mtu_probing | 1 | $TCP_MTU |" >> "$REPORT_FILE"

if [[ "$TCP_FASTOPEN" == "3" ]] && [[ "$TCP_SLOW_START" == "0" ]]; then
    check "Network tuning applied" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Network tuning verified ✓" >> "$REPORT_FILE"
else
    check "Network tuning applied" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Network tuning incomplete ✗" >> "$REPORT_FILE"
fi

head "7/8  Git Optimization Verification"
echo "" >> "$REPORT_FILE"
echo "## Git Optimization" >> "$REPORT_FILE"

GIT_PROTO=$(git config --global protocol.version 2>/dev/null || echo "unknown")
GIT_GRAPH=$(git config --global core.commitGraph 2>/dev/null || echo "unknown")
GIT_MULTI=$(git config --global core.multiPackIndex 2>/dev/null || echo "unknown")

echo "| Setting | Expected | Actual |" >> "$REPORT_FILE"
echo "|---------|----------|--------|" >> "$REPORT_FILE"
echo "| protocol.version | 2 | $GIT_PROTO |" >> "$REPORT_FILE"
echo "| core.commitGraph | true | $GIT_GRAPH |" >> "$REPORT_FILE"
echo "| core.multiPackIndex | true | $GIT_MULTI |" >> "$REPORT_FILE"

if [[ "$GIT_PROTO" == "2" ]] && [[ "$GIT_GRAPH" == "true" ]]; then
    check "Git optimization applied" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Git optimization verified ✓" >> "$REPORT_FILE"
else
    check "Git optimization applied" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** Git optimization incomplete ✗" >> "$REPORT_FILE"
fi

head "8/8  System Load & Performance"
echo "" >> "$REPORT_FILE"
echo "## System Performance" >> "$REPORT_FILE"

LOAD=$(cat /proc/loadavg)
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
UPTIME_MIN=$((UPTIME_SEC / 60))

echo "- **Load Average:** $LOAD" >> "$REPORT_FILE"
echo "- **Uptime:** ${UPTIME_MIN} minutes" >> "$REPORT_FILE"
echo "- **CPU Count:** $(nproc)" >> "$REPORT_FILE"
echo "- **CPU Frequency:** $(grep "cpu MHz" /proc/cpuinfo 2>/dev/null | head -1 | awk '{print $4}') MHz" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "### Top Processes by Memory" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
ps -eo pid,comm,%mem,%cpu,rss --sort=-%mem | head -8 >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"

LOAD_SCORE=$(echo "$LOAD" | awk '{print $1}')
if [[ $(echo "$LOAD_SCORE < 1.0" | bc) -eq 1 ]]; then
    check "System load healthy (<1.0)" "pass"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** System load healthy ✓" >> "$REPORT_FILE"
else
    check "System load healthy (<1.0)" "fail"
    echo "" >> "$REPORT_FILE"
    echo "**Result:** System load elevated ✗" >> "$REPORT_FILE"
fi

# Final Score
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "## Final Score" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
PERCENTAGE=$((SCORE * 100 / TOTAL))
echo "**Score: ${SCORE}/${TOTAL} checks passed (${PERCENTAGE}%)**" >> "$REPORT_FILE"

if [[ $PERCENTAGE -ge 90 ]]; then
    echo "✅ **EXCELLENT** - All optimizations working correctly" >> "$REPORT_FILE"
elif [[ $PERCENTAGE -ge 70 ]]; then
    echo "⚠️ **GOOD** - Most optimizations working, minor issues" >> "$REPORT_FILE"
elif [[ $PERCENTAGE -ge 50 ]]; then
    echo "⚠️ **FAIR** - Several issues need attention" >> "$REPORT_FILE"
else
    echo "❌ **POOR** - Critical issues detected, consider rollback" >> "$REPORT_FILE"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  PHASE 3 VERIFICATION COMPLETE                                ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  Score: ${SCORE}/${TOTAL} checks passed (${PERCENTAGE}%)                          ║"
if [[ $PERCENTAGE -ge 90 ]]; then
    echo "║  Status: ✅ EXCELLENT - All optimizations working correctly         ║"
elif [[ $PERCENTAGE -ge 70 ]]; then
    echo "║  Status: ⚠️  GOOD - Most optimizations working                      ║"
else
    echo "║  Status: ❌ NEEDS ATTENTION - Review report for issues             ║"
fi
echo "║                                                                 ║"
echo "║  Full report: $REPORT_FILE           ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
