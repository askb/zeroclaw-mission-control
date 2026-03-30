#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
##############################################################################
# ZeroClaw Mission Control — Teardown
# Stops all services and cleans up ephemeral data
##############################################################################

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/docker/docker-compose.yml"
ENV_FILE="${PROJECT_ROOT}/docker/.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
function log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

function stop_services() {
    if [[ ! -f "${COMPOSE_FILE}" ]]; then
        log_warn "docker-compose.yml not found"
        return 0
    fi

    log_info "Stopping all services..."
    if docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" down --remove-orphans 2>/dev/null; then
        log_info "Services stopped ✅"
    else
        log_warn "Some services may not have been running"
    fi
}

function cleanup_volumes() {
    local clean_volumes="${1:-false}"

    if [[ "${clean_volumes}" == "true" ]]; then
        log_warn "Removing Docker volumes (data will be lost)..."
        docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" down -v 2>/dev/null || true
        log_info "Volumes removed"
    fi
}

function cleanup_workspace() {
    local workspace="${PROJECT_ROOT}/workspace"
    if [[ -d "${workspace}" ]]; then
        local file_count
        file_count="$(find "${workspace}" -type f 2>/dev/null | wc -l)"
        if [[ "${file_count}" -gt 0 ]]; then
            log_warn "Workspace contains ${file_count} file(s) — preserving"
            log_warn "To clean: rm -rf ${workspace}/*"
        else
            log_info "Workspace is empty"
        fi
    fi
}

function cleanup_backups() {
    local backup_dir="${PROJECT_ROOT}/docker/.env.backups"
    if [[ -d "${backup_dir}" ]]; then
        local backup_count
        backup_count="$(find "${backup_dir}" -type f 2>/dev/null | wc -l)"
        log_info "Found ${backup_count} .env backup(s) in ${backup_dir}"
        log_info "To clean: rm -rf ${backup_dir}"
    fi
}

function usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --volumes    Also remove Docker volumes (destroys Redis data)"
    echo "  --help       Show this help message"
    echo ""
}

function main() {
    local clean_volumes="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --volumes)
                clean_volumes="true"
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   ZeroClaw — Teardown                           ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    stop_services
    cleanup_volumes "${clean_volumes}"
    cleanup_workspace
    cleanup_backups

    echo ""
    log_info "Teardown complete."
    echo ""
}

main "$@"
