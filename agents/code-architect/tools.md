# Tools: Code Architect

Authorized tools for the `coder` agent. Tools not listed here are
**not permitted** for this agent.

## Authorized Tools

### 1. Filesystem

- **Tool ID**: `filesystem`
- **Scope**: Repository root and workspace directory only
- **Operations**: read, write, create, delete, list, search
- **Restrictions**: Cannot access `/etc`, `/root`, `~/.ssh`, or any dotfiles outside repo

```json
{
  "tool": "filesystem",
  "config": {
    "allowedPaths": ["./", "./workspace/"],
    "deniedPaths": [".env", ".env.*", "*.key", "*.pem"],
    "maxFileSize": "1MB"
  }
}
```

### 2. Shell Execution

- **Tool ID**: `shell`
- **Scope**: Sandboxed to repository root
- **Allowed commands**: git, docker, pre-commit, shellcheck, yamllint, actionlint,
  python, pip, npm, node, make, curl (HTTPS only), jq, yq
- **Denied commands**: sudo, su, rm -rf /, chmod 777, eval, ssh

```json
{
  "tool": "shell",
  "config": {
    "workingDir": "./",
    "timeout": 120,
    "maxOutputSize": "100KB",
    "deniedPatterns": [
      "sudo *", "su *", "rm -rf /", "chmod 777",
      "eval *", "ssh *", "curl http://*"
    ]
  }
}
```

### 3. GitHub CLI

- **Tool ID**: `github_cli`
- **Scope**: Current repository only
- **Operations**: pr create, pr list, issue create, issue list, workflow run,
  run view, release create
- **Restrictions**: Cannot modify repository settings, secrets, or branch protection

```json
{
  "tool": "github_cli",
  "config": {
    "scope": "repo",
    "allowedSubcommands": [
      "pr", "issue", "workflow", "run", "release"
    ]
  }
}
```

### 4. Docker CLI

- **Tool ID**: `docker`
- **Scope**: zeroclaw-* containers only
- **Operations**: ps, logs, inspect, compose up/down/restart
- **Restrictions**: Cannot build images, push to registries, or exec into containers

```json
{
  "tool": "docker",
  "config": {
    "allowedContainerPrefix": "zeroclaw-",
    "allowedCommands": ["ps", "logs", "inspect", "compose"],
    "deniedCommands": ["build", "push", "exec", "run"]
  }
}
```

## Prohibited Tools

- ❌ `web_search` — Use `researcher` agent for information gathering
- ❌ `arxiv_search` — Delegate to `researcher`
- ❌ `database` — No direct database manipulation

## Delegation

| Task Type | Delegate To | Example |
|-----------|-------------|---------|
| Research / fact-checking | `researcher` | "What's the latest Redis security advisory?" |
| Task prioritization | `manager` | "Found 3 bugs — which should I fix first?" |
| Scope decisions | `manager` | "Should I add retry logic or keep it simple?" |
