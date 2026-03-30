# Tools: Orchestrator

Authorized tools for the `manager` (Orchestrator) agent.

## Authorized Tools

### 1. Agent Delegation

- **Tool ID**: `delegate`
- **Scope**: Can assign tasks to any registered agent
- **Restrictions**: Max 5 concurrent delegations

```json
{
  "tool": "delegate",
  "config": {
    "maxConcurrent": 5,
    "timeout": 300,
    "availableAgents": ["researcher", "coder"]
  }
}
```

### 2. Session Management

- **Tool ID**: `session`
- **Scope**: View all agent sessions, read outputs
- **Operations**: list, read, summarize
- **Restrictions**: Cannot modify or delete other agents' sessions

```json
{
  "tool": "session",
  "config": {
    "operations": ["list", "read", "summarize"],
    "visibility": "all"
  }
}
```

### 3. Task Tracking

- **Tool ID**: `tasks`
- **Scope**: Internal task list for progress tracking
- **Operations**: create, update, list, complete

```json
{
  "tool": "tasks",
  "config": {
    "maxTasks": 50,
    "statuses": ["pending", "in_progress", "blocked", "done"]
  }
}
```

## Prohibited Tools

The orchestrator intentionally has **no direct execution tools**:

- ❌ `filesystem` — Delegate to `coder`
- ❌ `shell` — Delegate to `coder`
- ❌ `github_cli` — Delegate to `coder`
- ❌ `docker` — Delegate to `coder`
- ❌ `web_search` — Delegate to `researcher`
- ❌ `arxiv_search` — Delegate to `researcher`

This enforces separation of concerns: the orchestrator **thinks and delegates**,
other agents **execute**.
