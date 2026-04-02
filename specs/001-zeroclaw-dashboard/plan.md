# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Anil Belur <askb23@gmail.com>

# Implementation Plan: ZeroClaw Custom Dashboard

**Spec ID**: 001
**Date**: 2026-04-02

---

## Approach

Build as a **separate repository** (`askb/zeroclaw-dashboard`) to keep concerns
separated. The dashboard is a pure Next.js frontend that connects to the
existing ZeroClaw gateway via WebSocket and reads local files for memory/docs.

It will be added to the ZeroClaw docker-compose as an optional service, or run
standalone via `pnpm dev` during development.

## New Repository Structure

```
zeroclaw-dashboard/
├── .github/
│   ├── copilot-instructions.md
│   ├── agents/
│   │   └── dashboard-dev.agent.md
│   └── workflows/
│       ├── lint.yaml
│       └── build.yaml
├── .specify/
│   └── memory/
│       └── constitution.md          # Link to zeroclaw-mission-control Constitution
├── src/
│   ├── app/
│   │   ├── layout.tsx               # Root layout (sidebar + dark theme)
│   │   ├── page.tsx                 # Dashboard home (redirect to tasks)
│   │   ├── tasks/
│   │   │   └── page.tsx             # Task Board (Kanban)
│   │   ├── calendar/
│   │   │   └── page.tsx             # Calendar view
│   │   ├── projects/
│   │   │   └── page.tsx             # Projects + reverse prompting
│   │   ├── memory/
│   │   │   └── page.tsx             # Memory journal browser
│   │   ├── docs/
│   │   │   └── page.tsx             # Docs repository
│   │   ├── team/
│   │   │   └── page.tsx             # Team org chart
│   │   ├── office/
│   │   │   └── page.tsx             # Pixel-art office
│   │   └── api/
│   │       ├── gateway/
│   │       │   └── route.ts         # Proxy to gateway (server-side)
│   │       ├── tasks/
│   │       │   └── route.ts         # Task data from MC API
│   │       ├── memory/
│   │       │   └── route.ts         # Memory file reader
│   │       └── docs/
│   │           └── route.ts         # Docs file reader
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx          # Navigation sidebar
│   │   │   └── Header.tsx           # Page header
│   │   ├── tasks/
│   │   │   ├── KanbanBoard.tsx      # Drag-and-drop columns
│   │   │   ├── TaskCard.tsx         # Individual task card
│   │   │   └── ActivityFeed.tsx     # Live activity sidebar
│   │   ├── calendar/
│   │   │   └── CalendarGrid.tsx     # Month/week/day view
│   │   ├── memory/
│   │   │   ├── MemoryTimeline.tsx   # Daily-organized entries
│   │   │   └── MemorySearch.tsx     # Search bar + filters
│   │   ├── team/
│   │   │   ├── OrgChart.tsx         # Agent hierarchy
│   │   │   └── AgentCard.tsx        # Agent status card
│   │   └── office/
│   │       └── PixelOffice.tsx      # Canvas-based visualization
│   ├── lib/
│   │   ├── gateway.ts               # WebSocket client to gateway
│   │   ├── types.ts                 # TypeScript interfaces
│   │   └── utils.ts                 # Shared utilities
│   └── styles/
│       └── globals.css              # Tailwind + custom dark theme
├── public/
│   └── sprites/                     # Pixel art sprites (office screen)
├── .pre-commit-config.yaml
├── .editorconfig
├── .yamllint
├── .eslintrc.json
├── tailwind.config.ts
├── next.config.ts
├── package.json
├── pnpm-lock.yaml
├── tsconfig.json
├── Dockerfile                       # For docker-compose integration
├── AGENTS.md
├── README.md
└── LICENSE
```

## Phase Breakdown

### Phase 1: Next.js Skeleton + Layout
- [ ] Initialize Next.js 15 with App Router, Tailwind, TypeScript, pnpm
- [ ] Create dark-mode Linear theme (globals.css + tailwind.config.ts)
- [ ] Build Sidebar component with navigation links + icons
- [ ] Build root layout with sidebar + content area
- [ ] Add placeholder pages for all 7 screens
- [ ] Set up ESLint, Prettier, pre-commit hooks
- [ ] Add SPDX headers, AGENTS.md, copilot-instructions.md

**Deliverable**: Running skeleton at localhost:3000 with navigation

### Phase 2: Task Board (Kanban)
- [ ] Create gateway WebSocket client (lib/gateway.ts)
- [ ] Build KanbanBoard with 4 columns (Backlog, In Progress, Review, Done)
- [ ] Build TaskCard component (title, agent, progress, priority)
- [ ] Build ActivityFeed component (live updates from gateway)
- [ ] Server-side API route to proxy MC task API
- [ ] Agent heartbeat indicator (online/offline/busy via WebSocket)
- [ ] Task detail panel (click to expand)

**Deliverable**: Working Kanban with live data from gateway

### Phase 3: Memory Screen
- [ ] Server-side API route to read memory files from workspace
- [ ] Build MemoryTimeline component (daily-organized entries)
- [ ] Build MemorySearch component (full-text search)
- [ ] Markdown rendering with syntax highlighting
- [ ] Filter by agent, date range, topic
- [ ] Auto-refresh on new memory entries

**Deliverable**: Searchable memory browser with daily journal view

### Phase 4: Calendar + Docs
- [ ] Build CalendarGrid component (month/week/day views)
- [ ] Read cron schedule from gateway config
- [ ] Display completed vs scheduled vs failed tasks
- [ ] Build Docs screen with file discovery and search
- [ ] Markdown rendering with table of contents
- [ ] Document categorization (auto from frontmatter or folder)

**Deliverable**: Calendar showing cron jobs, Docs with search

### Phase 5: Projects + Team
- [ ] Build Projects screen with goal tracking
- [ ] Implement Reverse Prompting (AI suggests next move via gateway)
- [ ] Build Team OrgChart component
- [ ] Build AgentCard with real-time status
- [ ] Mission statement banner

**Deliverable**: Project management + team visibility

### Phase 6: Office (Pixel Art) + Polish
- [ ] Build PixelOffice with HTML5 Canvas
- [ ] Create sprite assets for agents (desk, cooler, meeting)
- [ ] Wire real-time agent status to sprite positions
- [ ] Add keyboard shortcuts (Cmd+K search, etc.)
- [ ] Performance optimization (lazy loading, code splitting)
- [ ] Add to zeroclaw docker-compose as optional service

**Deliverable**: Complete dashboard with all 7 screens

## Docker Integration (Phase 6)

Add to `zeroclaw-mission-control/docker/docker-compose.yml`:

```yaml
dashboard:
  build:
    context: ../  # assumes zeroclaw-dashboard is sibling dir
    dockerfile: zeroclaw-dashboard/Dockerfile
  container_name: zeroclaw-dashboard
  ports:
    - "${DASHBOARD_CUSTOM_BIND:-127.0.0.1}:3000:3000"
  environment:
    - GATEWAY_WS_URL=ws://gateway:18789
    - GATEWAY_TOKEN=${ZEROCLAW_GATEWAY_TOKEN}
    - MC_API_URL=http://mission-control:4000
  volumes:
    - ../workspace:/app/data/workspace:ro
    - ../agents:/app/data/agents:ro
  depends_on:
    gateway:
      condition: service_healthy
  networks:
    - zeroclaw-net
  read_only: true
  cap_drop: [ALL]
  security_opt: [no-new-privileges:true]
```

## Rollback Plan

Dashboard is a separate repository with no write access to the gateway.
Rollback = `docker compose stop dashboard` or simply don't deploy it.
The existing Mission Control continues to work independently.

## Dependencies

- Requires: ZeroClaw gateway running (ws://localhost:18789)
- Requires: Mission Control running (http://localhost:4000) for task API
- Optional: Workspace directory mounted for memory/docs file reads
- Blocked by: Nothing — can start immediately
