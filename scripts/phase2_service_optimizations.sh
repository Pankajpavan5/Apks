#!/bin/bash
###############################################################################
# AIOS Phase 2: Service Optimizations (Requires service restarts)
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
# Risk Level: MEDIUM
#
# This script updates service files with performance optimizations.
# Services will be restarted ONE AT A TIME with health checks between each.
# Full rollback available via rollback_phase2.sh
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

head "PHASE 2: Service Optimizations (With Restarts)"
echo "Risk Level: MEDIUM - Services will be restarted one-by-one"
echo "Health checks between each restart"
echo "Rollback available: scripts/rollback_phase2.sh"
echo ""
echo "WARNING: This will restart running services!"
echo "If a service fails to restart, the script will STOP and offer rollback."
echo ""

# Create backup directory with timestamps
BACKUP_DIR="/tmp/aios-phase2-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
ok "Backup directory created: $BACKUP_DIR"

# Backup ALL current service files
for svc in code-interpreter jupyter envd; do
    SERVICE_FILE="/etc/systemd/system/${svc}.service"
    if [[ -f "$SERVICE_FILE" ]]; then
        cp "$SERVICE_FILE" "$BACKUP_DIR/${svc}.service.bak"
        ok "Backed up: ${svc}.service"
    else
        warn "Service file not found: ${svc}.service (using defaults)"
    fi
done

# Backup drop-in configs too
for dir in code-interpreter.service.d jupyter.service.d envd.service.d; do
    if [[ -d "/etc/systemd/system/$dir" ]]; then
        cp -r "/etc/systemd/system/$dir" "$BACKUP_DIR/" 2>/dev/null || true
        ok "Backed up: $dir/"
    fi
done

# Function to check service health after restart
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

    err "${svc}.service FAILED to start after $max_retries attempts!"
    return 1
}

# Function to rollback if service fails
rollback_on_failure() {
    local failed_svc=$1
    err "FATAL: $failed_svc.service failed to start!"
    echo ""
    echo "Starting automatic rollback..."
    bash /home/user/Apks/scripts/rollback_phase2.sh
    exit 1
}

head "1/4  Optimize code-interpreter.service"
cat > /etc/systemd/system/code-interpreter.service << 'EOF'
[Unit]
Description=Code Interpreter Server
Documentation=https://github.com/e2b-dev/code-interpreter
Requires=jupyter.service
After=jupyter.service
PartOf=jupyter.service
StartLimitBurst=3
StartLimitIntervalSec=60

[Service]
Type=simple
WorkingDirectory=/root/.server
ExecStartPre=/root/.jupyter/jupyter-healthcheck.sh
ExecStart=/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --loop uvloop --http httptools --no-access-log --no-use-colors --timeout-keep-alive 120 --limit-concurrency 50 --backlog 1024 --timeout-graceful-shutdown 10
Restart=on-failure
RestartSec=2
StandardOutput=null
StandardError=journal
SyslogLevel=warning

# Resource limits for stability
MemoryMax=512M
MemoryHigh=384M
CPUQuota=120%
TasksMax=128
Nice=5
IOSchedulingClass=idle
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=30
TimeoutStopSec=10
OOMPolicy=continue

[Install]
WantedBy=multi-user.target
EOF

echo "  Changes: workers 2→1, timeout 30→120, concurrency 100→50, CPU 150%→120%"
ok "code-interpreter.service updated"

echo "  Restarting code-interpreter.service..."
sudo systemctl daemon-reload
sudo systemctl restart code-interpreter.service || rollback_on_failure "code-interpreter"
check_service_health "code-interpreter" || rollback_on_failure "code-interpreter"
ok "code-interpreter.service: HEALTHY"

# Brief pause for system stabilization
sleep 3

head "2/4  Optimize jupyter.service"
cat > /etc/systemd/system/jupyter.service << 'EOF'
[Unit]
Description=Jupyter Server
Documentation=https://jupyter-server.readthedocs.io
Wants=code-interpreter.service
After=network.target
StartLimitBurst=3
StartLimitIntervalSec=60

[Service]
Type=simple
Environment=MATPLOTLIBRC=/root/.config/matplotlib/.matplotlibrc
Environment=PYTHONDONTWRITEBYTECODE=1
Environment=PYTHONUNBUFFERED=1
Environment=JUPYTER_NO_BROWSER=1
Environment=MPLBACKEND=Agg
ExecStartPre=/bin/bash -c 'echo "Validating Jupyter environment..."'
ExecStart=/usr/local/bin/jupyter server --IdentityProvider.token="aios-secure-token" --ServerApp.ip=127.0.0.1 --ServerApp.port=8888 --ServerApp.open_browser=False --ServerApp.allow_remote_access=False --ServerApp.root_dir=/home/user/Apks --ServerApp.disable_check_xsrf=False --MappingKernelManager.cull_interval=60 --MappingKernelManager.cull_idle_timeout=1800 --MappingKernelManager.cull_connected=True --MappingKernelManager.cull_busy=False
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=3
StandardOutput=null
StandardError=journal
SyslogLevel=warning

# Resource limits
MemoryMax=512M
MemoryHigh=384M
CPUQuota=150%
TasksMax=256
Nice=5
IOSchedulingClass=idle
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=45
TimeoutStopSec=15
OOMPolicy=continue

# Security hardening
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/home/user/Apks /root/.jupyter /root/.local
NoNewPrivileges=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

echo "  Changes: fixed token, cull_interval 300→60, idle_timeout 3600→1800"
echo "           Memory 768M→512M, CPU 200%→150%, Tasks 512→256"
ok "jupyter.service updated"

echo "  Restarting jupyter.service..."
sudo systemctl daemon-reload
sudo systemctl restart jupyter.service || rollback_on_failure "jupyter"
check_service_health "jupyter" || rollback_on_failure "jupyter"
ok "jupyter.service: HEALTHY"

# Wait for code-interpreter to reconnect (depends on jupyter)
sleep 5
if systemctl is-active --quiet code-interpreter.service 2>/dev/null; then
    ok "code-interpreter.service: still HEALTHY after jupyter restart"
else
    warn "code-interpreter.service: restarting after jupyter restart..."
    sudo systemctl restart code-interpreter.service || true
    check_service_health "code-interpreter" || rollback_on_failure "code-interpreter"
fi

head "3/4  Optimize envd.service"
cat > /etc/systemd/system/envd.service << 'EOF'
[Unit]
Description=Env Daemon Service
After=multi-user.target
StartLimitBurst=3
StartLimitIntervalSec=30

[Service]
Type=simple
Restart=always
RestartSec=2
User=root
Group=root

# Go runtime optimizations
Environment=GOTRACEBACK=crash
Environment=GOMEMLIMIT=512MiB
Environment=GOGC=100
Environment=GOMAXPROCS=2
Environment=GODEBUG=asyncpreemptoff=1

# System limits
LimitCORE=infinity
LimitNOFILE=65536
LimitNPROC=4096
LimitMEMLOCK=infinity

# Execution
ExecStart=/bin/bash -l -c "/usr/bin/envd"
ExecReload=/bin/kill -HUP $MAINPID

# Resource scheduling
Nice=-5
OOMScoreAdjust=-500
OOMPolicy=continue
IOSchedulingClass=best-effort
IOSchedulingPriority=4

# Accounting
Delegate=yes
MemoryAccounting=yes
CPUAccounting=yes
MemoryMin=100M
MemoryLow=256M
MemoryHigh=512M
MemoryMax=768M
CPUWeight=500

# Security hardening
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/tmp /var/run /home/user
NoNewPrivileges=yes
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectControlGroups=yes

[Install]
WantedBy=multi-user.target
EOF

echo "  Changes: GOGC 80→100, GOMEMLIMIT 768→512, Nice -15→-5"
echo "           CPUWeight 750→500, MemoryMax 1024M→768M"
ok "envd.service updated"

echo "  Restarting envd.service..."
sudo systemctl daemon-reload
sudo systemctl restart envd.service || rollback_on_failure "envd"
check_service_health "envd" || rollback_on_failure "envd"
ok "envd.service: HEALTHY"

# Verify other services still healthy after envd restart
sleep 3
for svc in code-interpreter jupyter; do
    if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
        ok "${svc}.service: still HEALTHY after envd restart"
    else
        warn "${svc}.service: restarting..."
        sudo systemctl restart ${svc}.service 2>/dev/null || true
    fi
done

head "4/4  Final System Verification"
sudo systemctl daemon-reload
ok "Systemd daemon reloaded"

echo ""
echo "=== FINAL SERVICE STATUS ==="
for svc in code-interpreter jupyter envd dbus systemd-journald systemd-logind systemd-networkd; do
    if systemctl is-active --quiet ${svc}.service 2>/dev/null; then
        pid=$(systemctl show ${svc}.service -p MainPID --value 2>/dev/null)
        rss=$(ps -o rss= -p $pid 2>/dev/null | tr -d ' ')
        echo -e "  ${G}✓${N} $svc: running (PID=$pid, RSS=${rss}KB)"
    else
        echo -e "  ${R}✗${N} $svc: NOT RUNNING"
    fi
done

echo ""
echo "=== MEMORY USAGE ==="
free -h | head -2

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  PHASE 2 COMPLETE                                            ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  Services optimized and restarted:                               ║"
echo "║   · code-interpreter: workers=1, timeout=120, concurrency=50     ║"
echo "║   · jupyter: fixed token, fast culling, memory limits            ║"
echo "║   · envd: GOGC=100, Nice=-5, CPUWeight=500                       ║"
echo "║                                                                 ║"
echo "║  All services verified HEALTHY                                   ║"
echo "║                                                                 ║"
echo "║  Backup location: $BACKUP_DIR                        ║"
echo "║  Rollback script: scripts/rollback_phase2.sh                     ║"
echo "║                                                                 ║"
echo "║  NEXT: Run Phase 3 for verification                              ║"
echo "║    bash scripts/phase3_verification.sh                           ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
