#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
##############################################################################
# ZeroClaw Mission Control — Health Check
# Verifies all services are running and responsive
##############################################################################

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/docker/.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

function check_pass() { echo -e "  ${GREEN}✅${NC} $1"; PASS=$((PASS + 1)); }
function check_fail() { echo -e "  ${RED}❌${NC} $1"; FAIL=$((FAIL + 1)); }
function check_warn() { echo -e "  ${YELLOW}⚠️${NC} $1"; WARN=$((WARN + 1)); }

function check_env_file() {
    echo "── Environment ──"
    if [[ -f "${ENV_FILE}" ]]; then
        check_pass ".env file exists"

        local perms
        perms="$(stat -c '%a' "${ENV_FILE}" 2>/dev/null || stat -f '%Lp' "${ENV_FILE}" 2>/dev/null)"
        if [[ "${perms}" == "600" ]]; then
            check_pass ".env permissions: ${perms}"
        else
            check_warn ".env permissions: ${perms} (expected 600)"
        fi

        # Check for placeholder values
        if grep -q 'REPLACE_ME\|REPLACE_WITH' "${ENV_FILE}" 2>/dev/null; then
            check_warn "Placeholder values found in .env — edit API keys"
        fi

        # Check that gateway token is set
        if grep -q '^ZEROCLAW_GATEWAY_TOKEN=.\{32,\}' "${ENV_FILE}" 2>/dev/null; then
            check_pass "Gateway token is set"
        else
            check_fail "Gateway token missing or too short"
        fi
    else
        check_fail ".env file not found — run scripts/setup.sh"
    fi
    echo ""
}

function check_containers() {
    echo "── Containers ──"
    local compose_file="${PROJECT_ROOT}/docker/docker-compose.yml"

    if [[ ! -f "${compose_file}" ]]; then
        check_fail "docker-compose.yml not found"
        echo ""
        return
    fi

    local services=("zeroclaw-gateway" "mission-control" "zeroclaw-redis")
    for svc in "${services[@]}"; do
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${svc}$"; then
            local status
            status="$(docker inspect --format='{{.State.Status}}' "${svc}" 2>/dev/null)"
            if [[ "${status}" == "running" ]]; then
                check_pass "${svc}: running"
            else
                check_fail "${svc}: ${status}"
            fi
        else
            check_warn "${svc}: not running"
        fi
    done
    echo ""
}

function check_network_ports() {
    echo "── Network ──"

    # Source .env for port values
    if [[ -f "${ENV_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${ENV_FILE}" 2>/dev/null || true
    fi

    local gw_port="${GATEWAY_PORT:-18789}"
    local dash_port="${DASHBOARD_PORT:-4000}"

    for port_info in "${gw_port}:Gateway" "${dash_port}:Dashboard"; do
        local port="${port_info%%:*}"
        local name="${port_info##*:}"
        if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
           netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
            check_pass "${name} port ${port}: listening"
        else
            check_warn "${name} port ${port}: not listening"
        fi
    done
    echo ""
}

function check_security() {
    echo "── Security ──"

    # Check .env not tracked by git
    if cd "${PROJECT_ROOT}" && git ls-files --error-unmatch docker/.env &>/dev/null 2>&1; then
        check_fail ".env is tracked by git — REMOVE IT IMMEDIATELY"
    else
        check_pass ".env is not tracked by git"
    fi

    # Check .gitignore has .env
    if grep -q '\.env' "${PROJECT_ROOT}/.gitignore" 2>/dev/null; then
        check_pass ".gitignore includes .env patterns"
    else
        check_fail ".gitignore missing .env patterns"
    fi

    echo ""
}

function main() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   ZeroClaw — Health Check                       ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    check_env_file
    check_containers
    check_network_ports
    check_security

    echo "── Summary ──"
    echo -e "  ${GREEN}Passed${NC}: ${PASS}  ${YELLOW}Warnings${NC}: ${WARN}  ${RED}Failed${NC}: ${FAIL}"
    echo ""

    if [[ ${FAIL} -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
