# System 2 Manual Test Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manually verify all 9 System 2 walkers behave correctly end-to-end against the live backend and test repo.

**Architecture:** System 2 is a chain of walkers triggered by GitHub webhook events. Each walker is tested in isolation first (offline/unit), then as part of the full chain (live GitHub + Discord). The manual trigger walkers (Tasks 7/8) are used to drive the live chain without needing real webhook delivery.

**Tech Stack:** Jac, PyGithub, Discord webhook, local subprocess sandbox, curl

**Prerequisites before running any test:**
- Backend running: `GITHUB_TOKEN="..." ANTHROPIC_API_KEY="..." DISCORD_WEBHOOK_URL="..." GITHUB_WEBHOOK_SECRET="..." jac start main.jac --port 8080`
- Test repo available (see dev_setup.md for repo name/credentials)
- Replace `OWNER/REPO`, `COMMIT_SHA`, `MERGE_SHA` with real values from the test repo

---

## Task 1: `GitHubSystem2WebhookWalker`

**Files:** `walkers/ghostwatch/github_system2_webhook.jac`, `walkers/ghostwatch/impl/github_system2_webhook.impl.jac`

- [ ] **Step 1: Unknown event type returns noop**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{"event_type": "ping", "payload": {}, "signature": "", "raw_body": ""}'
```
Expected: `{"status": "noop", "event": "ping"}`

- [ ] **Step 2: Push event with no manifest files returns push_no_manifest**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "push",
    "payload": {
      "repository": {"full_name": "OWNER/REPO"},
      "after": "COMMIT_SHA_NO_MANIFEST"
    },
    "signature": "",
    "raw_body": ""
  }'
```
Expected: `{"status": "push_no_manifest"}`
Note: Use a commit SHA where only `.jac` or `.md` files changed — no manifest files.

- [ ] **Step 3: Push event with manifest file dispatches dep diff**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "push",
    "payload": {
      "repository": {"full_name": "OWNER/REPO"},
      "after": "COMMIT_SHA_WITH_MANIFEST"
    },
    "signature": "",
    "raw_body": ""
  }'
```
Expected: `{"status": "dependency_diff_dispatched", "manifest_count": 1}`
Note: Use a commit SHA where `requirements.txt` or `package.json` was changed.

- [ ] **Step 4: Pull request opened (not merged) is ignored**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {
      "action": "opened",
      "pull_request": {"merged": false}
    },
    "signature": "",
    "raw_body": ""
  }'
```
Expected: `{"status": "pr_ignored", "action": "opened"}`

- [ ] **Step 5: Pull request closed and merged dispatches gap analysis**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "pull_request",
    "payload": {
      "action": "closed",
      "pull_request": {
        "merged": true,
        "merge_commit_sha": "MERGE_SHA",
        "base": {"repo": {"full_name": "OWNER/REPO"}}
      }
    },
    "signature": "",
    "raw_body": ""
  }'
```
Expected: `{"status": "gap_analysis_dispatched"}`

- [ ] **Step 6: Invalid HMAC signature returns 401**

```bash
curl -s -X POST http://localhost:8080/walker/github-system2-webhook-walker \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "push",
    "payload": {},
    "signature": "sha256=deadbeef",
    "raw_body": "test"
  }'
```
Expected: `{"status": 401, "error": "Invalid webhook signature"}`
Note: Requires `GITHUB_WEBHOOK_SECRET` set in the server environment.

---

## Task 2: `DependencyDiffWalker`

**Files:** `walkers/ghostwatch/dep_diff.jac`, `walkers/ghostwatch/impl/dep_diff.impl.jac`

**Prerequisites:**
- Graph must be built against `ghostwatch-test-target` first so phantom import detection works
- Need two commit SHAs from `ghostwatch-test-target`: one where a manifest was changed (`COMMIT_SHA_WITH_MANIFEST`) and its parent (`PARENT_SHA`)
- The manifest change must add a package not imported anywhere in the codebase

- [ ] **Step 1: Build the graph against ghostwatch-test-target**

```bash
curl -s -X POST http://localhost:8080/walker/graph-builder-walker \
  -H "Content-Type: application/json" \
  -d '{"repo_url": "https://github.com/Aarosunn/ghostwatch-test-target"}'
```
Expected: `{"status": "graph_built"}` (or similar success response)

- [ ] **Step 2: Run dep diff against a manifest-changing commit**

```bash
curl -s -X POST http://localhost:8080/walker/dependency-diff-walker \
  -H "Content-Type: application/json" \
  -d '{
    "repo_full_name": "Aarosunn/ghostwatch-test-target",
    "commit_sha": "COMMIT_SHA_WITH_MANIFEST",
    "parent_sha": "PARENT_SHA",
    "manifest_paths": ["package.json"]
  }'
```
Expected: `{"status": "dep_diff_complete"}`

- [ ] **Step 3: Verify incident node was created in graph state**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: response includes at least one incident with `dependency_name` matching the added package and `status` of `"detected"`, `"sandboxed"`, or `"malicious"`.

- [ ] **Step 4: Verify idempotency — re-running same commit does not create duplicate incident**

Re-run the same curl from Step 2 verbatim.
Then re-check graph state from Step 3.
Expected: same number of incidents as before, no duplicates for the same `dedupe_key`.

- [ ] **Step 5: Run dep diff against a commit with no manifest changes**

```bash
curl -s -X POST http://localhost:8080/walker/dependency-diff-walker \
  -H "Content-Type: application/json" \
  -d '{
    "repo_full_name": "Aarosunn/ghostwatch-test-target",
    "commit_sha": "COMMIT_SHA_NO_MANIFEST",
    "parent_sha": "PARENT_SHA_NO_MANIFEST",
    "manifest_paths": ["requirements.txt"]
  }'
```
Expected: `{"status": "dep_diff_complete"}` with no new incidents created (verify via graph state).

## Task 3: `SandboxExecutorWalker`

**Files:** `walkers/ghostwatch/sandbox.jac`, `walkers/ghostwatch/impl/sandbox.impl.jac`, `lib/impl/sandbox_exec.impl.jac`

**Prerequisites:**
- At least one `GhostwatchIncidentNode` must exist in the graph (created by Task 2 tests)
- Grab the incident JID from the graph state response in Task 2 Step 3
- Replace `INCIDENT_JID` below with that value
- **Important:** `GraphStateWalker` only returns the single most recently updated incident. Grab the JID before creating any new incidents, or you'll lose track of earlier ones.

- [ ] **Step 1: Get a valid incident JID from graph state**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: response includes incidents list — copy the `jid` field of any incident with `status != "cleared"`.

- [ ] **Step 2: Manually trigger sandbox on a known incident**

```bash
curl -s -X POST http://localhost:8080/walker/sandbox-executor-walker \
  -H "Content-Type: application/json" \
  -d '{"incident_jid": "INCIDENT_JID"}'
```
Expected: `{"status": "malicious", "jid": "INCIDENT_JID"}` (if incident has `risk_level: "critical"`)
OR: `{"status": "needs_human_review", "jid": "INCIDENT_JID"}` (if package doesn't exist on PyPI/npm)
OR: `{"status": "cleared", "jid": "INCIDENT_JID"}` (if package installed cleanly with no hostile signals)

- [ ] **Step 3: Verify incident node updated in graph state**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: the incident's `status` matches what Step 2 reported. `sandbox_result` and `behavioral_trace` fields are now populated (non-empty dicts).

- [ ] **Step 4: Verify critical risk override forces malicious**

Check graph state for the incident created from the demo commit (the one with `phantom_import` + `new_postinstall` → `risk_level: "critical"`).
Expected: `status == "malicious"` regardless of whether the package actually installed.

- [ ] **Step 5: Verify sandbox on unknown JID returns error**

```bash
curl -s -X POST http://localhost:8080/walker/sandbox-executor-walker \
  -H "Content-Type: application/json" \
  -d '{"incident_jid": "nonexistent-jid-000"}'
```
Expected: `{"error": "incident not found", "jid": "nonexistent-jid-000"}`

## Task 4: `FixGenerationWalker`

**Files:** `walkers/ghostwatch/fix_gen.jac`, `walkers/ghostwatch/impl/fix_gen.impl.jac`

**Prerequisites:**
- A `GhostwatchIncidentNode` with `status == "malicious"` must exist in the graph
- Use the same `INCIDENT_JID` from Task 3
- The incident's repo must have a valid `GITHUB_TOKEN` with write access (needed to fetch manifest content at parent SHA)
- **Important:** Keep `ghostwatch-test-target`'s `package.json` minimal (few or no other dependencies) — the fix validation sandbox installs the full manifest and will fail if other deps can't resolve

- [ ] **Step 1: Manually trigger fix generation on a malicious incident**

```bash
curl -s -X POST http://localhost:8080/walker/fix-generation-walker \
  -H "Content-Type: application/json" \
  -d '{"incident_jid": "INCIDENT_JID"}'
```
Expected: `{"fix_validated": true}` — fix inverted cleanly and sandbox install passed.
If you get `{"fix_validated": false}`: the fixed manifest failed sandbox install — check that `ghostwatch-test-target`'s `package.json` has no other deps that fail to resolve in a clean npm environment.

- [ ] **Step 2: Verify PRCreatorWalker was spawned (check for PR on ghostwatch-test-target)**

After Step 1 returns `fix_validated: true`, check GitHub:
```bash
gh pr list --repo Aarosunn/ghostwatch-test-target
```
Expected: a PR opened by GhostWatch with title `"GhostWatch: address malicious dependency <name>"`.

- [ ] **Step 3: Verify incident updated_at was refreshed**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_incident.updated_at` is more recent than before Step 1.

- [ ] **Step 4: Verify unknown JID returns error**

```bash
curl -s -X POST http://localhost:8080/walker/fix-generation-walker \
  -H "Content-Type: application/json" \
  -d '{"incident_jid": "nonexistent-jid-000"}'
```
Expected: `{"error": "incident not found"}`

## Task 5: `GhostwatchPRCreatorWalker`

**Files:** `walkers/ghostwatch/pr_creator.jac`, `walkers/ghostwatch/impl/pr_creator.impl.jac`

**Prerequisites:**
- `GITHUB_TOKEN` must have `repo` write scope on `ghostwatch-test-target`
- **Do NOT reuse the same incident JID from Task 4** — if Task 4 succeeded, `fix_pr_url` is already set and the walker will immediately return `idempotent_skip`, skipping the creation path entirely
- Push a second commit to `ghostwatch-test-target` adding a different fake package (e.g. `"spy-logger": "latest"`) with a postinstall script to generate a fresh malicious incident, then use its JID as `INCIDENT_JID_2`
- `FIXED_MANIFEST_CONTENT` for this incident is `{"name":"ghostwatch-test-target","version":"1.0.0","dependencies":{}}`

- [ ] **Step 0: Verify correct endpoint name**

```bash
curl -s http://localhost:8080/walker/ghostwatch-pr-creator-walker
curl -s http://localhost:8080/walker/ghostwatch-p-r-creator-walker
```
Use whichever returns something other than a 404. Replace the URL in all steps below accordingly.

- [ ] **Step 1: Manually trigger PR creation on a fresh malicious incident**

```bash
curl -s -X POST http://localhost:8080/walker/ghostwatch-p-r-creator-walker \
  -H "Content-Type: application/json" \
  -d '{
    "incident_jid": "INCIDENT_JID_2",
    "validated_fix_content": "{\"name\":\"ghostwatch-test-target\",\"version\":\"1.0.0\",\"dependencies\":{}}"
  }'
```
Expected: `{"pr_url": "https://github.com/Aarosunn/ghostwatch-test-target/pull/N", "branch": "ghostwatch/auto-fix-spy-logger-TIMESTAMP"}`

- [ ] **Step 2: Verify PR exists on GitHub**

```bash
gh pr list --repo Aarosunn/ghostwatch-test-target
```
Expected: PR titled `"GhostWatch: address malicious dependency spy-logger"` is open.

- [ ] **Step 3: Verify Discord notification fired**

Check the Discord channel configured in `DISCORD_WEBHOOK_URL`.
Expected: a message about the malicious dependency with the PR URL.

- [ ] **Step 4: Verify incident node updated**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_incident.fix_pr_url` is set to the PR URL from Step 1. `alert_state == "pr_opened"`.

- [ ] **Step 5: Verify idempotency — re-running does not open a second PR**

Re-run the same curl from Step 1 verbatim.
Expected: `{"status": "idempotent_skip", "pr": "https://github.com/..."}` — no new PR created.
Verify on GitHub: still only one open GhostWatch PR for `spy-logger`.

## Task 6: `GapAnalysisWalker`

**Files:** `walkers/ghostwatch/gap_analysis.jac`, `walkers/ghostwatch/impl/gap_analysis.impl.jac`

**Prerequisites:**
- Graph must be built against `ghostwatch-test-target` (Task 2 Step 1)
- `DISCORD_WEBHOOK_URL` set in server environment
- Replace `MERGE_SHA` with any valid commit SHA from `ghostwatch-test-target` (doesn't need to be a real merge commit — it's stored as metadata only)

- [ ] **Step 1: Trigger gap analysis manually**

```bash
curl -s -X POST http://localhost:8080/walker/gap-analysis-walker \
  -H "Content-Type: application/json" \
  -d '{
    "repo_full_name": "Aarosunn/ghostwatch-test-target",
    "merge_commit_sha": "MERGE_SHA"
  }'
```
Expected: `{"suggestions": 4}` (one per source file in ghostwatch-test-target: database.py, auth.py, api.py, utils.py — all missing tests)

- [ ] **Step 2: Verify GapAnalysisNode in graph state**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_gap_analysis` is populated with `merge_commit_sha` matching `MERGE_SHA` and `suggestions` list of 4 items, each with `suggestion_type: "missing_tests"`.

- [ ] **Step 3: Verify Discord gap digest fired**

Check the Discord channel.
Expected: a message listing the suggested files to improve (database.py, auth.py, api.py, utils.py).

- [ ] **Step 4: Verify behavior with empty graph**

Stop the server, delete `.jac/data/` to clear the graph, restart, then run Step 1 again without building the graph first.
```bash
curl -s -X POST http://localhost:8080/walker/gap-analysis-walker \
  -H "Content-Type: application/json" \
  -d '{"repo_full_name": "Aarosunn/ghostwatch-test-target", "merge_commit_sha": "MERGE_SHA"}'
```
Expected: `{"suggestions": 0}` — no FileNodes in graph so nothing to rank. Discord digest still fires (empty).

## Task 7: `System2PushTriggerWalker`

**Files:** `walkers/ghostwatch/system2_hooks.jac`, `walkers/ghostwatch/impl/system2_hooks.impl.jac`

**Prerequisites:**
- Graph built against `ghostwatch-test-target`
- A commit on `ghostwatch-test-target` that adds `evil-data-collector` + postinstall script to `package.json`
- Get SHAs:
```bash
COMMIT_SHA=$(gh api repos/Aarosunn/ghostwatch-test-target/commits/main --jq '.sha')
PARENT_SHA=$(gh api repos/Aarosunn/ghostwatch-test-target/commits/$COMMIT_SHA --jq '.parents[0].sha')
echo "commit: $COMMIT_SHA  parent: $PARENT_SHA"
```

- [ ] **Step 1: Trigger the full System 2 pipeline via push trigger**

```bash
curl -s -X POST http://localhost:8080/walker/system2-push-trigger-walker \
  -H "Content-Type: application/json" \
  -d '{
    "repo_full_name": "Aarosunn/ghostwatch-test-target",
    "commit_sha": "COMMIT_SHA",
    "parent_sha": "PARENT_SHA",
    "manifest_paths": ["package.json"]
  }'
```
Expected: `{"status": "push_dispatched"}`

- [ ] **Step 2: Verify full pipeline fired — check graph state for new incident**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_incident` shows `dependency_name: "evil-data-collector"`, `status: "malicious"`, `fix_pr_url` populated.

- [ ] **Step 3: Verify GitHub PR was opened**

```bash
gh pr list --repo Aarosunn/ghostwatch-test-target
```
Expected: PR titled `"GhostWatch: address malicious dependency evil-data-collector"` is open.

- [ ] **Step 4: Verify Discord malicious incident notification fired**

Check Discord channel.
Expected: notification with `evil-data-collector` flagged as malicious and PR URL included.

## Task 8: `System2MergeTriggerWalker`

**Files:** `walkers/ghostwatch/system2_hooks.jac`, `walkers/ghostwatch/impl/system2_hooks.impl.jac`

**Prerequisites:**
- Graph built against `ghostwatch-test-target`
- Any valid commit SHA from `ghostwatch-test-target` for `MERGE_SHA`

- [ ] **Step 1: Trigger gap analysis via merge trigger**

```bash
curl -s -X POST http://localhost:8080/walker/system2-merge-trigger-walker \
  -H "Content-Type: application/json" \
  -d '{
    "repo_full_name": "Aarosunn/ghostwatch-test-target",
    "merge_commit_sha": "MERGE_SHA"
  }'
```
Expected: `{"status": "merge_dispatched"}`

- [ ] **Step 2: Verify GapAnalysisNode created in graph state**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_gap_analysis` is populated with `merge_commit_sha` matching `MERGE_SHA` and a non-empty `suggestions` list.

- [ ] **Step 3: Verify Discord gap digest fired**

Check Discord channel.
Expected: message listing suggested files to improve from `ghostwatch-test-target`.

## Task 9: `System2EscalationTickWalker`

**Files:** `walkers/ghostwatch/system2_hooks.jac`, `walkers/ghostwatch/impl/system2_hooks.impl.jac`

**Prerequisites:**
- At least one `GhostwatchIncidentNode` with `fix_pr_url` set and `alert_state == "pr_opened"`
- `next_escalation_at` on the incident must be <= current Unix timestamp for escalation to fire
- Since `next_escalation_at` is set to `now + 7200` by PRCreatorWalker, the easiest way to test is to use an incident whose PR was opened more than 2 hours ago, OR manually note that the sweep will return cleanly but no Discord message fires until the 2 hours pass

- [ ] **Step 1: Run escalation sweep before 2 hours — verify it runs but doesn't escalate**

```bash
curl -s -X POST http://localhost:8080/walker/system2-escalation-tick-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `{"status": "escalation_sweep"}` — sweep completes, no Discord message fires (incident not yet eligible).

- [ ] **Step 2: Run escalation sweep after 2 hours have passed**

Wait until 2 hours after the PR was opened in Task 5/7, then re-run Step 1.
Expected: `{"status": "escalation_sweep"}` — Discord escalation notification fires for the incident.

- [ ] **Step 3: Verify incident marked as escalated**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_incident.alert_state == "escalated"`.

- [ ] **Step 4: Verify idempotency — re-running does not re-escalate**

Re-run Step 1 again immediately after Step 2.
Expected: `{"status": "escalation_sweep"}` — no second Discord message fires. `alert_state` remains `"escalated"`.

## Task 9: `System2EscalationTickWalker`

**Files:** `walkers/ghostwatch/system2_hooks.jac`, `walkers/ghostwatch/impl/system2_hooks.impl.jac`

**Prerequisites:**
- At least one `GhostwatchIncidentNode` with `fix_pr_url` set and `alert_state == "pr_opened"`
- `next_escalation_at` on the incident must be <= current Unix timestamp for escalation to fire
- Since `next_escalation_at` is set to `now + 7200` by PRCreatorWalker, the easiest way to test is to use an incident whose PR was opened more than 2 hours ago, OR manually note that the sweep will return cleanly but no Discord message fires until the 2 hours pass

- [ ] **Step 1: Run escalation sweep before 2 hours — verify it runs but doesn't escalate**

```bash
curl -s -X POST http://localhost:8080/walker/system2-escalation-tick-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `{"status": "escalation_sweep"}` — sweep completes, no Discord message fires (incident not yet eligible).

- [ ] **Step 2: Run escalation sweep after 2 hours have passed**

Wait until 2 hours after the PR was opened in Task 5/7, then re-run Step 1.
Expected: `{"status": "escalation_sweep"}` — Discord escalation notification fires for the incident.

- [ ] **Step 3: Verify incident marked as escalated**

```bash
curl -s -X POST http://localhost:8080/walker/graph-state-walker \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: `latest_incident.alert_state == "escalated"`.

- [ ] **Step 4: Verify idempotency — re-running does not re-escalate**

Re-run Step 1 again immediately after Step 2.
Expected: `{"status": "escalation_sweep"}` — no second Discord message fires. `alert_state` remains `"escalated"`.
