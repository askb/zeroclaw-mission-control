# ZeroClaw Mission Control

[![Lint](https://github.com/askb/zeroclaw-mission-control/actions/workflows/lint.yaml/badge.svg)](https://github.com/askb/zeroclaw-mission-control/actions/workflows/lint.yaml)
[![Security Audit](https://github.com/askb/zeroclaw-mission-control/actions/workflows/security-audit.yaml/badge.svg)](https://github.com/askb/zeroclaw-mission-control/actions/workflows/security-audit.yaml)

A **zero-trust agent orchestration platform** powered by the OpenClaw gateway
and Mission Control dashboard. Runs three specialized AI agents — researcher,
coder, and orchestrator — with hardened Docker containers, token-based auth,
and network isolation.

## Features

- 🔒 **Zero-Trust Security** — Non-root containers, read-only FS, no-privilege-escalation
- 🤖 **3 Specialized Agents** — Research, coding, and orchestration personas
- 🔑 **Automatic Secret Management** — Token generation, rotation, and .env isolation
- 🐳 **Hardened Docker Compose** — Resource limits, health checks, internal-only Redis
- 🔄 **Full CI/CD** — Lint, security audit, SHA-pin verification, semantic PRs, Dependabot
- 📋 **AI-Ready** — Copilot instructions, AGENTS.md, PR review agent

## Quick Start

### Prerequisites

- Docker Engine 24+ with Compose v2
- `openssl` (for token generation)
- At least one LLM API key (Anthropic or OpenAI)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/askb/zeroclaw-mission-control.git
cd zeroclaw-mission-control

# 2. Run the secure bootstrap
./scripts/setup.sh

# 3. Add your API keys
nano docker/.env
# Set ANTHROPIC_API_KEY and/or OPENAI_API_KEY

# 4. Start all services
cd docker && docker compose up -d

# 5. Verify everything is healthy
../scripts/health-check.sh
```

### Access

| Service | URL | Auth |
|---------|-----|------|
| Gateway | `http://localhost:18789` | Token (auto-generated) |
| Mission Control | `http://localhost:4000` | Token (via gateway) |

> **Note**: By default, services bind to `127.0.0.1` (localhost only).
> Edit `GATEWAY_BIND_HOST` and `DASHBOARD_BIND_HOST` in `.env` to change.

## Architecture

```
┌──────────────────────────────────────────┐
│           ZeroClaw Network (bridge)       │
│                                           │
│  ┌────────────┐    ┌──────────────────┐  │
│  │  Gateway    │    │ Mission Control  │  │
│  │  :18789     │◄──►│ :4000            │  │
│  │  (token)    │ ws │ (token)          │  │
│  └──────┬──────┘    └──────────────────┘  │
│         │                                  │
│  ┌──────┴──────┐                          │
│  │  Redis      │  (internal only)         │
│  │  :6379      │  (ACL + password)        │
│  └─────────────┘                          │
│                                            │
│  Agents: researcher | coder | orchestrator │
└──────────────────────────────────────────┘
```

## Agents

| Agent | Role | Tools | Default |
|-------|------|-------|---------|
| **Research Specialist** | Information gathering, fact-checking, citations | Web Search (Brave), Arxiv, URL Fetch | No |
| **Code Architect** | Implementation, debugging, code review | Filesystem, Shell, GitHub CLI, Docker | No |
| **Orchestrator** | Task delegation, coordination, prioritization | Delegation, Session Mgmt, Task Tracking | Yes ⭐ |

Agent personas are defined in `agents/<name>/agent.md` with authorized tools
in `agents/<name>/tools.md`.

## Security

### Zero-Trust Design

| Layer | Protection |
|-------|-----------|
| **Secrets** | `.env` gitignored; `openssl rand` generated tokens |
| **Network** | Docker bridge; Redis internal-only (no host port) |
| **Containers** | Non-root, read-only FS, `no-new-privileges` |
| **Resources** | CPU/memory limits prevent DoS |
| **Supply Chain** | All GHA SHA-pinned; Dependabot for updates |
| **Detection** | `detect-secrets` + private key scanning in pre-commit |
| **Rotation** | `scripts/rotate-secrets.sh` for credential cycling |

### Secret Rotation

```bash
# Rotate all internal tokens (preserves API keys)
./scripts/rotate-secrets.sh
```

### Teardown

```bash
# Stop services
./scripts/teardown.sh

# Stop services AND delete volumes (Redis data)
./scripts/teardown.sh --volumes
```

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `lint.yaml` | Push/PR | YAML lint, shellcheck, pre-commit |
| `docker-compose-validate.yaml` | Push/PR (docker/, config/) | Compose config validation |
| `security-audit.yaml` | Push/PR + weekly | Secret detection, credential patterns, SHA-pin audit |
| `semantic-pull-request.yaml` | PR | Enforce conventional PR titles |
| `sha-pinned-actions.yaml` | PR (.github/) | Verify all actions are SHA-pinned |
| `copilot-auto-assign.yml` | Issue labeled "copilot" | Auto-assign Copilot agent |
| `release-drafter.yaml` | Push to main | Auto-generate release notes |

## Configuration

### Gateway (`config/zeroclaw.json5`)

- Model routing: Claude Sonnet 4 (primary) → GPT-4o (fallback)
- Token auth from `ZEROCLAW_GATEWAY_TOKEN` env var
- Rate limiting: 60 req/min, 100K tokens/min
- Agent definitions with per-agent model overrides

### Redis (`config/redis.conf`)

- Password required (from `REDIS_PASSWORD` env var)
- Dangerous commands disabled (`FLUSHALL`, `FLUSHDB`, `DEBUG`)
- Memory limit: 200MB with LRU eviction
- RDB persistence for session data

## Development

### Pre-commit Hooks

```bash
# Install hooks
pip install pre-commit
pre-commit install

# Run all checks
pre-commit run --all-files
```

### Hooks Included

- Trailing whitespace, end-of-file, YAML/JSON check
- Large file detection (500KB max)
- Private key detection
- yamllint, shellcheck
- GitHub Actions workflow validation
- codespell (typo detection)
- detect-secrets (credential scanning)

## License

SPDX-License-Identifier: Apache-2.0

Copyright 2026 The Linux Foundation
