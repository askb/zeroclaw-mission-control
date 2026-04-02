# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Anil Belur <askb23@gmail.com>

# Task Breakdown: ZeroClaw Custom Dashboard

**Spec ID**: 001
**Date**: 2026-04-02

---

## Status Legend
- ⬜ Not started
- 🔄 In progress
- ✅ Done
- ❌ Blocked

## Tasks

### Phase 1: Next.js Skeleton + Layout
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1 | Create `askb/zeroclaw-dashboard` repo | ⬜ | Add to Constitution allowlist |
| 1.2 | `pnpm create next-app` with App Router, TS, Tailwind | ⬜ | Next.js 15+, pnpm |
| 1.3 | Dark-mode Linear theme (globals.css + tailwind config) | ⬜ | Colors: slate-900, blue-500 accent |
| 1.4 | Sidebar component with Lucide icons | ⬜ | 7 nav items |
| 1.5 | Root layout (sidebar + content area) | ⬜ | |
| 1.6 | Placeholder pages for all 7 screens | ⬜ | |
| 1.7 | Pre-commit, ESLint, SPDX headers | ⬜ | |
| 1.8 | AGENTS.md, copilot-instructions.md, Constitution ref | ⬜ | |

### Phase 2: Task Board (Kanban)
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1 | Gateway WebSocket client (lib/gateway.ts) | ⬜ | Token auth via env var |
| 2.2 | KanbanBoard with 4 columns | ⬜ | Drag-drop optional for MVP |
| 2.3 | TaskCard component | ⬜ | Agent icon, priority, progress |
| 2.4 | ActivityFeed (live updates) | ⬜ | WebSocket events |
| 2.5 | MC Task API proxy (server-side route) | ⬜ | /api/tasks → MC:4000 |
| 2.6 | Agent heartbeat indicators | ⬜ | Green/yellow/red dots |
| 2.7 | Task detail panel | ⬜ | Side panel on click |

### Phase 3: Memory Screen
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1 | Memory file reader API route | ⬜ | Read from workspace volume |
| 3.2 | MemoryTimeline (daily entries) | ⬜ | Grouped by date |
| 3.3 | MemorySearch (full-text) | ⬜ | Client-side filter |
| 3.4 | Markdown rendering | ⬜ | react-markdown + rehype |
| 3.5 | Agent and date filters | ⬜ | Dropdown + date picker |

### Phase 4: Calendar + Docs
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4.1 | CalendarGrid (month view) | ⬜ | |
| 4.2 | Cron schedule reader | ⬜ | Parse gateway config |
| 4.3 | Task history overlay on calendar | ⬜ | |
| 4.4 | Docs file discovery API route | ⬜ | Scan workspace/docs/ |
| 4.5 | Docs search and categorization | ⬜ | |
| 4.6 | Markdown rendering with TOC | ⬜ | |

### Phase 5: Projects + Team
| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.1 | Projects screen with goal cards | ⬜ | |
| 5.2 | Reverse Prompting via gateway | ⬜ | Send prompt, display suggestion |
| 5.3 | OrgChart component | ⬜ | Agent hierarchy tree |
| 5.4 | AgentCard with live status | ⬜ | |
| 5.5 | Mission statement banner | ⬜ | |

### Phase 6: Office + Polish
| # | Task | Status | Notes |
|---|------|--------|-------|
| 6.1 | PixelOffice Canvas component | ⬜ | 2D pixel art |
| 6.2 | Agent sprites (desk/cooler/meeting) | ⬜ | |
| 6.3 | Wire real-time status to positions | ⬜ | |
| 6.4 | Keyboard shortcuts (Cmd+K) | ⬜ | |
| 6.5 | Dockerfile for production build | ⬜ | |
| 6.6 | Add to zeroclaw docker-compose | ⬜ | Optional service |
| 6.7 | README with screenshots | ⬜ | |

## Blockers

| Blocker | Impact | Resolution |
|---------|--------|------------|
| Gateway WebSocket API docs unclear | Phase 2 | Explore via `openclaw acp --help` |
| Memory file format unknown | Phase 3 | Inspect `config/gateway/memory/` |
| Cron not yet configured | Phase 4 | Add cron jobs to gateway first |

## Quality Checklist

- [ ] All SPDX headers present
- [ ] Pre-commit passes (ESLint, Prettier, yamllint)
- [ ] No hardcoded secrets (gateway token via env var)
- [ ] Read-only access to all data sources
- [ ] Constitution allowlist updated
- [ ] Conventional commits with sign-off
- [ ] Works on localhost:3000
