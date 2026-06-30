#!/bin/bash
###############################################################################
# AIOS Master Orchestrator: Run All Optimization Phases
# Agent: agent_173 (FORGE)
# Date: 2026-06-30
#
# This script runs all optimization phases in order with safety checks.
# Phases:
#   Phase 0: Pre-flight health check (MUST pass)
#   Phase 1: Safe optimizations (no restarts)
#   Phase 2: Service optimizations (with restarts)
#   Phase 3: Verification & metrics
#
# Rollback scripts are available for each phase.
###############################################################################
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}!${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
head() { echo -e "\n${B}══ $1 ══${N}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
RUN_PHASE0=true
RUN_PHASE1=true
RUN_PHASE2=true
RUN_PHASE3=true
DRY_RUN=false
VERBOSE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-phase0    Skip pre-flight checks"
    echo "  --skip-phase1    Skip safe optimizations"
    echo "  --skip-phase2    Skip service optimizations"
    echo "  --skip-phase3    Skip verification"
    echo "  --dry-run        Show what would be done without executing"
    echo "  --verbose        Show detailed output"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash $0                    # Run all phases"
    echo "  bash $0 --skip-phase2      # Run phases 0, 1, 3 only"
    echo "  bash $0 --dry-run          # Preview without executing"
    echo "  bash $0 --skip-phase0 --skip-phase3  # Run only phases 1 and 2"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-phase0) RUN_PHASE0=false; shift ;;
        --skip-phase1) RUN_PHASE1=false; shift ;;
        --skip-phase2) RUN_PHASE2=false; shift ;;
        --skip-phase3) RUN_PHASE3=false; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

head "AIOS SYSTEM OPTIMIZATION - Master Orchestrator"
echo "Agent: agent_173 (FORGE)"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
    if [[ "$RUN_PHASE0" == "true" ]]; then
        echo "  Phase 0: Pre-flight health check"
        echo "    Command: bash $SCRIPT_DIR/phase0_preflight_check.sh"
    fi
    if [[ "$RUN_PHASE1" == "true" ]]; then
        echo "  Phase 1: Safe optimizations (no restarts)"
        echo "    Command: bash $SCRIPT_DIR/phase1_safe_optimizations.sh"
    fi
    if [[ "$RUN_PHASE2" == "true" ]]; then
        echo "  Phase 2: Service optimizations (with restarts)"
        echo "    Command: bash $SCRIPT_DIR/phase2_service_optimizations.sh"
    fi
    if [[ "$RUN_PHASE3" == "true" ]]; then
        echo "  Phase 3: Verification & metrics"
        echo "    Command: bash $SCRIPT_DIR/phase3_verification.sh"
    fi
    echo ""
    echo "Dry run complete. Remove --dry-run to execute."
    exit 0
fi

# Phase 0: Pre-flight checks
if [[ "$RUN_PHASE0" == "true" ]]; then
    head "PHASE 0: Pre-flight Health Check"
    echo "Running system health checks..."
    if bash "$SCRIPT_DIR/phase0_preflight_check.sh"; then
        ok "Phase 0: PASSED - System is ready for optimization"
    else
        err "Phase 0: FAILED - System health check failed!"
        echo ""
        echo "❌ Optimization aborted due to pre-flight check failures."
        echo "   Fix the issues reported above before re-running."
        exit 1
    fi
    sleep 2
else
    warn "Phase 0: SKIPPED (pre-flight checks disabled)"
fi

# Phase 1: Safe optimizations
if [[ "$RUN_PHASE1" == "true" ]]; then
    head "PHASE 1: Safe Optimizations (No Restarts)"
    echo "Applying safe configuration changes..."
    if bash "$SCRIPT_DIR/phase1_safe_optimizations.sh"; then
        ok "Phase 1: COMPLETE - Safe optimizations applied"
    else
        err "Phase 1: FAILED - Safe optimizations had errors!"
        echo ""
        warn "Phase 2 will be skipped due to Phase 1 failure."
        RUN_PHASE2=false
    fi
    sleep 3
else
    warn "Phase 1: SKIPPED (safe optimizations disabled)"
fi

# Phase 2: Service optimizations
if [[ "$RUN_PHASE2" == "true" ]]; then
    head "PHASE 2: Service Optimizations (With Restarts)"
    echo "Updating and restarting services..."
    echo ""
    echo "⚠️  WARNING: Services will be restarted!"
    echo "   This may cause brief interruptions to running tasks."
    echo ""

    if bash "$SCRIPT_DIR/phase2_service_optimizations.sh"; then
        ok "Phase 2: COMPLETE - Services optimized and restarted"
    else
        err "Phase 2: FAILED - Service optimization had errors!"
        echo ""
        warn "Phase 3 will be skipped due to Phase 2 failure."
        warn "Consider running rollback: bash $SCRIPT_DIR/rollback_phase2.sh"
        RUN_PHASE3=false
    fi
    sleep 3
else
    warn "Phase 2: SKIPPED (service optimizations disabled)"
fi

# Phase 3: Verification
if [[ "$RUN_PHASE3" == "true" ]]; then
    head "PHASE 3: Verification & Metrics"
    echo "Verifying all optimizations..."
    if bash "$SCRIPT_DIR/phase3_verification.sh"; then
        ok "Phase 3: COMPLETE - Verification finished"
    else
        warn "Phase 3: COMPLETED WITH WARNINGS"
        echo "   Review the verification report for details."
    fi
else
    warn "Phase 3: SKIPPED (verification disabled)"
fi

# Final summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  ✅  ALL PHASES COMPLETE                                          ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║                                                                 ║"
echo "║  Phases executed:                                                ║"
if [[ "$RUN_PHASE0" == "true" ]]; then echo "║   ✓ Phase 0: Pre-flight checks                                  ║"; fi
if [[ "$RUN_PHASE1" == "true" ]]; then echo "║   ✓ Phase 1: Safe optimizations                                 ║"; fi
if [[ "$RUN_PHASE2" == "true" ]]; then echo "║   ✓ Phase 2: Service optimizations                                ║"; fi
if [[ "$RUN_PHASE3" == "true" ]]; then echo "║   ✓ Phase 3: Verification                                       ║"; fi
echo "║                                                                 ║"
echo "║  Rollback scripts available:                                     ║"
echo "║   · bash scripts/rollback_phase1.sh                             ║"
echo "║   · bash scripts/rollback_phase2.sh                             ║"
echo "║                                                                 ║"
echo "║  Performance report: /tmp/aios-phase3-report-*.md               ║"
echo "║                                                                 ║"
echo "║  To re-run optimization:                                         ║"
echo "║   · Rollback first, then run: bash scripts/run_all_phases.sh    ║"
echo "║                                                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
