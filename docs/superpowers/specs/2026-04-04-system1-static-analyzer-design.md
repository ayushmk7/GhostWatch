# GhostWatch System 1 — Static Analyzer Design
**Date:** 2026-04-04
**Hackathon:** JacHacks 2026
**Owner:** System 1 (Aaron)

---

## Overview

System 1 is the static PR analysis pipeline for GhostWatch. When a PR is opened or updated on `jaseci-labs/jaseci`, a GitHub webhook triggers three specialist walkers that traverse a persistent Jac graph of the codebase in parallel. Results are delivered as a verdict card in the shared web app frontend and a notification ping to Discord. A maintainer can then approve the verdict, which posts a single review comment to the GitHub PR.

System 1 is architecturally independent from System 2 but shares the graph data model, graph build infrastructure, GitHub integration, and frontend shell.

---

## Success Criteria

- PR verdict delivered and visible in the web app in under 30 seconds from webhook receipt
- Live graph visualization shows walker traversal animation within 3 seconds of verdict arrival
- Zero crashes during the demo — all failures degrade gracefully
- Graph is pre-built once at server start and reused for the entire hackathon

---

## Key Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Trigger | GitHub webhook `pull_request` event | Fully automatic, no human command needed |
| Graph build | Once at server start, persists on root forever | Jac root persistence — no rebuild needed during hackathon |
| Subgraph for Security + Compat | Diff + 1 hop | Focused analysis without noise |
| BlastRadius traversal | Full graph, max 5 hops | Must discover true blast radius |
| Parallel dispatch | `flow/wait` on wrapper functions | Jac `flow/wait` works on functions, not walker spawns |
| Verdict posting | Single post after all three walkers resolve | Simpler, no partial state edge cases |
| GitHub PR comment | Single PR-level review comment | Not the main selling point, simplest that works |
| Discord | Webhook URL only, HTTP POST | Notification-only — no bot process, no discord.py |
| Animation | Full graph rendered, traversal paths replayed post-analysis | No WebSockets needed, loops for demo effect |
| Backboard memory | Stretch goal — not in v1 | Get working product first |

---

## File Structure

```
ghostwatch/
├── main.jac                              # entry point — jac start main.jac
├── jac.toml                              # deps, model config, serve config
├── .env                                  # all secrets
│
├── graph/                                # [SHARED] graph data model
│   ├── nodes.jac                         # pure declarations: FileNode, DependencyNode,
│   │                                     #   FindingNode, DocumentationNode, TestNode
│   ├── edges.jac                         # pure declarations: ImportEdge, DependencyEdge,
│   │                                     #   FindingEdge, BlastEdge
│   ├── builder.jac                       # GraphBuilderWalker declaration
│   └── impl/
│       └── builder.impl.jac             # GraphBuilderWalker implementation
│
├── objects/                              # [SHARED] shared data types
│   ├── verdict.jac                       # VerdictObject, SecurityFinding,
│   │                                     #   CompatibilityIssue, ContributorSuggestion
│   └── sandbox.jac                       # BehavioralTrace, SandboxResult,
│                                         #   SuspiciousDependency (System 2 owns)
│
├── walkers/
│   ├── static/                           # [SYSTEM 1]
│   │   ├── orchestrator.jac              # OrchestratorWalker declaration
│   │   ├── security.jac                  # SecurityAuditorWalker declaration
│   │   ├── compatibility.jac             # CompatibilityCheckerWalker declaration
│   │   ├── blast_radius.jac             # BlastRadiusMapperWalker declaration
│   │   ├── graph_state.jac              # GraphStateWalker declaration (GET /walker/graph-state)
│   │   ├── pr_comment.jac               # PRCommentWriterWalker declaration
│   │   └── impl/
│   │       ├── orchestrator.impl.jac    # parallel flow/wait dispatch
│   │       ├── security.impl.jac        # by llm() audit logic
│   │       ├── compatibility.impl.jac   # API surface cross-reference
│   │       ├── blast_radius.impl.jac   # N-hop traversal + scoring
│   │       ├── graph_state.impl.jac    # graph topology + latest PRAnalysisNode
│   │       └── pr_comment.impl.jac     # GitHub review comment posting
│   │
│   └── ghostwatch/                       # [SYSTEM 2]
│       ├── dep_diff.jac
│       ├── sandbox.jac
│       ├── gap_analysis.jac
│       ├── fix_gen.jac
│       ├── pr_creator.jac
│       └── impl/
│           ├── dep_diff.impl.jac
│           ├── sandbox.impl.jac
│           ├── gap_analysis.impl.jac
│           ├── fix_gen.impl.jac
│           └── pr_creator.impl.jac
│
├── integrations/                         # [SHARED]
│   ├── github.jac                        # PyGithub wrapper declarations
│   ├── discord.jac                       # Discord webhook notification (send only)
│   └── impl/
│       ├── github.impl.jac
│       └── discord.impl.jac
│
└── frontend/                             # [SHARED — coordinate with System 2]
    ├── main.jac                          # frontend entry point
    ├── pages/
    │   ├── layout.jac                    # [SHARED] nav shell, wraps all pages
    │   ├── index.jac                     # [SYSTEM 1] graph viz + walker animation
    │   ├── analysis/
    │   │   └── [pr_id].jac              # [SYSTEM 1] verdict detail + Approve button
    │   ├── security/
    │   │   └── [incident_id].jac        # [SYSTEM 2] malicious dep report
    │   └── gaps.jac                      # [SYSTEM 2] contributor gap suggestions
    └── components/
        ├── Navigation.cl.jac             # [SHARED] top nav
        ├── GraphView.cl.jac              # [SYSTEM 1] graph topology renderer
        ├── WalkerTrace.cl.jac            # [SYSTEM 1] traversal animation replay
        ├── VerdictCard.cl.jac            # [SYSTEM 1] verdict display
        └── AlertBanner.cl.jac            # [SYSTEM 2] security alert banner
```

---

## Data Flow

```
1. PR opened/updated on jaseci-labs/jaseci
         │
         ▼
2. GitHub sends pull_request webhook to GhostWatch
   GitHubWebhookWalker validates HMAC signature
   Checks event type → fires OrchestratorWalker
         │
         ▼
3. OrchestratorWalker spawns on root
   Calls PyGithub to fetch: changed files list + unified diff
   Looks up corresponding FileNodes in the graph
   Builds allowed_nodes set: changed FileNodes + their 1-hop ImportEdge neighbors
         │
         ▼
4. Three wrapper functions dispatched in parallel via flow/wait
   flow run_security()  → spawns SecurityAuditorWalker
   flow run_compat()    → spawns CompatibilityCheckerWalker
   flow run_blast()     → spawns BlastRadiusMapperWalker
   Each walker appends jid(here) to traversal_path on every node visit
         │
         ▼
5. All three resolve — OrchestratorWalker merges findings into VerdictObject
   VerdictObject includes: risk score, per-walker findings,
   affected node count, all three traversal_paths
   PRAnalysisNode saved to graph connected to root (audit trail)
         │
         ├──────────────────────────────────────┐
         ▼                                      ▼
6a. Discord webhook POST sends ping:      6b. VerdictObject available at
    "PR #123 analyzed — Risk: HIGH            GET /walker/graph-state
     View report → [link]"                    for frontend to fetch
         │
         ▼
7. Maintainer opens web app
   Graph visualization loads full graph + VerdictObject
   WalkerTrace replays all three traversal_paths simultaneously
   VerdictCard shows risk score + per-walker findings
         │
         ▼
8. Maintainer clicks Approve
   PRCommentWriterWalker fires
   Posts single review comment to GitHub PR with full verdict summary
```

---

## Graph Data Model

### Nodes (declared in `graph/nodes.jac`)

```jac
node FileNode {
    has path: str;           # relative file path from repo root
    has content: str;        # full source content
    has language: str;       # jac, python, json, toml
    has risk_score: int = 0; # 0-10, updated by BlastRadiusMapper
    has is_test: bool = False;
}

node FindingNode {
    has walker_type: str;    # security, compatibility, blast_radius
    has severity: str;       # critical, high, medium, low
    has description: str;
    has evidence: str;
    has line_number: int = 0;
}

node PRAnalysisNode {
    has pr_url: str;         # full GitHub PR URL
    has verdict: dict;       # serialized VerdictObject including traversal_paths
    has created_at: str;     # ISO timestamp
}
```

### Edges (declared in `graph/edges.jac`)

```jac
edge ImportEdge {
    has is_direct: bool = True;
    has import_type: str;    # static, dynamic, conditional
}

edge BlastEdge {
    has hops: int = 1;
    has impact_type: str;    # direct, transitive, runtime
}
```

---

## Graph Build

`GraphBuilderWalker` is called once at server start via `POST /walker/rebuild-graph`. The built graph persists on root for the entire hackathon — no rebuilds.

**Scope:** Only files with extensions `.jac`, `.py`, `.json`, `.toml`.

**Skip paths:** `__pycache__/`, `.jac/`, `node_modules/`, `dist/`, `build/`.

**Node creation pattern** (`++>` returns a list, always index `[0]`):
```jac
file_node = (root ++> FileNode(path=item.path, content=content, language=lang))[0];
```

**Authenticated GitHub API required** — `GITHUB_TOKEN` is mandatory. Without it the 60 req/hr unauthenticated limit is hit instantly during graph build.

---

## Walker Logic

### SecurityAuditorWalker

- **Traversal boundary:** `allowed_nodes` set (diff + 1 hop). Disengages if `jid(here)` not in set.
- **Per node:** calls `audit_file()` via `by llm()` with `here.content`, `here.path`, and `pr_context` as explicit parameters.
- **Returns:** `list[SecurityFinding]` — severity, description, line number, evidence, recommendation.
- **Disengages on:** `TestNode` entry — no security audit of test files.
- **Traversal path:** appends `jid(here)` on every FileNode visit.

### CompatibilityCheckerWalker

- **Traversal boundary:** `allowed_nodes` set (diff + 1 hop). Disengages if `jid(here)` not in set.
- **Per node:** first calls `_uses_changed_api()` via `by llm()` (cheap check). If true, calls full `check_compatibility()` via `by llm()`.
- **Returns:** `list[CompatibilityIssue]` — API name, issue type, affected callers.
- **Traversal path:** appends `jid(here)` on every FileNode visit.

### BlastRadiusMapperWalker

- **Traversal boundary:** none — traverses the full graph.
- **Depth limit:** `max_hops = 5`, tracked via `current_hop` counter.
- **Per node:** scores numerically via `_score_node()` by llm(), accumulates `risk_score`, creates `BlastEdge` with hop count. No full content analysis — scoring only.
- **Traversal path:** appends `jid(here)` on every FileNode visit.
- **Stops when:** `current_hop >= max_hops` or no more connected nodes.

---

## OrchestratorWalker

```jac
# Wrapper functions — flow/wait works on functions, not walker spawns
def run_security(root_node: FileNode, allowed: set, diff: str) -> list {
    return root_node spawn SecurityAuditorWalker(
        allowed_nodes=allowed, pr_context=diff
    );
}

def run_compat(root_node: FileNode, allowed: set, apis: list, diff: str) -> list {
    return root_node spawn CompatibilityCheckerWalker(
        allowed_nodes=allowed, changed_apis=apis, pr_diff=diff
    );
}

def run_blast(root_node: FileNode, changed: list) -> dict {
    return root_node spawn BlastRadiusMapperWalker(changed_nodes=changed);
}

# Parallel dispatch
sec_future  = flow run_security(subgraph_root, allowed_nodes, diff);
com_future  = flow run_compat(subgraph_root, allowed_nodes, apis, diff);
bla_future  = flow run_blast(subgraph_root, changed_node_ids);

sec_result  = wait sec_future;
com_result  = wait com_future;
bla_result  = wait bla_future;

# Merge into VerdictObject via by llm()
verdict = merge_findings(sec_result, com_result, bla_result);

# Persist audit trail
pr_node = (root ++> PRAnalysisNode(pr_url=self.pr_url, verdict=verdict))[0];
```

---

## GitHub Integration

All GitHub calls live in `integrations/github.jac`. Walkers never call PyGithub directly.

**Functions System 1 needs:**

| Function | Purpose |
|----------|---------|
| `validate_webhook_signature(payload, signature) -> bool` | HMAC-SHA256 check against `GITHUB_WEBHOOK_SECRET` |
| `fetch_pr_diff(pr_url: str) -> PRDiff` | Changed file list + unified diff text |
| `fetch_file_content(repo, path, ref) -> str` | Raw file content (used by GraphBuilderWalker) |
| `post_pr_comment(pr_url, body) -> None` | Single review comment on Approve |

**Rate limiting:** exponential backoff, 3 retries, doubles delay on each. Partial results reported on failure rather than crash.

**Webhook events handled:**

| Event | Action |
|-------|--------|
| `pull_request` opened/synchronize | Fire OrchestratorWalker (System 1) |
| `push` touching dep files | Fire DependencyDiffWalker (System 2) |
| `pull_request` closed + merged | Fire GapAnalysisWalker (System 2) |

---

## Discord Integration

No discord.py. No bot process. One function in `integrations/discord.jac`:

```jac
def notify_discord(pr_number: str, risk: str, report_link: str) -> None {
    # HTTP POST to Discord webhook URL
    # Message: "PR #123 analyzed — Risk: HIGH — View Report → [link]"
}
```

**Env var:** `DISCORD_WEBHOOK_URL` — configured once in Discord server settings.

The message appears in the designated channel under the "GhostWatch" webhook name with a custom avatar, indistinguishable from a bot message to the viewer.

---

## Frontend

### `pages/index.jac` — Graph Visualization

- Fetches `GET /walker/graph-state` on load
- Returns all nodes, all edges, latest `PRAnalysisNode` if present
- Passes to `GraphView` for rendering, kicks off `WalkerTrace` if analysis exists

### `components/GraphView.cl.jac`

- Renders full repo graph via `@xyflow/react`
- Nodes colored by `risk_score`: green (0-3), yellow (4-6), red (7-10)
- Accepts `highlighted_nodes` prop from `WalkerTrace`

### `components/WalkerTrace.cl.jac`

- Receives all three `traversal_path` arrays from `VerdictObject`
- Replays simultaneously at 80ms per hop using `setInterval`
- Walker colors: Security = red, Compatibility = yellow, BlastRadius = orange
- Each visited node pulses then stays highlighted
- Loops continuously — animation never stops during demo

### `pages/analysis/[pr_id].jac` — Verdict Page

- Fetches `PRAnalysisNode` by ID
- Renders `VerdictCard`: overall risk score, per-walker findings, affected node count, blast radius summary
- Approve button → `POST /walker/approve-review` → `PRCommentWriterWalker` → single GitHub review comment

### Fetching data from client:

The frontend never triggers the orchestrator — that is webhook-driven. The client only reads state:

```jac
# Fetch graph topology + latest PRAnalysisNode
sv import from ...walkers.static.graph_state { GraphStateWalker }
result = root() spawn GraphStateWalker();
graph_data = result.reports[0];
```

The frontend polls `GraphStateWalker` at a fixed interval (e.g. every 5 seconds) to detect when a new `PRAnalysisNode` has been added by the webhook pipeline. When one appears, `WalkerTrace` kicks off automatically.

---

## Error Handling

| Failure | Behavior |
|---------|----------|
| `by llm()` call throws | Walker catches, records empty finding with error note, continues traversal |
| Walker fails entirely | Returns empty findings list — pipeline continues with other two walkers |
| GitHub API rate limit | Exponential backoff (3 retries). On total failure: Discord ping "analysis failed — GitHub unavailable" |
| Approve clicked twice | `PRCommentWriterWalker` checks if comment already posted before writing — idempotent |

---

## Shared with System 2

| Asset | Owner | System 2 Usage |
|-------|-------|----------------|
| `graph/nodes.jac` | System 1 | DependencyDiffWalker reads FileNode + DependencyNode |
| `graph/edges.jac` | System 1 | System 2 reads edge types |
| `graph/builder.jac` | System 1 | System 2 webhook can call GraphBuilderWalker if needed |
| `objects/verdict.jac` | System 1 | System 2 reads ContributorSuggestion type |
| `objects/sandbox.jac` | System 2 | System 1 does not use |
| `integrations/github.jac` | Shared | System 2 adds push/merge handler functions |
| `integrations/discord.jac` | Shared | System 2 uses same notify function for security alerts |
| `frontend/pages/layout.jac` | Shared | Coordinate before modifying |
| `frontend/components/Navigation.cl.jac` | Shared | Coordinate before modifying |

---

## Environment Variables

```
# Required for System 1
GITHUB_TOKEN=ghp_...              # Authenticated API calls — mandatory
GITHUB_WEBHOOK_SECRET=...         # HMAC webhook validation
ANTHROPIC_API_KEY=sk-ant-...      # All by llm() calls
DISCORD_WEBHOOK_URL=https://...   # Discord notification channel

# Required for System 2
E2B_API_KEY=...
```

---

## Out of Scope / Stretch Goals

- **Backboard memory** — walker memory threads per repository. Architecture leaves a clean hook (load memory at walker init, store finding at walker exit) but nothing is built in v1.
- **Role-based auth** — web app Approve button is ungated in v1.
- **Incremental graph updates** — graph is static for hackathon duration.
- **Animated graph during analysis** — animation is a post-analysis replay, not real-time.

---

## Pre-Demo Setup

1. `jac start main.jac`
2. `POST /walker/rebuild-graph {"branch": "main"}` — wait for completion
3. Graph is now persisted on root — do not restart the server unnecessarily
4. Configure GitHub webhook on `jaseci-labs/jaseci` pointing to the running server
5. Set `DISCORD_WEBHOOK_URL` in `.env` and verify the Discord channel receives a test ping
