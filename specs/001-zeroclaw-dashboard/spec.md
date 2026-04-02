# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Anil Belur <askb23@gmail.com>

# Feature Specification: ZeroClaw Custom Dashboard

**Spec ID**: 001
**Author**: Anil Belur
**Date**: 2026-04-02
**Status**: Draft
**Repository**: `askb/zeroclaw-dashboard` (new)

---

## Summary

Build a custom "Mission Control Dashboard" as a Next.js application that acts
as the central hub for managing ZeroClaw AI agents, tasks, memory, and
documentation. The interface follows a dark-mode "Linear" app aesthetic —
clean, professional, keyboard-driven.

This dashboard **supplements** the existing OpenClaw Mission Control (task
management + per-task chat) by adding views that MC doesn't provide: calendar,
memory browser, docs repository, team visualization, and the fun pixel-art
office.

## Motivation

The stock Mission Control is task-focused. As ZeroClaw's capabilities grow
(multiple agents, skills, cron jobs, memory), a custom dashboard provides:

- **Visibility**: See all agent activity, cron schedules, and memory in one place
- **Accountability**: Calendar view ensures scheduled tasks actually run
- **Knowledge management**: Searchable docs and memory browser
- **Team awareness**: Visual org chart of agents and their current status
- **Engagement**: Pixel-art office makes the system approachable and fun

## Architecture

```
┌─────────────────────────────────────────────────┐
│              ZeroClaw Dashboard                  │
│            (Next.js, localhost:3000)              │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │Task Board│  │ Calendar │  │ Projects │      │
│  │ (Kanban) │  │  (Cron)  │  │(Reverse  │      │
│  │          │  │          │  │ Prompt)  │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │              │              │            │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐      │
│  │  Memory  │  │   Docs   │  │   Team   │      │
│  │ (Journal)│  │ (Search) │  │(Org Chart│      │
│  │          │  │          │  │ + Office)│      │
│  └────┬─────┘  └────┴─────┘  └──────────┘      │
│       │                                          │
├───────┴──────────────────────────────────────────┤
│         Data Sources (read-only APIs)            │
│  ┌──────────┐ ┌────────┐ ┌──────────┐          │
│  │ OpenClaw │ │ Redis  │ │ Local FS │          │
│  │ Gateway  │ │(memory)│ │(md files)│          │
│  │ ws:18789 │ │        │ │          │          │
│  └──────────┘ └────────┘ └──────────┘          │
└─────────────────────────────────────────────────┘
```

### Key Design Decisions

- **Read-only by default**: Dashboard reads from gateway API, Redis, and local
  files. No direct writes to gateway config or agent state.
- **WebSocket for live data**: Connect to gateway ws://localhost:18789 for
  real-time session/agent activity.
- **Local file access**: Memory and docs screens read markdown files from
  the workspace directory (mounted as volume).
- **No authentication needed**: Runs on localhost only, behind the same
  gateway token auth.

## Requirements

### Must Have (MVP — Phase 1-3)

- [ ] Next.js 15+ App Router with Tailwind CSS dark mode
- [ ] Sidebar navigation (Linear-style: Tasks, Calendar, Projects, Memory, Docs, Team, Office)
- [ ] **Task Board (Kanban)**: Columns for Backlog, In Progress, Review, Done
  - Live Activity Feed sidebar showing real-time agent actions
  - Agent heartbeat indicator (online/offline/busy)
  - Task assignment to specific agents
  - Task detail panel with chat history (read from gateway)
- [ ] **Calendar Screen**: Visual month/week/day view
  - Display cron jobs from gateway config
  - Show completed vs scheduled tasks
  - Proactive task suggestions based on patterns
- [ ] **Memory Screen**: Searchable journal view
  - Daily-organized entries from agent memory files
  - Markdown rendering with syntax highlighting
  - Search across all memory entries
  - Filter by agent, date range, topic
- [ ] Gateway WebSocket connection for live data
- [ ] Responsive layout (desktop primary, tablet secondary)

### Should Have (Phase 4-5)

- [ ] **Projects Screen**: High-level goal tracking
  - Reverse Prompting: AI suggests next best move per project
  - Progress tracking with milestones
  - Link to related tasks and PRs
- [ ] **Docs Screen**: Centralized document repository
  - AI-generated newsletters, architecture docs, plans
  - Full-text search with categorization
  - Markdown rendering with table of contents
  - Auto-discovery of new docs from workspace
- [ ] **Team Screen**: Agent organizational chart
  - Visual org chart showing agent hierarchy
  - Agent cards with: name, role, current status, tools
  - Mission statement banner at top
  - Click-through to agent config/activity

### Nice to Have (Phase 6)

- [ ] **Office Screen**: 2D pixel-art visualization
  - Agents represented at desks, water cooler, meeting room
  - Real-time position based on current activity
  - Fun animations (typing, thinking, sleeping)
  - Built with HTML5 Canvas or CSS pixel art
- [ ] Keyboard shortcuts (Linear-style: Cmd+K, etc.)
- [ ] Notification system for important agent events
- [ ] Cost tracking dashboard (OpenRouter usage)

### Must NOT

- [ ] Must NOT write to gateway config directly
- [ ] Must NOT modify agent definitions
- [ ] Must NOT store secrets in the dashboard code
- [ ] Must NOT be exposed to the public internet (localhost only)
- [ ] Must NOT bypass the Constitution or exec approvals
- [ ] Must NOT require a separate database (use gateway API + file reads)

## Screens Breakdown

### Screen 1: Task Board (Kanban)

```
┌─────────────────────────────────────────────────────────┐
│ ⚡ Live Feed        │  Backlog  │ In Progress │  Done   │
│                     │           │             │         │
│ 14:02 🔍 Researcher │ ┌───────┐ │ ┌─────────┐ │ ┌─────┐│
│   searched "k8s"    │ │Task 3 │ │ │ Task 1  │ │ │ T5  ││
│                     │ │       │ │ │ 🤖 Coder │ │ │ ✅  ││
│ 14:01 🤖 Coder      │ └───────┘ │ │ ████░░  │ │ └─────┘│
│   committed fix     │ ┌───────┐ │ └─────────┘ │         │
│                     │ │Task 4 │ │             │         │
│ 14:00 👔 Manager    │ │       │ │             │         │
│   delegated task    │ └───────┘ │             │         │
└─────────────────────┴───────────┴─────────────┴─────────┘
```

### Screen 2: Calendar

```
┌─────────────────────────────────────────────────┐
│ ◀ April 2026 ▶                                  │
│ Mon  Tue  Wed  Thu  Fri  Sat  Sun               │
│                1    2    3    4    5             │
│               🔄   🔄                            │
│  6    7    8    9   10   11   12                 │
│ 🔄   🔄        🔄                                │
│                                                  │
│ 🔄 = Cron job   ✅ = Completed   ❌ = Failed     │
│                                                  │
│ Today's Schedule:                                │
│ ├─ 06:00 Daily health check (cron)              │
│ ├─ 09:00 PR review sweep (cron)                 │
│ └─ 18:00 Backup workspace (cron)                │
└─────────────────────────────────────────────────┘
```

### Screen 5: Memory

```
┌─────────────────────────────────────────────────┐
│ 🔍 Search memory...              [Agent ▾] [📅] │
│                                                  │
│ ── April 2, 2026 ──────────────────────────────  │
│ 14:30 | Researcher                               │
│ Learned: Kimi K2 supports 128K context window.   │
│ Source: https://moonshotai.com/kimi-k2           │
│                                                  │
│ 13:15 | Coder                                    │
│ Fixed: docker-compose SearXNG service added.     │
│ PR: #12 — merged                                 │
│                                                  │
│ ── April 1, 2026 ──────────────────────────────  │
│ ...                                              │
└─────────────────────────────────────────────────┘
```

## Data Sources

| Screen | Source | Method |
|--------|--------|--------|
| Task Board | Gateway WebSocket + MC API | `ws://localhost:18789`, `http://localhost:4000/api/tasks` |
| Calendar | Gateway config (cron) + task history | Read `openclaw.json` cron entries |
| Projects | Local markdown files in `workspace/projects/` | File system read |
| Memory | Gateway memory store + Redis | `openclaw memory` CLI or API |
| Docs | Local markdown files in `workspace/docs/` | File system read |
| Team | Agent definitions in `agents/` | File system read |
| Office | Agent session status via gateway | WebSocket status events |

## Security Considerations

- Dashboard runs on localhost:3000 — not exposed externally
- Uses same gateway token for WebSocket auth
- Read-only access to all data sources
- No file writes from the dashboard
- Token passed via environment variable, never in client-side code
- Server-side API routes handle all gateway communication

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Next.js (App Router) | 15+ |
| Styling | Tailwind CSS | 4+ |
| Icons | Lucide React | Latest |
| WebSocket | Native WebSocket API | - |
| Markdown | react-markdown + rehype | Latest |
| Charts | Recharts (optional) | Latest |
| Pixel Art | HTML5 Canvas | - |
| Package Manager | pnpm | Latest |

## Acceptance Criteria

- [ ] All Must Have features functional
- [ ] Dark mode Linear aesthetic achieved
- [ ] Live data flowing from gateway WebSocket
- [ ] Memory search returns relevant results
- [ ] Calendar shows actual cron schedule
- [ ] Pre-commit hooks pass
- [ ] No hardcoded secrets
- [ ] SPDX headers on all files
- [ ] README with setup instructions

## References

- Linear app design: https://linear.app
- OpenClaw Gateway API: https://docs.openclaw.ai
- Next.js App Router: https://nextjs.org/docs/app
- Tailwind CSS: https://tailwindcss.com
- Mission Control (existing): http://localhost:4000
