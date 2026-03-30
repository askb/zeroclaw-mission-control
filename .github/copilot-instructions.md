# ZeroClaw Mission Control — Copilot Instructions

## Repository Purpose

This repository defines a **zero-trust agent orchestration platform** using
Docker Compose. It runs the ZeroClaw gateway (LLM routing) and Mission Control
dashboard with three specialized AI agents: researcher, coder, and orchestrator.

## Architecture

```
Gateway (:18789) ←→ Mission Control (:4000)
    ↕
  Redis (internal only, :6379)
    ↕
  Agents: researcher | coder | orchestrator
```

## Key Directories

| Path | Purpose |
|------|---------|
| `docker/` | Docker Compose orchestration + `.env.example` |
| `config/` | Gateway config (`zeroclaw.json5`) + Redis config |
| `agents/` | Agent persona definitions (`agent.md` + `tools.md`) |
| `scripts/` | Bootstrap, rotation, health check, teardown |
| `.github/workflows/` | CI/CD: lint, security audit, release, PR validation |

## Security Rules (NON-NEGOTIABLE)

1. **Never hardcode secrets** — Use `${ENV_VAR}` references, never literal values
2. **SHA-pin all actions** — `uses: actions/checkout@<40-char-sha>  # vX.Y.Z`
3. **Non-root containers** — All services must include `user:` directive
4. **No privilege escalation** — `security_opt: [no-new-privileges:true]`
5. **Internal Redis** — Redis must never have a host port binding
6. **SPDX headers** — All new files need `Apache-2.0` license header
7. **Shellcheck** — All bash scripts must pass `shellcheck -S warning`

## Code Standards

- **YAML**: 2-space indent, yamllint compliant
- **Bash**: `set -euo pipefail`, SPDX header, shellcheck clean
- **Commits**: Conventional format (`feat:`, `fix:`, `docs:`, etc.), signed
- **PRs**: Semantic title required, all CI checks must pass

## Agent Personas

Each agent has an `agent.md` (identity/rules) and `tools.md` (authorized tools):

- **researcher** — Web search, Arxiv; cannot execute code
- **coder** — Filesystem, shell, GitHub CLI; cannot web search
- **orchestrator** — Delegation only; no direct tool access

When modifying agents, maintain strict separation of concerns.

## Running Locally

```bash
./scripts/setup.sh          # Generate tokens, create .env
cd docker && docker compose up -d   # Start services
./scripts/health-check.sh   # Verify everything works
```
