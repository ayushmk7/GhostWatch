# Frontend Integration — System 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the GhostWatch frontend to live backend walkers — graph state polling, @xyflow/react visualization with traversal animation, live Overview data, and a wired Run Analysis button.

**Architecture:** Frontend (port 8000/8001) and backend (port 8080) run as separate Jac servers. The frontend Vite dev server proxies `/walker/*` to port 8080 via a jac.toml override, keeping all browser calls same-origin. Communication uses plain `fetch()` wrapped in a typed helper. All target walkers are `walker:pub` — no auth required.

**Tech Stack:** Jac/jaclang, @xyflow/react, React 18, Vite, Python `requests` (proxy fallback only)

**TDD Policy:** Every task follows red → green → commit. For backend tasks: write a failing curl assertion first, then implement, then re-assert. For frontend tasks: curl-verify the backend data shape before writing any wiring code, then verify visually in the browser. No implementation step runs before its corresponding test step.

---

## File Map

| File | Role |
|---|---|
| `walkers/static/impl/orchestrator.impl.jac` | Backend: add post-LLM `traversal_paths` override |
| `frontend/jac.toml` | Add `@xyflow/react` dep + Vite proxy config |
| `frontend/mock_data.cl.jac` | Add `DEMO_PR_URL`, `DEMO_REPO_URL` constants |
| `frontend/theme.cl.jac` | Add CSS keyframes for node pulse + scan animations |
| `frontend/components/GraphView.cl.jac` | New: ReactFlow graph with risk coloring + traversal animation |
| `frontend/components/AppShell.cl.jac` | Wire state, fetch helpers, button, live data, verdict panel |
| `frontend/main.jac` | Option C fallback only: add proxy walkers here |
| `tests/test_traversal.jac` | TDD: assert traversal_paths non-empty after OrchestratorWalker |

---

## Task 0: Validate Vite Proxy Override

**This is a gate — do not write any frontend fetch code until this passes.**

**Files:**
- Modify: `frontend/jac.toml`

- [ ] **Step 1: Add Vite proxy config to frontend/jac.toml**

Current `frontend/jac.toml` ends at `[plugins]`. Add:

```toml
[plugins.client.vite.server.proxy."/walker"]
target = "http://localhost:8080"
changeOrigin = true
```

- [ ] **Step 2: Start the frontend and inspect the generated Vite config**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac start main.jac --dev &
sleep 5
cat .jac/client/vite.config.js | grep -A 5 proxy
```

- [ ] **Step 3: Decision branch**

**If output shows a `proxy` key pointing to `http://localhost:8080`:**
Proxy override works. Kill the dev server (`kill %1`), proceed to Task 1. All fetch calls in this plan use relative URLs like `/walker/GraphStateWalker`.

**If output shows no proxy key (or default port 8001 only):**
Jac doesn't pass unknown Vite server keys through. Kill the dev server. Implement Option C (proxy walkers) before proceeding:

Add to `frontend/main.jac` BEFORE the `cl { ... }` block:

```jac
import requests;
import from typing { Any }

walker:pub GraphStateProxy {
    can fetch with Root entry {
        resp: Any = requests.post(
            "http://localhost:8080/walker/GraphStateWalker",
            json={}
        );
        report resp.json();
    }
}

walker:pub OrchestratorProxy {
    has pr_url: str;

    can run with Root entry {
        resp: Any = requests.post(
            "http://localhost:8080/walker/OrchestratorWalker",
            json={"pr_url": self.pr_url}
        );
        report resp.json();
    }
}
```

Then in all subsequent tasks, replace `/walker/GraphStateWalker` with `/walker/GraphStateProxy` and `/walker/OrchestratorWalker` with `/walker/OrchestratorProxy`.

Restart the frontend and verify:
```bash
curl -s -X POST http://localhost:8001/walker/GraphStateProxy \
  -H "Content-Type: application/json" -d '{}' | python3 -m json.tool | head -20
```
Expected: JSON with `"reports"` key containing graph data.

- [ ] **Step 4: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/jac.toml frontend/main.jac
git commit -m "chore: configure frontend-to-backend communication channel"
```

---

## Task 1: Backend Fix — traversal_paths Always Populated (TDD)

**Goal:** `OrchestratorWalker` response always contains non-empty `traversal_paths` regardless of whether the LLM call succeeds or fails.

**Files:**
- Test: `tests/test_traversal.jac`
- Modify: `walkers/static/impl/orchestrator.impl.jac`

**Prerequisite:** Backend running with a pre-built graph.
```bash
cd /home/asunaron/hackathons/GhostWatch
source .env
GITHUB_TOKEN="$GITHUB_TOKEN" ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL" GITHUB_WEBHOOK_SECRET="$GITHUB_WEBHOOK_SECRET" \
  jac start main.jac --port 8080 &
sleep 3
```

- [ ] **Step 1: Write the failing test — assert traversal_paths is non-empty**

Create `tests/test_traversal.jac`:

```jac
# tests/test_traversal.jac
# TDD: OrchestratorWalker must always return non-empty traversal_paths.blast_radius

import from walkers.static.orchestrator { OrchestratorWalker }
import from typing { Any }

test traversal_paths_populated {
    result: Any = root spawn OrchestratorWalker(
        pr_url="https://github.com/Aarosunn/ghostwatch-test-target/pull/2"
    );
    verdict: Any = getattr(result, "verdict", {});
    paths: Any = verdict.get("traversal_paths", {});
    blast: Any = paths.get("blast_radius", []);
    assert len(blast) > 0, f"traversal_paths.blast_radius is empty: {verdict}";
}
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
cd /home/asunaron/hackathons/GhostWatch
PYTHONPATH=/home/asunaron/hackathons/GhostWatch \
  GITHUB_TOKEN="$GITHUB_TOKEN" ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  jac test tests/test_traversal.jac
```

Expected: FAIL — `traversal_paths.blast_radius is empty: {...}` (LLM path returns `traversal_paths: {}`).

- [ ] **Step 3: Implement the fix in orchestrator.impl.jac**

In `walkers/static/impl/orchestrator.impl.jac`, inside `impl OrchestratorWalker.orchestrate`, find the try/except block around `_merge_findings`. The current try block ends with the verdict assignment. Add the override as the LAST line inside the `try` block, before closing it:

```jac
    try {
        verdict = self._merge_findings(
            security=sec_result,
            compat=com_result,
            blast=bla_result,
            pr_url=self.pr_url
        );
        # Always override traversal_paths — LLM does not reliably populate this field
        verdict.traversal_paths = {
            "security": sec_result.get("traversal_path", []),
            "compatibility": com_result.get("traversal_path", []),
            "blast_radius": bla_result.get("traversal_path", [])
        };
    } except Exception as e { # jac:ignore[W2052]
```

The except block already sets `traversal_paths` correctly — do not touch it.

- [ ] **Step 4: Run the test — confirm it passes**

```bash
PYTHONPATH=/home/asunaron/hackathons/GhostWatch \
  GITHUB_TOKEN="$GITHUB_TOKEN" ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  jac test tests/test_traversal.jac
```

Expected: PASS — no assertion error.

- [ ] **Step 5: Spot-check via curl**

```bash
curl -s -X POST http://localhost:8080/walker/OrchestratorWalker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/2"}' \
  | python3 -c "import sys,json; r=json.load(sys.stdin); p=r['reports'][0].get('traversal_paths',{}); print('blast_radius nodes:', len(p.get('blast_radius',[])))"
```

Expected: `blast_radius nodes: <N>` where N > 0.

- [ ] **Step 6: Commit**

```bash
git add tests/test_traversal.jac walkers/static/impl/orchestrator.impl.jac
git commit -m "fix: always populate traversal_paths from walker results, not LLM output"
```

---

## Task 2: Validate async def Pattern + Add Demo Constants

**Goal:** Confirm whether `async def` nested inside `def:pub` compiles in Jac. Add demo constants and the `doFetch` helper. These are prerequisites for all AppShell wiring.

**Files:**
- Modify: `frontend/mock_data.cl.jac`
- Modify: `frontend/components/AppShell.cl.jac` (doFetch helper only)

- [ ] **Step 1: Write a minimal async def test component**

Create `frontend/components/_AsyncTest.cl.jac`:

```jac
import from typing { Any }

def:pub AsyncTestComponent() -> JsxElement {
    has testResult: str = "pending";

    async def doAsyncThing() -> None {
        testResult = "done";
    }

    async can with entry {
        await doAsyncThing();
    }

    return <div>{testResult}</div>;
}
```

- [ ] **Step 2: Run jac check to confirm it compiles**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check components/_AsyncTest.cl.jac
```

**If PASS:** `async def` inside `def:pub` is valid. Delete the test file. Proceed — `fetchGraphState` and `runAnalysis` will be defined INSIDE AppShell.

**If FAIL (E-code on async def):** `async def` is not supported nested inside `def:pub`. Delete the test file. Both helpers will be defined as module-level `def` outside the AppShell function body. In that case, they cannot directly mutate component state — instead accept state-setter callbacks. The plan steps below mark where this changes.

```bash
rm /home/asunaron/hackathons/GhostWatch/frontend/components/_AsyncTest.cl.jac
```

- [ ] **Step 3: Add demo constants to mock_data.cl.jac**

Add at the bottom of `frontend/mock_data.cl.jac`:

```jac
cl glob:pub DEMO_PR_URL: str = "https://github.com/Aarosunn/ghostwatch-test-target/pull/2";
cl glob:pub DEMO_REPO_URL: str = "https://github.com/Aarosunn/ghostwatch-test-target";
```

- [ ] **Step 4: Verify mock_data compiles**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check mock_data.cl.jac
```

Expected: no errors.

- [ ] **Step 5: Add doFetch helper to AppShell.cl.jac**

Add BEFORE the `def parse_repo_slug` function (before line 30 of AppShell.cl.jac), after the existing imports block. Also add `import from typing { Any }` if not present. Also add `DEMO_PR_URL, DEMO_REPO_URL` to the `import from ..mock_data { ... }` block at the top.

```jac
import from typing { Any }

def doFetch(url: str, opts: dict) -> Any {
    return fetch(url, opts);
}
```

- [ ] **Step 6: Run jac check on AppShell**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check components/AppShell.cl.jac
```

Expected: no new errors introduced.

- [ ] **Step 7: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/mock_data.cl.jac frontend/components/AppShell.cl.jac
git commit -m "chore: add demo constants, doFetch helper, validate async def pattern"
```

---

## Task 3: Add CSS Keyframes for Node Animation

**Goal:** Define the two animation keyframes that GraphView will use. These live in `theme.cl.jac`'s `APP_STYLES` string.

**Files:**
- Modify: `frontend/theme.cl.jac`

- [ ] **Step 1: Curl-verify the frontend loads without CSS errors (baseline)**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac start main.jac --dev &
sleep 5
curl -s http://localhost:8000 | grep -c "gw-root"
```

Expected: `1` (the app root div is present). This is the baseline — no CSS errors before our changes.

Kill the server: `kill %1`

- [ ] **Step 2: Add keyframes to APP_STYLES in theme.cl.jac**

Find the end of the `APP_STYLES` string (the closing `"""`). Add these keyframes and utility classes immediately before the closing `"""`:

```css
/* ── Node animation keyframes ─────────────────────── */
@keyframes gw-node-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(125,211,255,0.3); }
  50%       { box-shadow: 0 0 14px 6px rgba(125,211,255,0.7); }
}

@keyframes gw-node-scan {
  0%   { box-shadow: 0 0 0 0 rgba(125,211,255,0); opacity: 0.85; }
  20%  { box-shadow: 0 0 22px 8px rgba(125,211,255,0.95); opacity: 1; }
  100% { box-shadow: 0 0 0 0 rgba(125,211,255,0); opacity: 0.85; }
}

/* ── ReactFlow canvas container ───────────────────── */
.gw-graph-canvas {
  height: 400px;
  width: 100%;
  background: rgba(0,0,0,0.2);
  border-radius: 8px;
  overflow: hidden;
}
```

- [ ] **Step 3: Run jac check on theme.cl.jac**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check theme.cl.jac
```

Expected: no errors (it's a string constant — only syntax matters).

- [ ] **Step 4: Start frontend and visually verify the page still loads**

```bash
jac start main.jac --dev &
sleep 5
curl -s http://localhost:8000 | grep -c "gw-root"
kill %1
```

Expected: `1`. No regressions.

- [ ] **Step 5: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/theme.cl.jac
git commit -m "feat: add gw-node-pulse and gw-node-scan CSS keyframes for graph animation"
```

---

## Task 4: Build GraphView Component

**Goal:** Implement `GraphView.cl.jac` using `@xyflow/react`. Nodes colored by risk_score (0–20 scale). Animated edges. Loading pulse + traversal scan animations via inline CSS.

**Files:**
- Modify: `frontend/jac.toml`
- Build: `frontend/components/GraphView.cl.jac`

- [ ] **Step 1: Add @xyflow/react to frontend/jac.toml**

In `frontend/jac.toml`, under `[dependencies.npm]`, add:

```toml
"@xyflow/react" = "latest"
```

- [ ] **Step 2: Write GraphView.cl.jac**

```jac
import "@xyflow/react/dist/style.css";
cl import from "@xyflow/react" { ReactFlow, Background, Controls }
import from typing { Any }

def riskColor(score: Any) -> str {
    s: int = int(score) if score else 0;
    if s >= 14 {
        return "rgba(239,68,68,0.85)";
    }
    if s >= 7 {
        return "rgba(251,191,36,0.85)";
    }
    return "rgba(125,211,255,0.6)";
}

def:pub GraphView(
    nodes_data: list,
    edges_data: list,
    animatingPath: list,
    analysisLoading: bool
) -> JsxElement {

    # Build path-index lookup for O(1) animation delay calc
    path_index: dict = {};
    for (i, jid_val) in enumerate(animatingPath) {
        path_index[jid_val] = i;
    }
    path_len: int = len(animatingPath);

    # Build ReactFlow node objects
    xf_nodes: list = [];
    for (idx, n) in enumerate(nodes_data) {
        node_style: dict = {
            "background": riskColor(n["risk_score"]),
            "border": "1px solid rgba(220,239,255,0.3)",
            "borderRadius": "6px",
            "padding": "8px 10px",
            "color": "rgba(220,239,255,0.9)",
            "fontSize": "11px",
            "minWidth": "80px",
            "textAlign": "center",
            "cursor": "default"
        };

        if analysisLoading {
            node_style["animationName"] = "gw-node-pulse";
            node_style["animationDuration"] = "1.5s";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        } elif path_len > 0 and n["id"] in path_index {
            node_style["animationName"] = "gw-node-scan";
            node_style["animationDuration"] = f"{path_len * 600}ms";
            node_style["animationDelay"] = f"{path_index[n['id']] * 600}ms";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        }

        label: str = n["path"].split("/")[-1];
        xf_nodes.append({
            "id": n["id"],
            "position": {"x": (idx % 6) * 200, "y": (idx // 6) * 120},
            "data": {"label": label},
            "style": node_style
        });
    }

    # Build ReactFlow edge objects
    xf_edges: list = [
        {
            "id": e["source"] + "-" + e["target"],
            "source": e["source"],
            "target": e["target"],
            "animated": True,
            "style": {"stroke": "rgba(125,211,255,0.4)", "strokeWidth": 1.5}
        }
        for e in edges_data
    ];

    return
        <div className="gw-graph-canvas">
            <ReactFlow
                nodes={xf_nodes}
                edges={xf_edges}
                fitView={True}
                nodesDraggable={False}
                nodesConnectable={False}
                elementsSelectable={False}
                proOptions={{"hideAttribution": True}}
            >
                <Background color="rgba(125,211,255,0.08)" gap={24}/>
                <Controls showInteractive={False}/>
            </ReactFlow>
        </div>;
}
```

- [ ] **Step 3: Run jac check on GraphView.cl.jac**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check components/GraphView.cl.jac
```

Expected: no errors. If E1032 on `fetch` or `int()` — add `import from typing { Any }` and cast: `s: Any = score; s_int = int(s) if s else 0`.

- [ ] **Step 4: Add GraphView import to AppShell.cl.jac**

At the top of `frontend/components/AppShell.cl.jac`, add with the other component imports:

```jac
cl import from .GraphView { GraphView }
```

- [ ] **Step 5: Run jac check on AppShell**

```bash
jac check components/AppShell.cl.jac
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/jac.toml frontend/components/GraphView.cl.jac frontend/components/AppShell.cl.jac
git commit -m "feat: build GraphView with xyflow/react, risk coloring, traversal animation"
```

---

## Task 5: Wire AppShell — State, fetchGraphState, Live Overview Data

**Goal:** Add live state to AppShell, call GraphStateWalker on mount, replace maintainer Overview mock data with derived live values, swap the graph placeholder for GraphView.

**Files:**
- Modify: `frontend/components/AppShell.cl.jac`

### Sub-task 5a: Curl-verify GraphStateWalker response shape (TDD red step)

- [ ] **Step 1: Confirm backend is running and curl GraphStateWalker**

```bash
curl -s -X POST http://localhost:8080/walker/GraphStateWalker \
  -H "Content-Type: application/json" -d '{}' \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
rep = r['reports'][0]
print('has_graph:', rep['has_graph'])
print('node count:', len(rep['nodes']))
print('edge count:', len(rep['edges']))
print('latest_analysis:', rep.get('latest_analysis') is not None)
print('sample node keys:', list(rep['nodes'][0].keys()) if rep['nodes'] else 'none')
"
```

Expected output:
```
has_graph: True
node count: <N>
edge count: <M>
latest_analysis: False
sample node keys: ['id', 'path', 'language', 'risk_score', 'is_test']
```

If `has_graph: False`, the graph is not built. Run:
```bash
curl -s -X POST http://localhost:8080/walker/GraphBuilderWalker \
  -H "Content-Type: application/json" \
  -d '{"repo_path": "/home/asunaron/hackathons/ghostwatch-test-target"}' \
  | python3 -m json.tool
```
Then re-run the GraphStateWalker curl until `has_graph: True`.

### Sub-task 5b: Add state and fetch logic to AppShell

- [ ] **Step 2: Add new state vars to AppShell**

Find the existing `has` declarations in AppShell (lines 41–44):
```jac
    has activeSection: str = "Overview",
        repoInput: str = "",
        repoLinked: bool = False,
        repoDisplay: str = "";
```

Replace with:
```jac
    has activeSection: str = "Overview",
        repoInput: str = DEMO_REPO_URL,
        repoLinked: bool = False,
        repoDisplay: str = "",
        graphState: dict | None = None,
        analysisLoading: bool = False,
        analysisResult: dict | None = None,
        animatingPath: list = [];

# NOTE: If jac check fails with an error on `DEMO_REPO_URL` as a has default
# (Jac may only accept literals), keep repoInput: str = "" and instead set it
# in the async can with entry block:
#   async can with entry {
#       repoInput = DEMO_REPO_URL;
#       await fetchGraphState();
#   }
```

- [ ] **Step 3: Add fetchGraphState inside AppShell**

Add after the `has` declarations block and before `def setSection`:

**If async def works (Task 2 confirmed PASS):**
```jac
    async def fetchGraphState() -> None {
        res: Any = await doFetch(
            "/walker/GraphStateWalker",
            {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": "{}"}
        );
        data: Any = await res.json();
        reports: Any = data.get("reports", []);
        if len(reports) > 0 {
            graphState = reports[0];
        }
    }
```

**If async def does NOT work (Task 2 confirmed FAIL) — module-level alternative:**
Add BEFORE the `def parse_repo_slug` function (outside AppShell):
```jac
async def fetchGraphStateHelper(setGraphState: Any) -> None {
    res: Any = await doFetch(
        "/walker/GraphStateWalker",
        {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": "{}"}
    );
    data: Any = await res.json();
    reports: Any = data.get("reports", []);
    if len(reports) > 0 {
        setGraphState(reports[0]);
    }
}
```
Then inside AppShell call it as: `await fetchGraphStateHelper(lambda s: Any { graphState = s; });`

- [ ] **Step 4: Add async can with entry for mount fetch**

After the `fetchGraphState` definition (or after `def setSection` if using module-level helper), add:

```jac
    async can with entry {
        await fetchGraphState();
    }
```

- [ ] **Step 5: Replace summaryCards assignment for maintainer Overview**

Find the existing line (around line 46):
```jac
    summaryCards = CONTRIBUTOR_SUMMARY_CARDS if isContributor else SUMMARY_CARDS;
```

Replace with:
```jac
    live_nodes: list = graphState["nodes"] if graphState else [];
    high_risk_count: int = len([n for n in live_nodes if int(n.get("risk_score", 0)) >= 14]);
    has_graph_live: bool = graphState["has_graph"] if graphState else False;
    latest_pr_live: dict | None = graphState["latest_analysis"] if graphState else None;

    live_summary_cards: list = [
        {
            "label": "Files scanned",
            "value": str(len(live_nodes)) if graphState else "—",
            "delta": "in graph",
            "tone": "frost",
            "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
        },
        {
            "label": "High-risk files",
            "value": str(high_risk_count) if graphState else "—",
            "delta": "above threshold",
            "tone": "cyan",
            "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
        },
        {
            "label": "Latest PR risk",
            "value": (
                latest_pr_live["verdict"].get("overall_risk", "?")
                if latest_pr_live else "None yet"
            ),
            "delta": "analyzed",
            "tone": "aqua",
            "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
        },
        {
            "label": "Graph status",
            "value": "Ready" if has_graph_live else "Building...",
            "delta": "system 1",
            "tone": "amber",
            "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
        }
    ];

    summaryCards = CONTRIBUTOR_SUMMARY_CARDS if isContributor else live_summary_cards;
```

- [ ] **Step 6: Replace walkerItems assignment**

Find:
```jac
    walkerItems = CONTRIBUTOR_WALKER_STATUS if isContributor else WALKER_STATUS;
```

Replace with:
```jac
    walker_state_str: str = "Running" if analysisLoading else ("Active" if has_graph_live else "Idle");
    live_walker_status: list = [
        {"name": "SecurityAuditorWalker", "state": walker_state_str},
        {"name": "CompatibilityCheckerWalker", "state": walker_state_str},
        {"name": "BlastRadiusMapperWalker", "state": walker_state_str}
    ];
    walkerItems = CONTRIBUTOR_WALKER_STATUS if isContributor else live_walker_status;
```

- [ ] **Step 7: Replace attentionItems assignment**

Find:
```jac
    attentionItems = CONTRIBUTOR_ATTENTION_ITEMS if isContributor else ATTENTION_ITEMS;
```

Replace with:
```jac
    latest_incident_live: dict | None = graphState["latest_incident"] if graphState else None;
    live_attention_items: list = [
        {
            "title": "Files in graph",
            "value": f"{len(live_nodes)} nodes"
        },
        {
            "title": "High-risk files",
            "value": f"{high_risk_count} detected"
        },
        {
            "title": "Latest incident",
            "value": latest_incident_live["status"] if latest_incident_live else "None"
        }
    ];
    attentionItems = CONTRIBUTOR_ATTENTION_ITEMS if isContributor else live_attention_items;
```

- [ ] **Step 8: Swap the graph placeholder for GraphView in the maintainer Overview section**

Find the graph panel in the MAINTAINER (not contributor) Overview section — around line 1055. The current content is:

```jac
                    <section
                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                    >
                        <div className="gw-graph-inner-frame"></div>
                        <GraphPlaceholderAccent/>
                        <div className="gw-graph-copy">
                            <span>
                                {graphKicker}
                            </span>
                            <h2>
                                {graphTitle}
                            </h2>
                            <p>
                                {graphBody}
                            </p>
                            <div className="gw-graph-foot">
                                {graphFoot}
                            </div>
                        </div>
                    </section>
```

Replace with:

```jac
                    <section
                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                    >
                        {(graphState and len(graphState["nodes"]) > 0) and
                            <GraphView
                                nodes_data={graphState["nodes"]}
                                edges_data={graphState["edges"]}
                                animatingPath={animatingPath}
                                analysisLoading={analysisLoading}
                            />}
                        {(not graphState or len(graphState["nodes"]) == 0) and
                            <div>
                                <GraphPlaceholderAccent/>
                                <div className="gw-graph-copy">
                                    <span>
                                        {graphKicker}
                                    </span>
                                    <h2>
                                        {graphTitle}
                                    </h2>
                                    <p>
                                        {graphBody}
                                    </p>
                                    <div className="gw-graph-foot">
                                        {graphFoot}
                                    </div>
                                </div>
                            </div>}
                    </section>
```

**Note:** There are TWO graph panel sections in AppShell — one inside `{isContributor and repoLinked and activeSection == "Overview" and ...}` and one inside `{(not isContributor) and repoLinked and activeSection == "Overview" and ...}`. Only replace the SECOND one (the `not isContributor` / maintainer block).

- [ ] **Step 9: Run jac check**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check components/AppShell.cl.jac
```

Fix any errors. Common issues:
- `graphState["nodes"]` when `graphState` might be None — guard with `graphState and ...`
- `int(n.get("risk_score", 0))` — if type checker complains, cast: `score_any: Any = n.get("risk_score", 0); int(score_any)`

- [ ] **Step 10: Start frontend and visually verify**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac start main.jac --dev
```

Navigate to `http://localhost:8000/app/maintainer`. Expected:
- Click Continue (repo URL is pre-filled)
- Graph canvas appears with colored nodes and animated edges
- Summary cards show live values (file count, high-risk count)
- Walker rail shows "Active" or "Idle" based on `has_graph`
- Browser console: no errors

- [ ] **Step 11: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/components/AppShell.cl.jac
git commit -m "feat: wire GraphStateWalker on mount, live Overview data, GraphView replaces placeholder"
```

---

## Task 6: Wire Run Analysis Button + Verdict Panel

**Goal:** Run Analysis button calls OrchestratorWalker with `DEMO_PR_URL`, stores result, starts traversal animation, shows verdict panel.

**Files:**
- Modify: `frontend/components/AppShell.cl.jac`

### Sub-task 6a: Curl-verify OrchestratorWalker response shape (TDD red step)

- [ ] **Step 1: Curl OrchestratorWalker and assert shape**

```bash
curl -s -X POST http://localhost:8080/walker/OrchestratorWalker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/2"}' \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
rep = r['reports'][0]
print('overall_risk:', rep.get('overall_risk'))
print('blast_radius_summary present:', bool(rep.get('blast_radius_summary')))
print('recommendation present:', bool(rep.get('recommendation')))
print('traversal_paths.blast_radius count:', len(rep.get('traversal_paths', {}).get('blast_radius', [])))
print('security_findings count:', len(rep.get('security_findings', [])))
print('compatibility_issues count:', len(rep.get('compatibility_issues', [])))
"
```

Expected:
```
overall_risk: high  (or critical/medium/low)
blast_radius_summary present: True
recommendation present: True
traversal_paths.blast_radius count: <N>  where N > 0
security_findings count: <N>
compatibility_issues count: <M>
```

If `traversal_paths.blast_radius count: 0`, Task 1's fix did not take effect — restart the backend and re-run.

### Sub-task 6b: Implement runAnalysis and verdict panel

- [ ] **Step 2: Add runAnalysis to AppShell**

Add after `fetchGraphState`, still inside AppShell (or at module level if async def failed in Task 2):

```jac
    async def runAnalysis() -> None {
        analysisLoading = True;
        analysisResult = None;
        animatingPath = [];

        body_str: str = f'{{"pr_url": "{DEMO_PR_URL}"}}';
        res: Any = await doFetch(
            "/walker/OrchestratorWalker",
            {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": body_str
            }
        );
        data: Any = await res.json();
        reports: Any = data.get("reports", []);

        if len(reports) > 0 {
            result: Any = reports[0];
            analysisResult = result;
            paths: Any = result.get("traversal_paths", {});
            blast_path: Any = paths.get("blast_radius", []);
            animatingPath = blast_path;
        }

        analysisLoading = False;
        await fetchGraphState();
    }
```

- [ ] **Step 3: Wire the Run Analysis button**

Find the button around line 394 of AppShell:
```jac
                                    <button
                                        type="button"
                                        className="gw-glass-button gw-button-primary"
                                        onClick={lambda -> None { }}
                                    >
                                        {analysisButtonLabel}
                                    </button>
```

Replace with:
```jac
                                    <button
                                        type="button"
                                        className="gw-glass-button gw-button-primary"
                                        onClick={lambda -> None { runAnalysis(); }}
                                        disabled={analysisLoading}
                                    >
                                        {analysisButtonLabel if not analysisLoading else "Analyzing..."}
                                    </button>
```

- [ ] **Step 4: Change the maintainer Overview button label from "Refresh desk" to "Run Analysis"**

Find around line 128:
```jac
                analysisButtonLabel = "Refresh desk";
```

Replace with:
```jac
                analysisButtonLabel = "Run Analysis";
```

- [ ] **Step 5: Add verdict panel to maintainer Overview**

In the maintainer Overview section (`{(not isContributor) and repoLinked and activeSection == "Overview" and ...}`), find the summary grid section:
```jac
                                    <section className="gw-summary-grid">
                                        {[<SummaryCard key={card["label"]} card={card}/> for card in summaryCards]}
                                    </section>
```

Add the verdict panel AFTER the summary grid section and BEFORE the graph panel section:

```jac
                                    {analysisResult and
                                        <section
                                            className="gw-glass-panel gw-fade-up"
                                            style={{
                                                "padding": "20px 24px",
                                                "marginBottom": "16px",
                                                "borderLeft": "3px solid " + (
                                                    "rgba(239,68,68,0.8)"
                                                    if analysisResult.get("overall_risk", "") in ["critical", "high"]
                                                    else "rgba(251,191,36,0.8)"
                                                    if analysisResult.get("overall_risk", "") == "medium"
                                                    else "rgba(125,211,255,0.6)"
                                                )
                                            }}
                                        >
                                            <div style={{"display": "flex", "alignItems": "center", "gap": "12px", "marginBottom": "10px"}}>
                                                <span style={{
                                                    "background": (
                                                        "rgba(239,68,68,0.25)"
                                                        if analysisResult.get("overall_risk", "") in ["critical", "high"]
                                                        else "rgba(251,191,36,0.25)"
                                                        if analysisResult.get("overall_risk", "") == "medium"
                                                        else "rgba(125,211,255,0.15)"
                                                    ),
                                                    "color": "rgba(220,239,255,0.9)",
                                                    "padding": "3px 10px",
                                                    "borderRadius": "20px",
                                                    "fontSize": "11px",
                                                    "fontWeight": "700",
                                                    "textTransform": "uppercase",
                                                    "letterSpacing": "0.05em"
                                                }}>
                                                    {analysisResult.get("overall_risk", "unknown")}
                                                </span>
                                                <span style={{"color": "rgba(220,239,255,0.5)", "fontSize": "12px"}}>
                                                    {str(len(analysisResult.get("security_findings", []))) + " security · " + str(len(analysisResult.get("compatibility_issues", []))) + " compat"}
                                                </span>
                                            </div>
                                            <p style={{"color": "rgba(220,239,255,0.82)", "fontSize": "13px", "marginBottom": "6px", "lineHeight": "1.5"}}>
                                                {analysisResult.get("blast_radius_summary", "")}
                                            </p>
                                            <p style={{"color": "rgba(125,211,255,0.82)", "fontSize": "12px", "fontStyle": "italic"}}>
                                                {analysisResult.get("recommendation", "")}
                                            </p>
                                        </section>}
```

- [ ] **Step 6: Run jac check**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac check components/AppShell.cl.jac
```

Fix any errors. Common: nested ternary in JSX style attrs may need extra parentheses.

- [ ] **Step 7: Commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add frontend/components/AppShell.cl.jac
git commit -m "feat: wire Run Analysis button, verdict panel, traversal animation trigger"
```

---

## Task 7: End-to-End Integration Test

**Goal:** Confirm the full demo flow works: mount → graph loads → Run Analysis → animation → verdict.

**Files:** No code changes — this is a verification task.

- [ ] **Step 1: Start both servers**

Terminal 1 (backend):
```bash
cd /home/asunaron/hackathons/GhostWatch
source .env
GITHUB_TOKEN="$GITHUB_TOKEN" ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL" GITHUB_WEBHOOK_SECRET="$GITHUB_WEBHOOK_SECRET" \
  jac start main.jac --port 8080
```

Terminal 2 (frontend):
```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac start main.jac --dev
```

- [ ] **Step 2: Run through the full demo flow**

1. Open `http://localhost:8000/app/maintainer`
2. Graph canvas should appear immediately with colored nodes + flowing edge animations
3. Summary cards show live counts
4. Walker rail shows "Active" (graph is built)
5. Click "Continue" (repo input is pre-filled)
6. Click "Run Analysis"
7. Button changes to "Analyzing..." and is disabled
8. Nodes pulse with cyan glow (loading state)
9. After 10–30 seconds: verdict panel appears below summary cards
10. Node pulse stops; traversal scan animation begins, sweeping through the blast_radius path on loop
11. Verdict panel shows overall_risk badge, blast_radius_summary, recommendation, finding counts

- [ ] **Step 3: Check browser console**

Open DevTools → Console. Expected: no errors. Acceptable warnings: ReactFlow controlled/uncontrolled prop warnings (cosmetic only).

- [ ] **Step 4: Verify the animation is actually data-driven**

```bash
curl -s -X POST http://localhost:8080/walker/OrchestratorWalker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/2"}' \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
blast = r['reports'][0].get('traversal_paths', {}).get('blast_radius', [])
print('Traversal path length:', len(blast))
print('First 3 node jids:', blast[:3])
"
```

Open DevTools → Elements → find an animated node. Its inline style `animationDelay` should be `0ms` for the first jid, `600ms` for the second, etc. — confirming the animation is mapped to the actual traversal data.

- [ ] **Step 5: Final commit**

```bash
cd /home/asunaron/hackathons/GhostWatch
git add -A
git commit -m "feat: System 1 frontend integration complete — live graph, traversal animation, verdict panel"
```

---

## Notes for Demo Day

1. **Swap `DEMO_PR_URL`** in `frontend/mock_data.cl.jac` to the prepared Jaseci PR before going on stage.
2. **Pre-build the Jaseci graph** on the demo instance before the presentation — `POST /walker/GraphBuilderWalker` with the Jaseci repo path.
3. **Two-worktree setup** (already planned): Instance 1 at `/GhostWatch` port 8080 for System 1 demo, Instance 2 at `/GhostWatch-s2` port 8081 for System 2 demo.
4. If the proxy walker fallback (Option C) was used in Task 0, change the fetch URLs in `frontend/main.jac`'s proxy walkers to point to port 8081 for the System 2 instance if needed.
