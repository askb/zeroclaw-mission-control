<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- SPDX-FileCopyrightText: 2026 The Linux Foundation -->

# Contributing to ZeroClaw Mission Control

Thank you for your interest in contributing! This guide covers everything you
need to get started.

## Table of Contents

- [Development Environment](#development-environment)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Code Standards](#code-standards)
- [Agent Development](#agent-development)
- [Docker Development Workflow](#docker-development-workflow)
- [Security Requirements](#security-requirements)

---

## Development Environment

### Prerequisites

- Docker Engine 24+ with Compose v2
- Python 3.11+ (for pre-commit hooks)
- `shellcheck` (for Bash linting)
- `openssl` (for token generation)
- At least one LLM API key (Anthropic or OpenAI)

### Setup

```bash
# Clone the repository
git clone https://github.com/askb/zeroclaw-mission-control.git
cd zeroclaw-mission-control

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Run the secure bootstrap (generates tokens, creates .env)
./scripts/setup.sh

# Add your API keys
nano docker/.env
# Set ANTHROPIC_API_KEY and/or OPENAI_API_KEY

# Start all services
cd docker && docker compose up -d

# Verify everything is healthy
../scripts/health-check.sh
```

---

## Pre-commit Hooks

All contributions **must** pass pre-commit checks. Never use `--no-verify`
to bypass hooks.

### Install and Run

```bash
# Install hooks (one-time)
pre-commit install

# Run all checks
pre-commit run --all-files

# Run a specific hook
pre-commit run shellcheck --all-files

# Update hooks to latest versions
pre-commit autoupdate
```

### Active Hooks

| Hook | Purpose |
|------|---------|
| trailing-whitespace | Remove trailing whitespace |
| end-of-file-fixer | Ensure files end with newline |
| check-yaml | Validate YAML syntax |
| check-json | Validate JSON syntax |
| check-added-large-files | Block files > 500KB |
| detect-private-key | Prevent private key commits |
| yamllint | YAML style validation |
| shellcheck | Bash script linting |
| actionlint | GitHub Actions workflow validation |
| codespell | Typo detection |
| detect-secrets | Credential scanning |
| gitlint | Commit message validation |

---

## Commit Message Format

We use **conventional commits** with a required sign-off (DCO compliance).

### Format

```
<type>(<scope>): <subject>

<body>

Signed-off-by: Your Name <your.email@example.com>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `refactor` | Code change (no new feature, no fix) |
| `chore` | Maintenance tasks |
| `ci` | CI/CD workflow changes |
| `security` | Security improvements |

### Examples

```bash
# Feature with sign-off
git commit -s -m "feat(agents): add discord-workflows skill"

# Bug fix
git commit -s -m "fix(docker): correct redis healthcheck interval"

# Documentation
git commit -s -m "docs: update README with caddy routing section"
```

---

## Pull Request Process

### Requirements

1. **Semantic PR title** — PR titles must follow conventional commit format
   (enforced by the `semantic-pull-request` workflow)
2. **All CI checks pass** — Lint, security audit, Docker Compose validation
3. **SHA-pinned actions** — Any new GitHub Actions must be pinned to full SHA
4. **No secrets in code** — `detect-secrets` and `security-audit` workflows
   will flag any leaked credentials
5. **Pre-commit clean** — Run `pre-commit run --all-files` before pushing

### Workflow

1. Fork and create a feature branch from `main`
2. Make your changes
3. Run `pre-commit run --all-files`
4. Push and open a PR with a semantic title (e.g., `feat: add new agent`)
5. Address review feedback
6. Once approved, the maintainer will merge

### PR Title Examples

```
feat(agents): add home-assistant skill
fix(docker): resolve redis connection timeout
docs: add caddy HTTPS routing section
ci: add daily health report workflow
```

---

## Code Standards

### SPDX License Headers

All new files **must** include SPDX headers:

```yaml
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
```

For Markdown files:

```html
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- SPDX-FileCopyrightText: 2026 The Linux Foundation -->
```

### Shell Scripts

- Must pass `shellcheck` with no warnings
- Use `set -euo pipefail` for error handling
- Include cleanup traps for resource management
- Use `#!/usr/bin/env bash` shebang

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
set -euo pipefail

function cleanup() {
    # Cleanup code
}
trap cleanup EXIT
```

### YAML Files

- Validate with `yamllint`
- Use 2-space indentation
- Format with `prettier`

### GitHub Actions Workflows

- Validate with `actionlint`
- **Pin ALL external actions to SHA** with version comments:

```yaml
# ✅ Correct — SHA-pinned with version comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# ❌ Wrong — floating tag
- uses: actions/checkout@v4
```

---

## Agent Development

### Adding a New Agent Persona

Agents live in `agents/<name>/` with two required files:

```
agents/<agent-name>/
├── agent.md    # Persona definition, system prompt, behavioral rules
└── tools.md    # Authorized tools and capabilities
```

#### agent.md

Define the agent's personality, role, and behavioral boundaries:

```markdown
# Agent Name

## Role
Brief description of what this agent does.

## Behavioral Rules
- Rule 1
- Rule 2

## Capabilities
What this agent can and cannot do.
```

#### tools.md

List the tools and APIs the agent is authorized to use:

```markdown
# Tools

## Authorized
- Tool 1: description
- Tool 2: description

## Denied
- Tool X: reason for denial
```

### Adding a New Skill

Skills live in `config/gateway/workspace/skills/<skill-name>/`:

```
config/gateway/workspace/skills/<skill-name>/
├── SKILL.md        # Skill definition and usage instructions
├── _meta.json      # Skill metadata
├── scripts/        # Executable scripts (optional)
└── references/     # API docs and references (optional)
```

#### SKILL.md

Define the skill's purpose, triggers, and usage:

```markdown
# Skill Name

## Purpose
What this skill does.

## Usage
How agents invoke this skill.

## Examples
Example interactions.
```

---

## Docker Development Workflow

### Starting Services

```bash
cd docker

# Start all services
docker compose up -d

# Start specific services
docker compose up -d gateway dashboard

# View logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f gateway
```

### Rebuilding After Changes

```bash
# Rebuild and restart
docker compose up -d --build

# Force recreate without cache
docker compose build --no-cache
docker compose up -d
```

### Health Checks

```bash
# Run the health check script
../scripts/health-check.sh

# Check individual service status
docker compose ps
```

### Teardown

```bash
# Stop services (preserves volumes)
../scripts/teardown.sh

# Stop and delete all data
../scripts/teardown.sh --volumes
```

---

## Security Requirements

### Non-Negotiable Rules

1. **No secrets in code** — API keys, tokens, and passwords must go in
   `docker/.env` (gitignored). Never commit credentials.
2. **SHA-pinned actions** — All GitHub Actions must be pinned to full SHA
   commit hashes, not floating tags.
3. **Pre-commit hooks** — Never bypass with `--no-verify`. If a hook fails,
   fix the issue.
4. **Container hardening** — All containers run non-root with read-only FS
   and `no-new-privileges`.
5. **Secret rotation** — Use `scripts/rotate-secrets.sh` to rotate internal
   tokens regularly.

### Reporting Vulnerabilities

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

---

## Questions?

Open an issue or start a discussion in the repository. We're happy to help!
# Contributing Guidelines

Thank you for your interest in contributing to this project! This document outlines the process for submitting issues, pull requests, and our coding standards.

## Submitting Issues

When submitting an issue, please:

1. **Search existing issues** first to avoid duplicates
2. Use a clear, descriptive title
3. Provide detailed reproduction steps for bugs
4. Include relevant system information (OS, Python version, etc.)
5. Add appropriate labels when possible

## Pull Request Process

### Before You Start
- Fork the repository
- Create a feature branch from `main`: `git checkout -b feature/your-feature-name`
- Ensure your changes don't break existing functionality

### Submitting Your PR
1. Write clear, concise commit messages
2. Update documentation as needed
3. Add tests for new functionality
4. Ensure all tests pass: `pytest` or `python -m pytest`
5. Push your branch: `git push origin feature/your-feature-name`
6. Open a pull request with:
   - A clear title and description
   - Link to any related issues
   - Screenshots/logs if applicable

### Review Process
- Maintainers will review within 2-3 business days
- Address feedback promptly
- Squash commits if requested

## Code Style Requirements

### Python
- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Use [Black](https://black.readthedocs.io/) for formatting: `black .`
- Use [isort](https://pycqa.github.io/isort/) for imports: `isort .`
- Add type hints where appropriate
- Maximum line length: 88 characters (Black default)

### Documentation
- Use [Google style](https://google.github.io/styleguide/pyguide.html) docstrings
- Update README.md for user-facing changes
- Keep changelog updated in `CHANGELOG.md`

### Testing
- Write unit tests for new features
- Maintain or improve test coverage
- Use pytest for testing framework
- Test file naming: `test_*.py`

## Automated PR Creation

This repository uses an AI coding agent that can:
- Create automated pull requests from natural language requests
- Generate tests for new functionality
- Refactor existing code while maintaining behavior
- Update documentation automatically

### How It Works
1. Issues labeled with `ai-assist` are reviewed by the coding agent
2. The agent analyzes the request and creates appropriate changes
3. A pull request is automatically generated with:
   - Clear commit messages
   - Updated tests
   - Documentation updates
   - Descriptive PR title and body

### Agent Capabilities
- **Code Generation**: Creates new features from specifications
- **Refactoring**: Restructures code without changing behavior
- **Bug Fixes**: Addresses reported issues with tests
- **Documentation**: Updates README, docstrings, and examples
- **Dependency Management**: Updates requirements files

### Agent Limitations
- Cannot access external APIs during development
- Requires human review for architectural decisions
- May need guidance on business logic requirements
- Cannot deploy changes to production

### Triggering Automated PRs
To request automated assistance:
1. Create an issue with the `ai-assist` label
2. Provide clear, specific requirements
3. The agent will respond with proposed changes for approval
4. Review and merge the generated PR

## Getting Help

- **Questions**: Open a discussion in the GitHub Discussions tab
- **Real-time chat**: Join our [Discord/Slack channel]
- **Code review**: Tag maintainers in your PR

## Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` file
- Release notes for significant contributions
- Special mentions in project announcements

Thank you for contributing!
