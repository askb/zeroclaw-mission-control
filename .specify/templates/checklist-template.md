# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Anil Belur <askb23@gmail.com>

# Quality Checklist: [FEATURE NAME]

**Spec ID**: NNN
**Date**: YYYY-MM-DD

---

## Pre-Commit
- [ ] `pre-commit run --all-files` passes
- [ ] No `--no-verify` used

## Code Quality
- [ ] SPDX license headers on all new files
- [ ] YAML files pass yamllint
- [ ] Shell scripts pass shellcheck
- [ ] No hardcoded secrets or credentials
- [ ] Conventional commit messages with sign-off

## Security
- [ ] No new env vars exposed to agent
- [ ] No new host volume mounts
- [ ] No privilege escalation
- [ ] No new open ports without documentation
- [ ] Constitution.md rules not violated
- [ ] Exec approvals updated if new tools added

## Documentation
- [ ] README updated if user-facing change
- [ ] AGENTS.md updated if agent behavior changed
- [ ] Constitution.md unchanged (or amendment PR opened)

## Testing
- [ ] Happy path verified
- [ ] Error case verified
- [ ] Cleanup/rollback tested

## PR Readiness
- [ ] Branch name follows convention (`zeroclaw/`, `feat/`, `fix/`)
- [ ] PR title uses conventional commits
- [ ] PR description explains the change
- [ ] All CI checks pass
