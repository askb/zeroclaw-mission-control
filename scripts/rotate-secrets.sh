#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
##############################################################################
# ZeroClaw Mission Control — Secret Rotation
# Regenerates all internal tokens and restarts services
##############################################################################

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/docker/.env"
BACKUP_DIR="${PROJECT_ROOT}/docker/.env.backups"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
function log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

function generate_token() { openssl rand -hex 32; }
function generate_password() { openssl rand -base64 24 | tr -d '/+=' | head -c 32; }

function backup_env() {
    if [[ ! -f "${ENV_FILE}" ]]; then
        log_error "No .env file found at ${ENV_FILE}"
        log_error "Run scripts/setup.sh first"
        exit 1
    fi

    mkdir -p "${BACKUP_DIR}"
    local backup_name
    backup_name=".env.$(date -u +"%Y%m%dT%H%M%SZ")"
    cp "${ENV_FILE}" "${BACKUP_DIR}/${backup_name}"
    chmod 600 "${BACKUP_DIR}/${backup_name}"
    log_info "Backed up current .env to ${BACKUP_DIR}/${backup_name}"
}

function rotate_secrets() {
    local new_gateway_token
    local new_redis_password
    new_gateway_token="$(generate_token)"
    new_redis_password="$(generate_password)"

    # Replace tokens in .env (preserve API keys)
    sed -i "s/^ZEROCLAW_GATEWAY_TOKEN=.*/ZEROCLAW_GATEWAY_TOKEN=${new_gateway_token}/" "${ENV_FILE}"
    sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=${new_redis_password}/" "${ENV_FILE}"

    chmod 600 "${ENV_FILE}"

    log_info "Rotated ZEROCLAW_GATEWAY_TOKEN: ${new_gateway_token:0:8}...(truncated)"
    log_info "Rotated REDIS_PASSWORD: (hidden)"
}

function restart_services() {
    local compose_dir="${PROJECT_ROOT}/docker"

    if docker compose -f "${compose_dir}/docker-compose.yml" ps --quiet 2>/dev/null | head -1 | grep -q .; then
        log_info "Restarting services with new credentials..."
        docker compose -f "${compose_dir}/docker-compose.yml" --env-file "${ENV_FILE}" down
        docker compose -f "${compose_dir}/docker-compose.yml" --env-file "${ENV_FILE}" up -d
        log_info "Services restarted ✅"
    else
        log_warn "Services not running. Start with: cd docker && docker compose up -d"
    fi
}

function main() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   ZeroClaw — Secret Rotation                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    log_info "Backing up current .env..."
    backup_env

    log_info "Generating new secrets..."
    rotate_secrets

    restart_services

    echo ""
    log_info "Rotation complete! API keys (Anthropic, OpenAI, Brave) were preserved."
    echo ""
}

main "$@"
