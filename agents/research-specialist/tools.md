# Tools: Research Specialist

Authorized tools for the `researcher` agent. Tools not listed here are
**not permitted** for this agent.

## Authorized Tools

### 1. Web Search (Brave Search API)

- **Tool ID**: `web_search`
- **Provider**: Brave Search API
- **Rate Limit**: 1 request/second, 1000 requests/day
- **Auth**: `BRAVE_API_KEY` environment variable
- **Use When**: Answering any factual question, verifying claims, finding recent data

```json
{
  "tool": "web_search",
  "config": {
    "provider": "brave",
    "maxResults": 10,
    "safeSearch": "moderate",
    "freshness": "past_month"
  }
}
```

### 2. Academic Search (Arxiv)

- **Tool ID**: `arxiv_search`
- **Provider**: Arxiv API (free, no auth)
- **Rate Limit**: 3 seconds between requests
- **Use When**: Finding academic papers, research methodologies, technical standards

```json
{
  "tool": "arxiv_search",
  "config": {
    "maxResults": 5,
    "sortBy": "relevance"
  }
}
```

### 3. URL Fetch

- **Tool ID**: `url_fetch`
- **Provider**: Built-in HTTP client
- **Rate Limit**: 1 request/second
- **Use When**: Reading full content of a specific URL found via search
- **Restrictions**: HTTPS only, max 100KB response, no file downloads

```json
{
  "tool": "url_fetch",
  "config": {
    "maxSizeKb": 100,
    "timeout": 10,
    "httpsOnly": true
  }
}
```

## Prohibited Tools

The following tools are **NOT authorized** for the research specialist:

- ❌ `filesystem` — No file read/write access
- ❌ `shell` — No command execution
- ❌ `github_cli` — No repository operations
- ❌ `docker` — No container management
- ❌ `database` — No direct data access

## Delegation

When the researcher identifies a task outside its scope:

| Task Type | Delegate To | Example |
|-----------|-------------|---------|
| Code implementation | `coder` | "Implement the API endpoint described in my research" |
| Task prioritization | `manager` | "These 5 findings need to be triaged" |
| Infrastructure changes | `coder` | "The config needs updating per the docs" |
