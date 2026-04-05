# GhostWatch System 1 — Manual Testing Plan
**Date:** 2026-04-04  
**Scope:** Tasks 1–11 (backend static analyzer)  
**Server:** `jac start main.jac` (port 8000)  
**Test repo:** `github.com/Aarosunn/ghostwatch-test-target`

---

## Task 1 — Project Bootstrap
*(Covered in prior session — skipped here)*

---

## Task 2 — Graph Schema: Nodes and Edges

### Files
- `graph/nodes.jac` — `FileNode`, `FindingNode`, `PRAnalysisNode`
- `graph/edges.jac` — `ImportEdge`, `BlastEdge`, `FindingEdge`

### What to verify
Task 2 is **pure declarations** — no runtime behavior, no endpoints. You cannot call a curl command that directly exercises just nodes/edges. Instead you verify Task 2 indirectly:

1. **`jac check` passes** — confirms all three node types and three edge types compile cleanly with correct field types and defaults.
2. **`rebuild-graph` succeeds** — the graph builder (Task 6) creates `FileNode`s and `ImportEdge`s; if the schema is broken, this fails.
3. **`graph-state-walker` returns node data** — the graph state walker (Task 10) serializes `FileNode` fields; if field names are wrong, the response is empty or malformed.

### Verification step 1 — jac check

```bash
cd /home/asunaron/hackathons/GhostWatch
jac check graph/nodes.jac
jac check graph/edges.jac
```

**Passing result:** No output (jac check is silent on success).

**Failing result:** Any `E####` error line, e.g.:
```
graph/nodes.jac:4: E1001: Type mismatch ...
```

### Verification step 2 — rebuild-graph creates FileNodes

```bash
curl -s -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "Aarosunn/ghostwatch-test-target", "branch": "main"}' \
  | python3 -m json.tool
```

**Passing result:** Response includes `"status": "ok"` and a `"files"` count > 0:
```json
{
  "status": "ok",
  "files": 4,
  "edges": 3
}
```
(Exact field names may vary — the key is non-zero counts, no error.)

**Failing result:** If node schema is broken, you'll see a Python traceback in the server logs and the response will be a 500 or contain `"error"`.

### Verification step 3 — graph-state-walker returns node fields

```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:** A list of objects each with `path`, `language`, `risk_score`, `is_test` — matching `FileNode`'s declared fields:
```json
[
  {
    "path": "database.py",
    "language": "python",
    "risk_score": 0,
    "is_test": false
  },
  ...
]
```

**Failing result:** Empty list `[]` (graph not built yet — run step 2 first), or fields missing/misnamed if the schema was changed incorrectly.

---

---

## Task 3 — Shared Data Objects (`objects/verdict.jac`)

### Files
- `objects/verdict.jac` — `SecurityFinding`, `CompatibilityIssue`, `ContributorSuggestion`, `VerdictObject`

### What to verify
Like Task 2, this is pure declarations — no endpoints. Verification is indirect:

1. **`jac check` passes** — confirms all four objects compile with correct field types and `sem` annotations.
2. **`orchestrator-walker` returns a verdict with the correct shape** — `VerdictObject` fields appear in the response.
3. **`graph-state-walker` includes `pr_analysis`** — the `VerdictObject` is serialized into `PRAnalysisNode.verdict` and readable back out.

### Verification step 1 — jac check

```bash
cd /home/asunaron/hackathons/GhostWatch
jac check objects/verdict.jac
```

**Passing result:** No output.

**Failing result:** Any `E####` error line. Most likely causes would be a malformed `sem` statement or a type annotation referencing an undefined type.

### Verification step 2 — run a full analysis and inspect the verdict shape

First ensure the graph is built:
```bash
curl -s -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "Aarosunn/ghostwatch-test-target", "branch": "main"}'
```

Then trigger analysis:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** Response contains a verdict object with all `VerdictObject` fields present:
```json
{
  "overall_risk": "high",
  "risk_score": 72,
  "security_findings": [...],
  "compatibility_issues": [...],
  "affected_node_count": 3,
  "blast_radius_summary": "...",
  "recommendation": "...",
  "traversal_paths": {
    "security": [...],
    "compatibility": [...],
    "blast_radius": [...]
  }
}
```

**Failing result:**
- Missing top-level keys (e.g. no `overall_risk`) — field was renamed or removed from `VerdictObject`
- `security_findings` is a list of plain dicts missing fields like `recommendation` — `SecurityFinding` fields changed
- `500` error in server logs — `dict(vars(verdict))` failed because `VerdictObject` wasn't properly constructed

### Verification step 3 — verdict persists in graph state

```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:** Response includes a `pr_analysis` key (or equivalent) containing the serialized `VerdictObject` from the most recent run.

**Failing result:** No `pr_analysis` key — `PRAnalysisNode` was never written, meaning `VerdictObject` serialization in the orchestrator failed silently.

---

## Task 4 — GitHub Integration (`integrations/github.jac` + impl + tests)

### Files
- `integrations/github.jac` — declarations: `PRDiff`, 5 functions
- `integrations/impl/github.impl.jac` — implementations
- `tests/test_core.jac` — 3 HMAC unit tests (+ 2 walker tests added in Task 8)

### What to verify
1. **Automated tests pass** — 3 HMAC validation tests (deterministic, no network)
2. **`fetch_pr_diff` returns correct shape** — call via orchestrator and inspect `PRDiff` fields in server logs
3. **`validate_webhook_signature` rejects bad signatures** — simulate a webhook with a wrong sig

### Verification step 1 — run automated tests

```bash
cd /home/asunaron/hackathons/GhostWatch
PYTHONPATH=/home/asunaron/hackathons/GhostWatch jac test tests/test_core.jac
```

**Passing result:**
```
PASSED test_core.jac::HMAC validation accepts correct signature
PASSED test_core.jac::HMAC validation rejects wrong signature
PASSED test_core.jac::HMAC validation rejects empty signature
...
5 passed
```

**Failing result:** Any `FAILED` line. Most likely cause: `hmac.new` import broken (the `new` keyword pitfall — must use `import hmac;` bare, not `import from hmac { new }`).

### Verification step 2 — webhook signature rejection (simulated)

```bash
curl -s -X POST http://localhost:8000/webhook \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=deadbeef" \
  -d '{"action": "opened", "pull_request": {"html_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}}' \
  | python3 -m json.tool
```

**Passing result:** Server returns a `401` or `{"error": "invalid signature"}` — the request is rejected before any analysis runs.

**Failing result:** Server returns `200` or triggers analysis — signature validation was bypassed or not wired in `main.jac`.

### Verification step 3 — fetch_pr_diff works with real PR

Trigger an analysis (requires graph to be built first):
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** Response contains non-empty `security_findings` or `compatibility_issues`. In server logs (stdout), you should see `fetch_pr_diff` completing without errors.

**Failing result:** 
- `500` with `KeyError` or `IndexError` — URL parsing failed (PR URL format unexpected)
- Empty findings everywhere — `GITHUB_TOKEN` missing from `.env`, so all file contents returned as `""`
- `GithubException: 401` in logs — token expired or missing repo scope

---

## Task 5 — Discord Integration (`integrations/discord.jac` + impl)

### Files
- `integrations/discord.jac` — declarations: `notify_discord`, `notify_discord_error`
- `integrations/impl/discord.impl.jac` — implementations

### What to verify
1. **`jac check` passes** — no syntax errors
2. **Discord message appears in channel** — run a full analysis end-to-end and confirm the message lands
3. **Graceful no-op when URL is unset** — temporarily remove `DISCORD_WEBHOOK_URL` from `.env` and confirm analysis still completes without error

### Verification step 1 — jac check

```bash
cd /home/asunaron/hackathons/GhostWatch
jac check integrations/discord.jac
jac check integrations/impl/discord.impl.jac
```

**Passing result:** No output.

**Failing result:** Any `E####` error — most likely an import issue with `requests` (must use `import requests;` bare with semicolon, not `import from requests { ... }`).

### Verification step 2 — Discord message appears after analysis

Ensure the server is running and graph is built, then trigger analysis:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** Within a few seconds, a message appears in your Discord channel:
```
🟠 PR #1 analyzed — Risk: HIGH
View report → https://github.com/Aarosunn/ghostwatch-test-target/pull/1
```
(Risk level and emoji will vary based on what the LLM found.)

**Failing result:**
- No message in Discord — check server logs for `"DISCORD_WEBHOOK_URL not set"` or `"Discord webhook returned 4xx"`
- `requests.post` fails — `requests` not installed in pyenv global (`pip install requests`)
- Message appears but emoji is ⚪ — `overall_risk` value from `VerdictObject` doesn't match any key in the emoji dict (case mismatch or unexpected value)

### Verification step 3 — graceful no-op without webhook URL

Comment out `DISCORD_WEBHOOK_URL` in `.env`, restart the server, run analysis again:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** Analysis completes successfully, response contains a full verdict, server logs show `"DISCORD_WEBHOOK_URL not set — skipping Discord notification"`. No crash, no 500.

**Failing result:** `500` error or exception traceback — the missing URL was not handled gracefully.

> Restore `DISCORD_WEBHOOK_URL` in `.env` after this test.

---

## Task 6 — Graph Builder (`graph/builder.jac` + impl)

### Files
- `graph/builder.jac` — `GraphBuilderWalker` declaration
- `graph/impl/builder.impl.jac` — `build`, `_should_skip`, `_detect_language`, `_build_import_edges`

### What to verify
1. **Graph builds from scratch** — `rebuild-graph` returns `"complete"` with correct node/edge counts
2. **Idempotency** — calling `rebuild-graph` a second time returns `"already_built"`
3. **Import edges are correct** — `graph-state-walker` shows `ImportEdge`s matching the test repo's known import structure

### Verification step 1 — build graph from scratch

Ensure server is freshly started (empty graph), then:
```bash
curl -s -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "Aarosunn/ghostwatch-test-target", "branch": "main"}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{
  "status": "complete",
  "nodes_built": 4,
  "edges_built": 3,
  "repo": "Aarosunn/ghostwatch-test-target",
  "branch": "main",
  "built_at": "2026-04-04T..."
}
```
`nodes_built: 4` = `database.py`, `auth.py`, `api.py`, `utils.py`. `edges_built: 3` = `api.py → auth.py`, `api.py → utils.py`, `auth.py → database.py`.

**Failing result:**
- `nodes_built: 0` — `GITHUB_TOKEN` missing or `get_repo_tree` failed
- `edges_built: 0` — AST import parsing failed (check server logs for `"Import edge build failed"`)
- `500` error — `fetch_file_content` threw an unhandled exception

### Verification step 2 — idempotency check

Call `rebuild-graph` a second time without restarting the server:
```bash
curl -s -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "Aarosunn/ghostwatch-test-target", "branch": "main"}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{
  "status": "already_built",
  "nodes_built": 4,
  "message": "Graph already exists. Re-call to force rebuild after clearing root."
}
```

**Failing result:** `"status": "complete"` with new nodes added — graph was rebuilt and now has duplicate `FileNode`s, which will cause double findings in analysis.

### Verification step 3 — graph state shows correct import structure

```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:** Response includes 4 file nodes. The import edges should reflect the known structure of `ghostwatch-test-target`:
- `api.py` → imports `auth.py` and `utils.py`
- `auth.py` → imports `database.py`

**Failing result:** Nodes present but no edges — `_build_import_edges` failed silently (check logs). Or nodes missing — file was skipped by extension filter or `_should_skip`.

---

## Task 7 — Walker Declarations

### Files
- `walkers/static/security.jac` — `SecurityAuditorWalker`
- `walkers/static/compatibility.jac` — `CompatibilityCheckerWalker`
- `walkers/static/blast_radius.jac` — `BlastRadiusMapperWalker`

### What to verify
Task 7 is declarations only — no runtime behavior. Verification is `jac check` plus confirming the walker fields appear correctly in analysis output.

### Verification step 1 — jac check all three

```bash
cd /home/asunaron/hackathons/GhostWatch
jac check walkers/static/security.jac
jac check walkers/static/compatibility.jac
jac check walkers/static/blast_radius.jac
```

**Passing result:** No output from any of the three.

**Failing result:** `E####` errors — most likely causes:
- `has allowed_nodes: set = {}` (wrong — `{}` is a dict literal, must be `set()`)
- `sem` statement on a `has` field inline instead of as a standalone statement
- Missing import for `SecurityFinding` or `CompatibilityIssue`

### Verification step 2 — traversal_path populated after analysis

```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

Inspect `traversal_paths` in the response:

**Passing result:**
```json
"traversal_paths": {
  "security": ["database.py", "auth.py"],
  "compatibility": ["api.py"],
  "blast_radius": ["database.py", "auth.py", "api.py"]
}
```
Non-empty lists confirm each walker traversed nodes and populated `traversal_path`.

**Failing result:** Empty lists `[]` for any walker — that walker visited no nodes, meaning `allowed_nodes` was empty or `FileNode`s weren't in the graph.

### Verification step 3 — `_severity_from_hops` unit test

```bash
PYTHONPATH=/home/asunaron/hackathons/GhostWatch jac test tests/test_core.jac
```

**Passing result:** `PASSED` for `"BlastRadiusMapper _severity_from_hops is correct"` — confirms hop 0 = critical, hop 1 = high, hop 2 = medium, hop 3+ = low.

**Failing result:** `FAILED` — the pure logic in `_severity_from_hops` returned unexpected values, meaning the hop→severity mapping in the impl was changed incorrectly.

---

## Task 8 — Walker Implementations

### Files
- `walkers/static/impl/security.impl.jac`
- `walkers/static/impl/compatibility.impl.jac`
- `walkers/static/impl/blast_radius.impl.jac`

### What to verify
1. **Unit tests pass** — `_severity_from_hops` and `SecurityAuditorWalker` empty-nodes test
2. **Security findings appear** — test repo has deliberate SQL injection and hardcoded secrets
3. **Blast radius scores write back to FileNodes** — `graph-state-walker` shows non-zero `risk_score` after analysis
4. **Compatibility walker pre-filter works** — files not using changed APIs produce no findings

### Verification step 1 — unit tests

```bash
PYTHONPATH=/home/asunaron/hackathons/GhostWatch jac test tests/test_core.jac
```

**Passing result:** All 5 tests pass including:
- `"BlastRadiusMapper _severity_from_hops is correct"`
- `"SecurityAuditorWalker with empty allowed_nodes visits no nodes"`

**Failing result:** Either test fails — check that `allowed_nodes` guard uses `jid(here)` not `here.path`, and that `_severity_from_hops` thresholds are 0/1/2/3+.

### Verification step 2 — security findings on test repo

Build graph then run analysis:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** `security_findings` contains at least 2–3 items. Expected findings from the test repo:
- SQL injection in `database.py`
- Hardcoded secrets/credentials
- MD5 hashing used for passwords

**Failing result:**
- Empty `security_findings` — `allowed_nodes` was empty so all nodes were skipped, or `GITHUB_TOKEN` missing so file contents were `""`
- LLM call errors in server logs — `ANTHROPIC_API_KEY` missing from `.env`

### Verification step 3 — blast radius risk scores written to FileNodes

After running analysis, check graph state:
```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:** FileNode objects show non-zero `risk_score` for files in the blast radius:
```json
{"path": "database.py", "risk_score": 18, ...}
{"path": "auth.py", "risk_score": 12, ...}
```

**Failing result:** All `risk_score: 0` — blast radius walker never scored any nodes. Check that `changed_nodes` was populated by the orchestrator before spawning `BlastRadiusMapperWalker`.

### Verification step 4 — hop counter resets correctly (cycle safety)

The test repo has a linear import chain (`api → auth → database`), so no cycles. To confirm the hop counter logic works, check `traversal_paths.blast_radius` in the analysis response — it should list nodes in hop order, not repeat any node twice.

**Passing result:** Each node path appears at most once in `traversal_paths.blast_radius`.

**Failing result:** Repeated entries — the `if here.path in self.affected_nodes` cycle guard is broken.

---

## Task 9 — Orchestrator (`walkers/static/orchestrator.jac` + impl)

### Files
- `walkers/static/orchestrator.jac` — `OrchestratorWalker` declaration
- `walkers/static/impl/orchestrator.impl.jac` — full orchestration logic

### What to verify
1. **Full end-to-end analysis returns a complete verdict** — all `VerdictObject` fields present and non-trivial
2. **Parallel walkers all contribute** — `traversal_paths` shows entries for all three walkers
3. **`PRAnalysisNode` is written to the graph** — persists after the request completes
4. **Error path: no graph built** — orchestrator fails gracefully with a clear error message
5. **Error path: bad PR URL** — fetch fails cleanly, no crash

### Verification step 1 — full end-to-end analysis

Ensure server running and graph built, then:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:** Full verdict with all fields populated:
```json
{
  "overall_risk": "high",
  "risk_score": 65,
  "security_findings": [{"severity": "critical", "description": "...", ...}],
  "compatibility_issues": [],
  "affected_node_count": 3,
  "blast_radius_summary": "...",
  "recommendation": "...",
  "traversal_paths": {
    "security": ["<jid>", "<jid>"],
    "compatibility": ["<jid>"],
    "blast_radius": ["<jid>", "<jid>", "<jid>"]
  }
}
```

**Failing result:**
- `{"error": "No graph built..."}` — run `rebuild-graph` first
- `{"error": "Failed to fetch PR diff..."}` — `GITHUB_TOKEN` missing or PR URL wrong
- `overall_risk: "unknown"` — `_merge_findings` LLM call failed, check `ANTHROPIC_API_KEY`
- Empty `traversal_paths` for any walker — that walker's `allowed_nodes` was empty or spawn failed

### Verification step 2 — PRAnalysisNode persists in graph

Immediately after step 1, poll graph state:
```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:** Response includes a `pr_analysis` section with `pr_url`, `verdict`, and `created_at` matching the just-completed analysis.

**Failing result:** No `pr_analysis` key — `root() ++> PRAnalysisNode(...)` failed, likely due to `dict(vars(verdict))` failing if `verdict` was `None`.

### Verification step 3 — graceful failure: no graph

Restart the server (clears in-memory graph), then immediately call:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{"error": "No graph built. Call POST /walker/rebuild-graph first.", "status": "failed"}
```

**Failing result:** `500` crash — the `not start_node` guard is missing or broken.

### Verification step 4 — graceful failure: bad PR URL

```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/notareal/repo/pull/999"}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{"error": "Failed to fetch PR diff: ...", "status": "failed"}
```

**Failing result:** Unhandled exception / `500` — the `fetch_pr_diff` try/except isn't in place.

---

## Task 10 — Output Layer (`graph_state.jac` + `pr_comment.jac` + impls)

### Files
- `walkers/static/graph_state.jac` + `impl/graph_state.impl.jac`
- `walkers/static/pr_comment.jac` + `impl/pr_comment.impl.jac`

### What to verify
1. **`graph-state-walker` returns correct shape** — nodes, edges, node_count, edge_count, latest_analysis, has_graph
2. **`latest_analysis` updates after each orchestrator run** — `pr_nodes[-1]` picks up the newest
3. **`pr-comment-writer` posts to GitHub and sets `comment_posted`**
4. **Idempotency — second call returns `already_posted`**
5. **Graceful failure: invalid `verdict_id`**

### Verification step 1 — graph state shape

Build graph, run analysis, then:
```bash
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool
```

**Passing result:**
```json
{
  "nodes": [
    {"id": "<jid>", "path": "database.py", "risk_score": 18, "language": "python", "is_test": false},
    ...
  ],
  "edges": [
    {"source": "<jid>", "target": "<jid>", "type": "ImportEdge"},
    ...
  ],
  "node_count": 4,
  "edge_count": 3,
  "latest_analysis": {
    "id": "<jid>",
    "pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1",
    "verdict": {...},
    "created_at": "2026-04-04T..."
  },
  "has_graph": true
}
```

**Failing result:**
- `"nodes": []` — graph not built, call `rebuild-graph` first
- `"latest_analysis": null` — no analysis run yet, call `orchestrator-walker` first
- `"edge_count": 0` with `"node_count": 4` — import edges not built (AST parsing failed in Task 6)

### Verification step 2 — latest_analysis updates after second run

Run the orchestrator a second time (same PR), then call graph-state-walker:
```bash
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}'

curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['latest_analysis']['created_at'])"
```

**Passing result:** The `created_at` timestamp is newer than the first run — `pr_nodes[-1]` picked up the latest `PRAnalysisNode`.

**Failing result:** Same timestamp as before — new `PRAnalysisNode` wasn't written, or `[-1]` is returning the first node instead of last.

### Verification step 3 — post PR comment to GitHub

Get the `verdict_id` from graph-state-walker's `latest_analysis.id`, then:
```bash
VERDICT_ID="<paste id from latest_analysis>"

curl -s -X POST http://localhost:8000/walker/pr-comment-writer \
  -H "Content-Type: application/json" \
  -d "{\"pr_url\": \"https://github.com/Aarosunn/ghostwatch-test-target/pull/1\", \"verdict_id\": \"$VERDICT_ID\"}" \
  | python3 -m json.tool
```

**Passing result:**
```json
{"status": "success", "comments_posted": 1}
```
And a GhostWatch comment appears on the GitHub PR at `github.com/Aarosunn/ghostwatch-test-target/pull/1`.

**Failing result:**
- `{"error": "PRAnalysisNode <id> not found"}` — wrong `verdict_id` or graph was rebuilt (clearing old nodes)
- `{"error": "...GithubException..."}` — `GITHUB_TOKEN` missing write permissions or expired
- Comment appears but is plain template (not LLM-formatted) — `_format_verdict_comment` LLM call failed, fell back to hardcoded template

### Verification step 4 — idempotency

Call pr-comment-writer again with the same `verdict_id`:
```bash
curl -s -X POST http://localhost:8000/walker/pr-comment-writer \
  -H "Content-Type: application/json" \
  -d "{\"pr_url\": \"https://github.com/Aarosunn/ghostwatch-test-target/pull/1\", \"verdict_id\": \"$VERDICT_ID\"}" \
  | python3 -m json.tool
```

**Passing result:**
```json
{"status": "already_posted", "comments_posted": 0}
```
No second comment on GitHub.

**Failing result:** `{"status": "success", "comments_posted": 1}` and a duplicate comment posted — `comment_posted` flag wasn't written back to `target.verdict`.

### Verification step 5 — graceful failure: bad verdict_id

```bash
curl -s -X POST http://localhost:8000/walker/pr-comment-writer \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1", "verdict_id": "fake-id-123"}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{"error": "PRAnalysisNode fake-id-123 not found", "status": "failed"}
```

**Failing result:** `500` crash — `target` was `None` and accessed without the `not target` guard.

---

## Task 11 — `main.jac`: Entry Point + Webhook Walker

### Files
- `main.jac` — all imports, `GitHubWebhookWalker`, `with entry` startup block

### What to verify
1. **Server starts cleanly** — `jac start main.jac` boots without errors
2. **All endpoints are live** — each walker endpoint responds
3. **Webhook triggers analysis on `pull_request` opened** — simulated webhook payload
4. **Webhook rejects bad signature** — HMAC validation blocks forged payloads
5. **Non-PR events are acknowledged but not analyzed** — `push` event falls through

### Verification step 1 — server starts

```bash
cd /home/asunaron/hackathons/GhostWatch
jac start main.jac
```

**Passing result:** Server prints startup lines and begins listening:
```
GhostWatch System 1 ready.
Step 1: POST /walker/rebuild-graph to build the codebase graph.
Step 2: Configure GitHub webhook -> POST /walker/git-hub-webhook-walker
INFO: Uvicorn running on http://0.0.0.0:8000
```

**Failing result:**
- `ModuleNotFoundError` — a module in the import block can't be resolved; check for typos in module paths
- `E####` jac error — a walker or node type in an imported module has a syntax error
- Server starts but some endpoints 404 — a `walker:pub` declaration was changed to `walker` (lost the `pub`)

### Verification step 2 — all endpoints respond

```bash
# Each should return JSON, not 404
curl -s -X POST http://localhost:8000/walker/graph-state-walker | python3 -m json.tool
curl -s -X POST http://localhost:8000/walker/rebuild-graph | python3 -m json.tool
```

**Passing result:** Both return JSON responses (even if graph is empty or already built).

**Failing result:** `404 Not Found` — walker not imported in `main.jac` or `walker:pub` missing.

### Verification step 3 — webhook triggers analysis

Simulate a GitHub `pull_request` opened event:
```bash
curl -s -X POST http://localhost:8000/walker/git-hub-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {
      "action": "opened",
      "pull_request": {
        "html_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"
      }
    },
    "signature": ""
  }' \
  | python3 -m json.tool
```

**Passing result:**
```json
{"status": "analysis_triggered", "pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}
```
Analysis runs asynchronously — poll `graph-state-walker` to see the result appear.

**Failing result:**
- `{"status": "webhook_received"}` — action filter didn't match; check `action` field is `"opened"`
- `{"error": "Invalid webhook signature"}` — signature check triggered unexpectedly; ensure `signature: ""` and `GITHUB_WEBHOOK_SECRET` unset in `.env` for dev testing

### Verification step 4 — webhook signature rejection

```bash
curl -s -X POST http://localhost:8000/walker/git-hub-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {"action": "opened", "pull_request": {"html_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}},
    "signature": "sha256=deadbeef"
  }' \
  | python3 -m json.tool
```

Note: requires `GITHUB_WEBHOOK_SECRET` to be set in `.env` for the check to activate.

**Passing result:**
```json
{"error": "Invalid webhook signature", "status": 401}
```

**Failing result:** `{"status": "analysis_triggered"}` — signature check was skipped, either secret not set or `validate_webhook_signature` not called.

### Verification step 5 — non-PR event falls through

```bash
curl -s -X POST http://localhost:8000/walker/git-hub-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{"event_type": "push", "payload": {}, "signature": ""}' \
  | python3 -m json.tool
```

**Passing result:**
```json
{"status": "webhook_received", "event": "push"}
```
No analysis triggered.

**Failing result:** `500` crash — `self.payload.get("action", "")` failed because `payload` was not a dict (type coercion issue).

---

## Full System Smoke Test

Run this sequence from a clean server start to verify all 11 tasks end-to-end:

```bash
# 1. Start server (separate terminal)
cd /home/asunaron/hackathons/GhostWatch && jac start main.jac

# 2. Build graph
curl -s -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "Aarosunn/ghostwatch-test-target", "branch": "main"}' \
  | python3 -m json.tool

# 3. Run analysis
curl -s -X POST http://localhost:8000/walker/orchestrator-walker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}' \
  | python3 -m json.tool

# 4. Check graph state (nodes, edges, latest_analysis all present)
curl -s -X POST http://localhost:8000/walker/graph-state-walker \
  | python3 -m json.tool

# 5. Post PR comment (use latest_analysis.id from step 4)
curl -s -X POST http://localhost:8000/walker/pr-comment-writer \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1", "verdict_id": "<id from step 4>"}' \
  | python3 -m json.tool

# 6. Run automated unit tests
PYTHONPATH=/home/asunaron/hackathons/GhostWatch jac test tests/test_core.jac
```

**Full passing result:** Steps 2–4 return JSON with non-zero counts, step 5 shows a comment on the GitHub PR, step 6 shows 5 tests passed.
