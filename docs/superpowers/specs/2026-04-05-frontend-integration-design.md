# GhostWatch Frontend Integration — System 1 Design Spec
**Date:** 2026-04-05  
**Scope:** Tasks 1–4 of System 1 frontend integration  
**Status:** Approved for implementation planning

---

## 1. Problem Statement

The frontend (`frontend/`) is visually complete but runs entirely on mock data. The backend (`walkers/static/`) has fully tested walkers that expose live graph state, PR analysis, and traversal history. This spec covers connecting the two for the hackathon demo.

---

## 2. Architecture

### Two-server setup
- **Frontend:** `cd frontend && jac start main.jac --dev` → Vite on port 8000, Jac API on port 8001
- **Backend:** `jac start main.jac --port 8080` from project root → Jac API on port 8080
- **`sv import` is not usable** — it requires walkers to be resolvable at compile time from `frontend/`, but `walkers/` is in the parent directory

### Communication strategy — Option A (Vite proxy override)
Add to `frontend/jac.toml`:
```toml
[plugins.client.vite.server.proxy."/walker"]
target = "http://localhost:8080"
changeOrigin = true
```
In dev mode, Jac's Vite server already proxies `/walker/*` to the local Jac API. This override retargets it to port 8080 instead. Browser calls remain same-origin (`localhost:8000/walker/...`) — no CORS involved.

**Test-first:** On day one of execution, start the frontend server and inspect `.jac/client/vite.config.js` to confirm the proxy key was picked up. If it is absent, pivot to **Option C (proxy walker)**: a thin `walker:pub GraphStateProxy` on the frontend server that uses Python `requests` to call port 8080 server-side.

### Auth
Both target walkers are `walker:pub` — no JWT token required.

### fetch helper
Browser globals (`fetch`, `JSON.stringify`) are unknown to Jac's type checker. Wrap all fetch calls in a top-level helper outside the component:
```jac
def doFetch(url: str, opts: dict) -> Any {
    return fetch(url, opts);
}
```

### async def validation
Before touching AppShell, validate that `async def` nested inside `def:pub` compiles in Jac. If it does not, extract `fetchGraphState` and `runAnalysis` as top-level `def` helpers in the same file.

---

## 3. Task 1 — GraphStateWalker data source

### New state in AppShell
```
has graphState: dict | None = None
has analysisLoading: bool = False
has analysisResult: dict | None = None
has animatingPath: list = []
```

### fetchGraphState
```
async def fetchGraphState() -> None:
    res = await doFetch("/walker/GraphStateWalker", {"method": "POST", "headers": {...}, "body": "{}"})
    data = await res.json()
    graphState = data["reports"][0]
```

### Lifecycle
`async can with entry` in AppShell calls `fetchGraphState()` once on mount. No polling timer — the demo flow is linear: mount → graph loads → user clicks Run Analysis → result appears.

### Response shape
```json
{
  "reports": [{
    "nodes": [{"id": "jid", "path": "...", "language": "...", "risk_score": 0-20, "is_test": bool}],
    "edges": [{"source": "jid", "target": "jid"}],
    "has_graph": true,
    "latest_analysis": {"id": "jid", "pr_url": "...", "verdict": {...}, "created_at": "..."},
    "latest_incident": {...} | null,
    "latest_gap_analysis": {...} | null
  }]
}
```

---

## 4. Task 2 — Graph visualization

### jac.toml additions (frontend/jac.toml)
```toml
[dependencies.npm]
"@xyflow/react" = "latest"
```

### CSS
`@xyflow/react` requires its stylesheet or nodes/edges render without background or borders. Add at the top of `GraphView.cl.jac` (Vite handles CSS imports in JS/TS, so this works in `.cl.jac` files):
```jac
import "@xyflow/react/dist/style.css";
```

### GraphView.cl.jac — props
```
nodes_data: list       # from graphState["nodes"]
edges_data: list       # from graphState["edges"]  
animatingPath: list    # blast_radius traversal jids, empty when idle
analysisLoading: bool  # true while OrchestratorWalker is running
```

### Node construction
- `id`: `n["id"]` (jid, matches traversal path jids)
- `position`: `x = (index % 6) * 200`, `y = int(index / 6) * 120`
- `label`: last path segment (filename)
- `style`: background color by risk_score (0–20 scale):
  - `>= 14` → red `rgba(239,68,68,0.85)`
  - `>= 7` → amber `rgba(251,191,36,0.85)`
  - else → frost `rgba(125,211,255,0.6)`

### Edge construction
- `id`: `source + "-" + target`
- `source`, `target`: direct from edges_data
- `animated`: `True` — dashed flowing lines on all edges

### Animation — pure CSS (no setInterval)
Two CSS keyframes defined in `theme.cl.jac` or inline:
- `@keyframes gw-node-pulse`: opacity/box-shadow cycle, 1.5s, for loading state
- `@keyframes gw-node-scan`: bright cyan glow spike then fade, for traversal animation

**Loading state** (`analysisLoading = True`): all nodes get `className="gw-node-pulse"`. No per-node delay.

**Animating state** (`animatingPath` non-empty): each node whose id is in `animatingPath` gets `className="gw-node-scan"` with:
- `animationDelay`: `path_index * 600ms`
- `animationDuration`: `len(animatingPath) * 600ms`  
- `animationIterationCount`: `"infinite"`

This means the glow sweeps through nodes in traversal order, looping forever. Nodes not in the path stay static with their risk color.

**Idle**: no animation class.

### AppShell integration
In the maintainer Overview graph panel section (lines 1055–1074 of AppShell):
- If `graphState` is not None and `graphState["nodes"]` is non-empty → render `<GraphView ...>`
- Else → keep existing `<GraphPlaceholderAccent/>` + copy text

---

## 5. Task 3 — Replace mock data (maintainer Overview only)

All other tabs (PR Review, Dependency Alerts, Incidents, Settings, all contributor view) stay on mock data.

### Summary cards
When `graphState` is not None, replace `SUMMARY_CARDS` with derived values:

| Card | Live value | Fallback (no graph) |
|---|---|---|
| Files scanned | `str(len(graphState["nodes"]))` | "—" |
| High-risk files | count of nodes where `risk_score >= 14` | "—" |
| Latest PR risk | `latest_analysis.verdict.overall_risk` if exists | "None yet" |
| Graph status | "Ready" if `has_graph` else "Building..." | "No graph" |

`tone`, `spark`, `delta` fields: use static values matching the existing card styles.

### Walker status rail
Replace `WALKER_STATUS` with derived list:

| Walker | State logic |
|---|---|
| SecurityAuditorWalker | "Running" if `analysisLoading` else "Active" if `has_graph` else "Idle" |
| CompatibilityCheckerWalker | same |
| BlastRadiusMapperWalker | same |

### Attention items
Replace `ATTENTION_ITEMS` with derived list:
- "Files in graph" / `f"{len(nodes)} nodes"`
- "High-risk files" / `f"{high_risk_count} detected"`
- "Latest incident" / `latest_incident["status"]` if present else "None"

### Verdict panel
Rendered in maintainer Overview between summary cards and graph panel, only when `analysisResult` is not None:
- Risk badge: `overall_risk` text, background color matches risk level
- `blast_radius_summary` paragraph
- `recommendation` paragraph  
- Finding counts: `"{n} security findings · {m} compatibility issues"`

No new component — inline JSX in AppShell.

---

## 6. Task 4 — Run Analysis button

### Demo constants (mock_data.cl.jac)
```
DEMO_PR_URL: str = "https://github.com/Aarosunn/ghostwatch-test-target/pull/2"
DEMO_REPO_URL: str = "https://github.com/Aarosunn/ghostwatch-test-target"
```
Swap `DEMO_PR_URL` to the prepared Jaseci PR before demo day.

### AppShell pre-fill
Change `repoInput` initial value from `""` to `DEMO_REPO_URL`. User clicks Continue once to link, then Run Analysis to trigger.

### Button states
| Condition | Label | Behavior |
|---|---|---|
| `not repoLinked` | "Connect" | existing `linkRepository()` |
| `repoLinked`, `not analysisLoading` | "Run Analysis" | `runAnalysis()` |
| `analysisLoading` | "Analyzing..." | disabled |

### runAnalysis sequence
1. Set `analysisLoading = True`, clear `analysisResult`, clear `animatingPath`
2. POST `/walker/OrchestratorWalker` with body `{"pr_url": DEMO_PR_URL}`
3. On response: store `reports[0]` in `analysisResult`
4. Extract `analysisResult["traversal_paths"]["blast_radius"]` into `animatingPath`
5. Set `analysisLoading = False`
6. Call `fetchGraphState()` to refresh node risk colors

Traversal paths come directly from the OrchestratorWalker response — no second walker call needed.

---

## 7. Backend fix — orchestrator.impl.jac

`_merge_findings by llm` creates a VerdictObject but does not reliably populate `traversal_paths` from the input walker dicts. Add an unconditional override immediately after the LLM call:

```jac
verdict.traversal_paths = {
    "security": sec_result.get("traversal_path", []),
    "compatibility": com_result.get("traversal_path", []),
    "blast_radius": bla_result.get("traversal_path", [])
};
```

This must be applied in BOTH the try block (LLM success path) and is already correct in the except block (fallback path).

---

## 8. Files changed

| File | Nature of change |
|---|---|
| `walkers/static/impl/orchestrator.impl.jac` | Backend fix: post-LLM traversal_paths override |
| `frontend/jac.toml` | Add `@xyflow/react` npm dep, add Vite proxy block |
| `frontend/mock_data.cl.jac` | Add `DEMO_PR_URL`, `DEMO_REPO_URL` constants |
| `frontend/components/GraphView.cl.jac` | Build from scratch |
| `frontend/components/AppShell.cl.jac` | State vars, fetch helpers, wire button, live Overview data, verdict panel, graph placeholder swap |

---

## 9. Out of scope

- Contributor view live data
- PR Review, Dependency Alerts, Incidents, Settings tabs live data
- Stub pages (`/analysis/[pr_id]`, `/gaps`, `/security/[incident_id]`)
- Demo cleanup (ghostwatch-test-target PR reset, worktree setup)
- Any System 2 frontend work
