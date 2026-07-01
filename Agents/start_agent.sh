#!/bin/bash

################################################################################
# AIOS Agent Bot Starter Script
################################################################################
#
# Starts an AIOS agent bot with proper environment setup.
#
# Usage:
#   ./start_agent.sh --agent-id 101 --role analyst --loop
#   ./start_agent.sh --agent-id 201 --role optimizer --once
#   ./start_agent.sh --agent-id 102 --repo /path/to/repo --poll-interval 120
#
# Environment Variables:
#   GITHUB_TOKEN      - GitHub Personal Access Token (required)
#   AGENT_REPO        - Path to cloned repository (default: ./Apks)
#   AIOS_LOG_DIR      - Log directory (default: ./logs)
#   AIOS_DEBUG        - Enable debug mode (0/1)
#
# Author: Sensi AI Arena
# Date: 2026-07-02
# Version: 1.0

set -euo pipefail

################################################################################
# CONFIGURATION
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_REPO="${AGENT_REPO:-.}"
AIOS_LOG_DIR="${AIOS_LOG_DIR:-.logs}"
AIOS_DEBUG="${AIOS_DEBUG:-0}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

AGENT_ID=""
AGENT_ROLE=""
POLL_INTERVAL="60"
MODE="loop"  # loop, once, or cycles
CYCLES=""

################################################################################
# COLORS & OUTPUT
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_ok() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; }

################################################################################
# FUNCTIONS
################################################################################

show_usage() {
    cat << 'EOF'
AIOS Agent Bot Starter

Usage:
  ./start_agent.sh [OPTIONS]

Required Options:
  --agent-id ID               Agent ID (101, 102, 103, 107, 201, 202, etc.)

Optional Options:
  --role ROLE                 Agent role (analyst, optimizer, debugger, coordinator)
  --repo PATH                 Repository path (default: ./Apks)
  --poll-interval SECONDS     Polling interval (default: 60)
  --loop                      Run continuous polling loop (default)
  --once                      Run single poll cycle and exit
  --cycles N                  Run N cycles and exit
  --help                      Show this help message

Environment Variables:
  GITHUB_TOKEN                GitHub PAT (required, can also pass via --token)
  AGENT_REPO                  Repository path override
  AIOS_LOG_DIR                Log directory (default: ./logs)
  AIOS_DEBUG                  Enable debug output (0/1)

Examples:
  # Start agent 101 in continuous loop
  ./start_agent.sh --agent-id 101 --role analyst --loop

  # Start agent 201 for single execution
  ./start_agent.sh --agent-id 201 --role optimizer --once

  # Start with custom polling interval
  ./start_agent.sh --agent-id 107 --poll-interval 30 --loop

  # Run 5 cycles for testing
  ./start_agent.sh --agent-id 102 --cycles 5

EOF
}

validate_env() {
    log_info "Validating environment..."

    # Check GITHUB_TOKEN
    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GITHUB_TOKEN not set"
        echo "Set it with: export GITHUB_TOKEN='ghp_xxxxxx...'"
        exit 1
    fi

    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 not found"
        exit 1
    fi

    log_ok "Python: $(python3 --version)"

    # Check repository
    if [ ! -d "$AGENT_REPO" ]; then
        log_error "Repository not found: $AGENT_REPO"
        exit 1
    fi

    if [ ! -d "$AGENT_REPO/.git" ]; then
        log_error "Not a git repository: $AGENT_REPO"
        exit 1
    fi

    log_ok "Repository: $AGENT_REPO"

    # Check required directories
    for dir in task/Pending task/Assigned task/Working task/Verification task/Complete \
               memory message/Inbox message/Outbox reports/Completed Agents/online; do
        if [ ! -d "$AGENT_REPO/$dir" ]; then
            log_warn "Creating directory: $AGENT_REPO/$dir"
            mkdir -p "$AGENT_REPO/$dir"
        fi
    done

    log_ok "Environment validated"
}

setup_logging() {
    mkdir -p "$AIOS_LOG_DIR"

    LOG_FILE="$AIOS_LOG_DIR/agent_${AGENT_ID}_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "Logging to: $LOG_FILE"

    # Redirect output to log file (while also showing on terminal)
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent-id)
                AGENT_ID="$2"
                shift 2
                ;;
            --role)
                AGENT_ROLE="$2"
                shift 2
                ;;
            --repo)
                AGENT_REPO="$2"
                shift 2
                ;;
            --poll-interval)
                POLL_INTERVAL="$2"
                shift 2
                ;;
            --token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --loop)
                MODE="loop"
                shift
                ;;
            --once)
                MODE="once"
                shift
                ;;
            --cycles)
                MODE="cycles"
                CYCLES="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate required args
    if [ -z "$AGENT_ID" ]; then
        log_error "Missing required option: --agent-id"
        show_usage
        exit 1
    fi
}

run_agent_bot() {
    log_info "Starting agent bot..."
    log_info "  Agent ID: $AGENT_ID"
    log_info "  Role: ${AGENT_ROLE:-auto-detected}"
    log_info "  Repository: $AGENT_REPO"
    log_info "  Poll Interval: $POLL_INTERVAL seconds"
    log_info "  Mode: $MODE"

    # Build python arguments
    local py_args=(
        "$SCRIPT_DIR/agent_bot.py"
        "--agent-id" "$AGENT_ID"
        "--repo-path" "$AGENT_REPO"
        "--poll-interval" "$POLL_INTERVAL"
    )

    if [ -n "$AGENT_ROLE" ]; then
        py_args+=(--role "$AGENT_ROLE")
    fi

    case $MODE in
        loop)
            py_args+=(--loop)
            log_ok "Running in continuous loop mode (Ctrl+C to stop)"
            ;;
        once)
            py_args+=(--once)
            log_ok "Running single poll cycle"
            ;;
        cycles)
            if [ -z "$CYCLES" ]; then
                log_error "Cycles mode requires --cycles N"
                exit 1
            fi
            py_args+=(--cycles "$CYCLES")
            log_ok "Running $CYCLES cycles"
            ;;
    esac

    if [ "$AIOS_DEBUG" == "1" ]; then
        log_warn "Debug mode enabled"
        python3 "${py_args[@]}"
    else
        python3 "${py_args[@]}" 2>&1 || {
            log_error "Agent bot failed with exit code $?"
            exit $?
        }
    fi
}

print_banner() {
    cat << 'EOF'

████████████████████████████████████████████████████████████████████████████████
█                                                                              █
█  🤖 AIOS AGENT BOT STARTER                                                  █
█                                                                              █
█  Multi-Agent AI Arena - GitHub-Coordinated Execution                        █
█                                                                              █
████████████████████████████████████████████████████████████████████████████████

EOF
}

################################################################################
# MAIN
################################################################################

main() {
    print_banner

    # Parse command line arguments
    parse_args "$@"

    # Setup logging
    setup_logging

    log_ok "Agent Bot Starter v1.0"

    # Validate environment
    validate_env

    # Run agent bot
    run_agent_bot
}

# Trap signals for cleanup
trap 'log_warn "Received interrupt signal"; exit 130' SIGINT SIGTERM

# Execute main
main "$@"
