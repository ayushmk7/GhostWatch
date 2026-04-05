#!/bin/bash

# ─────────────────────────────────────────────
#  GhostWatch Demo Trigger Commands
# ─────────────────────────────────────────────

# 1. BUILD GRAPH (run once on startup)
curl -s -X POST http://localhost:8080/walker/GraphBuilderWalker \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "ayushmk7/GhostWatch", "branch": "main"}' \
  | python3 -m json.tool


# ─────────────────────────────────────────────

# 2. SYSTEM 1 — Run PR Analysis
curl -s -X POST http://localhost:8080/walker/OrchestratorWalker \
  -H "Content-Type: application/json" \
  -d '{"pr_url": "https://github.com/ayushmk7/GhostWatch/pull/1"}' \
  | python3 -m json.tool


# ─────────────────────────────────────────────

# 3. SYSTEM 2 — Trigger malicious dependency detection
#    clean SHA  : 0a729607995d4fe0e03d091b0430affd02b6602f  (empty deps)
#    evil SHA   : 539abce7d863ab4e00cfa3e42ffbb27a95ec29e2  (evil-data-collector + postinstall)
curl -s -X POST http://localhost:8080/walker/System2PushTriggerWalker \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "ayushmk7/GhostWatch",
    "commit_sha": "539abce7d863ab4e00cfa3e42ffbb27a95ec29e2",
    "parent_sha": "0a729607995d4fe0e03d091b0430affd02b6602f"
  }' \
  | python3 -m json.tool


# ─────────────────────────────────────────────

# 4. CHECK GRAPH STATE
curl -s -X POST http://localhost:8080/walker/GraphStateWalker \
  -H "Content-Type: application/json" \
  -d '{"latest_pr": null, "latest_incident": null, "latest_gap": null}' \
  | python3 -m json.tool
