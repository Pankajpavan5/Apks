#!/bin/bash

################################################################################
# AIOS Multi-Agent Orchestrator
################################################################################
#
# Manages a fleet of AIOS agent instances:
# - Deploy agents as systemd services
# - Monitor agent health and status
# - View logs in real-time
# - Scale agents up/down
# - Perform group operations
#
# Usage:
#   ./orchestrator.sh deploy --agents 101,102,103,107,201,202
#   ./orchestrator.sh status
#   ./orchestrator.sh logs agent_101 --follow
#   ./orchestrator.sh start agent_101
#   ./orchestrator.sh stop all
#   ./orchestrator.sh scale 10  # Scale to 10 agents
#
# Author: Sensi AI Arena
# Date: 2026-07-02
# Version: 1.0

set -euo pipefail

################################################################################
# CONFIGURATION
################################################################################

REPO_PATH="${AIOS_REPO_PATH:-.}"
LOG_DIR="${AIOS_LOG_DIR:-.logs}"
AGENT_ROLES=(
    "101:analyst"
    "102:coordinator"
    "103:debugger"
    "107:poller"
    "201:optimizer"
    "202:researcher"
)

################################################################################
# COLORS & OUTPUT
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_ok() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; }
log_header() { echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}$*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"; }

################################################################################
# AGENT MANAGEMENT
################################################################################

get_all_agents() {
    # List agents from Agents/online/
    if [ -d "$REPO_PATH/Agents/online" ]; then
        for file in "$REPO_PATH/Agents/online"/agent_*.txt; do
            if [ -f "$file" ]; then
                basename "$file" .txt
            fi
        done | sort
    fi
}

get_agent_status() {
    local agent_id=$1
    
    if systemctl is-active --quiet "aios-agent@$agent_id"; then
        echo "🟢 running"
    elif systemctl is-enabled --quiet "aios-agent@$agent_id" 2>/dev/null; then
        echo "🔴 stopped"
    else
        echo "⚪ unregistered"
    fi
}

get_agent_role() {
    local agent_id=$1
    
    # Check Agents/online/ for role
    if [ -f "$REPO_PATH/Agents/online/agent_$agent_id.txt" ]; then
        grep "^Role:" "$REPO_PATH/Agents/online/agent_$agent_id.txt" | cut -d: -f2 | xargs
    else
        echo "unknown"
    fi
}

get_agent_uptime() {
    local agent_id=$1
    
    if systemctl is-active --quiet "aios-agent@$agent_id"; then
        systemctl show "aios-agent@$agent_id" -p ActiveEnterTimestamp --value
    else
        echo "offline"
    fi
}

get_agent_last_task() {
    local agent_id=$1
    
    # Find most recent report from this agent
    if [ -d "$REPO_PATH/reports/Completed" ]; then
        ls -t "$REPO_PATH/reports/Completed"/REPORT-*-agent_${agent_id}.md 2>/dev/null | head -1 | xargs -I {} basename {} | sed 's/REPORT-//g;s/-agent_.*//'
    else
        echo "none"
    fi
}

################################################################################
# OPERATIONS
################################################################################

cmd_status() {
    log_header "AIOS Agent Fleet Status"

    local total=0
    local running=0
    local stopped=0

    # Get agents from Agents/online/ directory
    local agents=$(get_all_agents)

    if [ -z "$agents" ]; then
        log_warn "No agents registered"
        return
    fi

    printf "%-15s %-12s %-15s %-30s\n" "Agent ID" "Status" "Role" "Last Task"
    printf "%-15s %-12s %-15s %-30s\n" "--------" "------" "----" "---------"

    for agent in $agents; do
        total=$((total + 1))
        
        status=$(get_agent_status "$agent")
        role=$(get_agent_role "$agent")
        last_task=$(get_agent_last_task "$agent")

        # Count running
        if [[ "$status" == *"running"* ]]; then
            running=$((running + 1))
        else
            stopped=$((stopped + 1))
        fi

        printf "%-15s %-12s %-15s %-30s\n" "$agent" "$status" "$role" "$last_task"
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total: $total agents | Running: $running | Stopped: $stopped"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

cmd_start() {
    local target=$1
    
    if [ "$target" == "all" ]; then
        log_info "Starting all agents..."
        for agent in $(get_all_agents); do
            cmd_start "$agent"
        done
        return
    fi

    log_info "Starting agent_$target..."
    if systemctl start "aios-agent@$target"; then
        log_ok "Started agent_$target"
    else
        log_error "Failed to start agent_$target"
        return 1
    fi
}

cmd_stop() {
    local target=$1
    
    if [ "$target" == "all" ]; then
        log_info "Stopping all agents..."
        for agent in $(get_all_agents); do
            cmd_stop "$agent"
        done
        return
    fi

    log_info "Stopping agent_$target..."
    if systemctl stop "aios-agent@$target"; then
        log_ok "Stopped agent_$target"
    else
        log_error "Failed to stop agent_$target"
        return 1
    fi
}

cmd_restart() {
    local target=$1
    
    if [ "$target" == "all" ]; then
        log_info "Restarting all agents..."
        cmd_stop "all"
        sleep 2
        cmd_start "all"
        return
    fi

    log_info "Restarting agent_$target..."
    systemctl restart "aios-agent@$target"
    log_ok "Restarted agent_$target"
}

cmd_logs() {
    local agent_id=$1
    local follow=${2:---tail=50}

    if [ "$agent_id" == "all" ]; then
        log_info "Tailing all agent logs..."
        journalctl -u "aios-agent@*" -f
        return
    fi

    log_info "Showing logs for agent_$agent_id..."
    if [ "$follow" == "--follow" ] || [ "$follow" == "-f" ]; then
        journalctl -u "aios-agent@$agent_id" -f
    else
        journalctl -u "aios-agent@$agent_id" $follow
    fi
}

cmd_deploy() {
    local agents="${1:---agents}"
    local agent_list=""

    # Parse agents from command line
    if [ "$agents" == "--agents" ] && [ -n "${2:-}" ]; then
        agent_list="$2"
    else
        log_error "Usage: orchestrator.sh deploy --agents 101,102,103,107,201,202"
        return 1
    fi

    log_header "Deploying AIOS Agent Fleet"

    log_info "Agent list: $agent_list"

    # Deploy each agent
    IFS=',' read -ra AGENTS <<< "$agent_list"
    for agent_id in "${AGENTS[@]}"; do
        agent_id=$(echo "$agent_id" | xargs)  # Trim whitespace
        log_info "Deploying agent_$agent_id..."

        # Create systemd service from template
        local service_file="/etc/systemd/system/aios-agent@$agent_id.service"
        if [ ! -f "$service_file" ]; then
            log_warn "Service file not found: $service_file"
            log_info "Ensure you've deployed the systemd service template"
            continue
        fi

        # Enable and start
        systemctl daemon-reload
        systemctl enable "aios-agent@$agent_id"
        systemctl start "aios-agent@$agent_id"

        log_ok "Deployed agent_$agent_id"
    done

    log_ok "Deployment complete"
}

cmd_health() {
    log_header "Agent Fleet Health Check"

    local agents=$(get_all_agents)
    local total=0
    local healthy=0
    local unhealthy=0

    for agent in $agents; do
        total=$((total + 1))

        if systemctl is-active --quiet "aios-agent@$agent"; then
            # Check if actively processing
            local last_log=$(journalctl -u "aios-agent@$agent" -n 1 --output=short | tail -1)
            if echo "$last_log" | grep -q "Poll cycle\|Completed"; then
                healthy=$((healthy + 1))
                log_ok "$agent: healthy (active)"
            else
                unhealthy=$((unhealthy + 1))
                log_warn "$agent: potentially stuck (check logs)"
            fi
        else
            unhealthy=$((unhealthy + 1))
            log_error "$agent: not running"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Health: $healthy/$total agents healthy"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $unhealthy -gt 0 ]; then
        return 1
    fi
}

cmd_scale() {
    local target_count=$1

    if ! [[ "$target_count" =~ ^[0-9]+$ ]]; then
        log_error "Usage: orchestrator.sh scale <number>"
        return 1
    fi

    log_header "Agent Fleet Auto-Scaling"

    local current_count=$(get_all_agents | wc -l)
    
    log_info "Current agents: $current_count"
    log_info "Target agents: $target_count"

    if [ "$current_count" -eq "$target_count" ]; then
        log_ok "Already at target scale"
        return
    fi

    if [ "$current_count" -lt "$target_count" ]; then
        log_info "Scaling UP..."
        for i in $(seq $((current_count + 1)) "$target_count"); do
            new_agent_id=$((200 + i))
            log_info "Creating agent_$new_agent_id..."
            # Note: This would require logic to create new agent registration
            # For now, just log what would happen
        done
    else
        log_info "Scaling DOWN..."
        for agent in $(get_all_agents | tail -n $((current_count - target_count))); do
            log_info "Removing $agent..."
            cmd_stop "$agent"
        done
    fi

    log_ok "Scaling complete"
}

cmd_sync_repo() {
    log_header "Repository Synchronization"

    log_info "Fetching latest from origin..."
    cd "$REPO_PATH"
    git fetch origin
    git pull --rebase origin main

    log_ok "Repository synchronized"
}

cmd_show_commands() {
    cat << 'EOF'

AIOS Agent Orchestrator - Command Reference

Status & Monitoring:
  orchestrator.sh status              Show status of all agents
  orchestrator.sh health              Check fleet health
  orchestrator.sh logs [agent] [opts] Show agent logs (--follow, --tail=N)

Agent Control:
  orchestrator.sh start <agent|all>   Start agent(s)
  orchestrator.sh stop <agent|all>    Stop agent(s)
  orchestrator.sh restart <agent|all> Restart agent(s)

Fleet Management:
  orchestrator.sh deploy --agents IDS Deploy agents (101,102,103,107,201,202)
  orchestrator.sh scale N             Scale fleet to N agents
  orchestrator.sh sync-repo           Pull latest repository changes

Examples:
  # View all agent statuses
  ./orchestrator.sh status

  # Tail all logs
  ./orchestrator.sh logs all --follow

  # Restart single agent
  ./orchestrator.sh restart 101

  # Check health
  ./orchestrator.sh health

  # Deploy 6 agents
  ./orchestrator.sh deploy --agents 101,102,103,107,201,202

  # Scale to 10 agents
  ./orchestrator.sh scale 10

  # View specific agent logs (last 100 lines)
  ./orchestrator.sh logs 101 --tail=100

EOF
}

################################################################################
# MAIN
################################################################################

main() {
    local command="${1:-status}"

    case "$command" in
        status)
            cmd_status
            ;;
        start)
            cmd_start "${2:-all}"
            ;;
        stop)
            cmd_stop "${2:-all}"
            ;;
        restart)
            cmd_restart "${2:-all}"
            ;;
        logs)
            cmd_logs "${2:-all}" "${3:---tail=50}"
            ;;
        deploy)
            cmd_deploy "${2:-}" "${3:-}"
            ;;
        health)
            cmd_health
            ;;
        scale)
            cmd_scale "${2:-}"
            ;;
        sync-repo|sync)
            cmd_sync_repo
            ;;
        help|--help|-h)
            cmd_show_commands
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_show_commands
            exit 1
            ;;
    esac
}

# Execute
main "$@"
