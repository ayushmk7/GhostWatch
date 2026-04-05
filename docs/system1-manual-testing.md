# System 1 Manual Testing Guide

End-to-end walkthrough for testing the GhostWatch static analyzer backend against the test repo.

**Test repo:** `github.com/Aarosunn/ghostwatch-test-target`
- 4 Python files: `api.py`, `auth.py`, `database.py`, `utils.py`
- Import graph: `api.py → auth.py → database.py`, `api.py → utils.py`
- PR #1 adds `log_event()` to `utils.py` — contains deliberate security issues

---

## Prerequisites

Credentials in `.env` (copy from `.env.example`):
```
GITHUB_TOKEN=...
ANTHROPIC_API_KEY=...
DISCORD_WEBHOOK_URL=...
GITHUB_WEBHOOK_SECRET=...
```

---

## Step 1: Start the server

`jac start` does **not** auto-load `.env`, so pass vars explicitly:

```bash
GITHUB_TOKEN="..." \
ANTHROPIC_API_KEY="..." \
DISCORD_WEBHOOK_URL="..." \
GITHUB_WEBHOOK_SECRET="..." \
jac start main.jac --port 8080
```

Check it's up:
```bash
curl http://localhost:8080/healthz
# → {"status":"ok"}
```

---

## Step 2: Authenticate

Register once (DB persists across restarts at `~/.jac/data/server.db`):

```bash
curl -X POST http://localhost:8080/user/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@ghostwatch.dev","password":"changeme"}'
```

Login and capture token:

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/user/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@ghostwatch.dev","password":"changeme"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

---

## Step 3: Build the codebase graph

```bash
curl -X POST http://localhost:8080/walker/GraphBuilderWalker \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"repo_name":"Aarosunn/ghostwatch-test-target","branch":"main"}'
```

Expected response:
```json
{
  "status": "complete",
  "nodes_built": 4,
  "edges_built": 4,
  "repo": "Aarosunn/ghostwatch-test-target",
  "branch": "main"
}
```

**Idempotent** — calling again returns `"status": "already_built"`. To force a rebuild, clear the DB.

---

## Step 4: Run analysis on PR #1

```bash
curl -X POST http://localhost:8080/walker/OrchestratorWalker \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pr_url":"https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}'
```

Expected verdict:
```json
{
  "overall_risk": "HIGH",
  "risk_score": 75,
  "security_findings": [
    { "severity": "HIGH", "description": "Log injection vulnerability in log_event function", ... },
    { "severity": "MEDIUM", "description": "Information disclosure through uncontrolled logging", ... },
    { "severity": "LOW", "description": "Use of print() instead of proper logging framework", ... }
  ],
  "compatibility_issues": [],
  "affected_node_count": 1,
  "blast_radius_summary": "...",
  "recommendation": "REJECT - ..."
}
```

A Discord notification is also fired to the configured webhook URL.

---

## Step 5: Check graph state

```bash
curl -X POST http://localhost:8080/walker/GraphStateWalker \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected response shape:
```json
{
  "nodes": [ { "id": "...", "path": "utils.py", "risk_score": 15, ... }, ... ],
  "edges": [ { "source": "...", "target": "...", "type": "ImportEdge" }, ... ],
  "node_count": 4,
  "edge_count": 4,
  "latest_analysis": {
    "id": "<verdict_id>",
    "pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/1",
    "verdict": { ... full verdict ... },
    "created_at": "..."
  },
  "has_graph": true
}
```

Note the `latest_analysis.id` — you'll need it for Step 6.

---

## Step 6: Post the PR comment to GitHub

```bash
VERDICT_ID="<id from latest_analysis.id above>"

curl -X POST http://localhost:8080/walker/PRCommentWriterWalker \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"pr_url\":\"https://github.com/Aarosunn/ghostwatch-test-target/pull/1\",\"verdict_id\":\"$VERDICT_ID\"}"
```

Expected: `{"status": "success", "comments_posted": 1}`

Check the actual PR on GitHub — a Markdown comment should appear with the full verdict.

**Idempotent** — calling again returns `{"status": "already_posted", "comments_posted": 0}`.

---

## Step 7: Test the webhook endpoint

### Bad signature → rejected

```bash
curl -X POST http://localhost:8080/walker/GitHubWebhookWalker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {"action":"opened","pull_request":{"html_url":"https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}},
    "signature": "sha256=badbadbadbad"
  }'
```

Expected: `{"error": "Invalid webhook signature", "status": 401}`

### No signature → triggers full analysis

```bash
curl -X POST http://localhost:8080/walker/GitHubWebhookWalker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {"action":"opened","pull_request":{"html_url":"https://github.com/Aarosunn/ghostwatch-test-target/pull/1"}}
  }'
```

Expected: `{"status": "analysis_triggered", "pr_url": "..."}` followed by the full analysis running in the same response.

---

## Unit tests

```bash
python3 -m pytest tests/ -v
```

5 tests:
- HMAC validation accepts correct signature
- HMAC validation rejects wrong signature
- HMAC validation rejects empty signature
- BlastRadiusMapper `_severity_from_hops` returns correct values
- SecurityAuditorWalker with empty `allowed_nodes` visits no nodes

---

## Notes

- **DB persistence:** Graph nodes and PR analysis results survive server restarts. Re-registering the user will fail if already registered — just use the login step.
- **Walker routes use PascalCase:** `/walker/GraphBuilderWalker`, not `/walker/rebuild-graph`.
- **`jac start` port:** defaults to `8000` if `--port` is omitted.
- **Fresh start:** delete `~/.jac/data/server.db` to clear all graph and user data.
