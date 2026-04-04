# Sentree — Product Requirements Document
**Version 1.0 | JacHacks 2026**

---

## Overview

Sentree is an autonomous multi-agent code guardian built natively in the Jac programming language, protecting the Jac open source repository in real time. It combines two distinct systems: a static multi-walker PR analyzer that reviews pull requests before they merge, and Ghostwatch, a fully autonomous out-of-loop dependency security pipeline that fires on any push and requires zero human intervention until a fix PR is ready to approve.

Sentree is built in Jac, protecting Jac, using Jac's own graph model of itself. The codebase is the graph. The agents are walkers. The language defends itself.

---

## Problem Statement

Open source repositories face two distinct threats that existing tools fail to address together:

**Threat 1 — Code quality and impact blindness.** When a PR touches core logic, existing review tools see the diff in isolation. They have no spatial awareness of how a change propagates through the codebase, no memory of what similar changes broke before, and no separation of concerns between security, compatibility, and blast radius. A single agent producing unaccountable output is not a review system.

**Threat 2 — Supply chain attacks bypassing CI/CD.** The Axios attack on March 31, 2026 demonstrated that sophisticated attackers use compromised maintainer credentials to publish directly to npm, bypassing GitHub Actions entirely. No PR is ever opened. Static code review never fires. The malicious dependency runs its postinstall hook automatically on every developer machine and CI pipeline that installs the package.

Sentree addresses both threats with architecturally distinct systems operating at the right layer.

---

## Target Users

**Primary — Jac/Jaseci maintainers** who need PR review support, dependency security monitoring, and autonomous protection for the core language repository without adding operational overhead.

**Secondary — Open source project maintainers broadly** who want a production-grade repo guardian deployable against any public GitHub repository.

---

## System 1: Sentree Static Analyzer

### What it does
A Discord slash command triggers a multi-walker analysis pipeline against any open PR on the Jac repository. Three specialist walkers traverse a live Jac graph of the codebase in parallel, each analyzing the change from a different angle, and post a structured verdict card to the Jac Discord server within seconds.

### User flow
1. PR opens on `jaseci-labs/jaseci`
2. Maintainer or contributor types `/trigger PR_URL` in Jac Discord
3. Sentree builds the affected subgraph from the PR diff
4. Three walkers traverse the subgraph concurrently
5. A structured Discord verdict card appears with risk score, per-walker findings, and action buttons
6. Maintainer clicks Approve — inline GitHub review comments are posted to the PR
7. Live graph visualization shows the walker traversal animating in real time

### Features

**Repo → Jac Graph Parser**
The entire Jac repository is modeled as a persistent Jac graph. Files are nodes. Import relationships and dependency edges connect them. The graph persists across sessions via Jac's root node — no separate database required. When a PR arrives, Sentree already has the full codebase topology loaded and only processes the affected subgraph.

**Security Auditor Walker**
Traverses the affected subgraph looking for dangerous patterns: credential exposure, unsafe operations, injection vectors, changes to security-critical paths. Uses `by llm()` with full file context injected via `incl_info(here)`. Leaves typed findings as edge annotations on the graph.

**Compatibility Checker Walker**
Traverses the API surface of changed nodes and cross-references against all usages of those APIs elsewhere in the graph. Flags breaking changes, deprecated pattern introductions, and interface mismatches. Knows the difference between internal and public API surfaces.

**Blast Radius Mapper Walker**
Spawns at every changed file node and traverses outward through dependency edges, counting downstream nodes affected. Produces a visual subgraph of the blast zone and a numeric risk score. The larger and more central the affected subgraph, the higher the risk score.

**Discord Verdict Card**
A structured Discord embed containing: overall risk score, per-walker one-line findings, total affected node count, an embedded graph thumbnail showing the blast zone, and two action buttons — Approve Review and Flag for Maintainer. Findings populate incrementally as each walker finishes — no waiting for the full pipeline.

**GitHub PR Comment Writer**
On Approve, translates structured findings into precise inline GitHub review comments posted directly to the relevant files in the PR. Every comment is traceable to the specific walker and graph node that produced it. Not slop, not noise — citable, located findings.

**Live Graph Visualization**
A `jac-client` frontend in the same `.jac` file as the backend. Shows the full codebase graph with affected nodes highlighted. Walker traversal animates in real time as findings are produced. The demo centerpiece — judges can see computation moving through the codebase topology live on screen.

**Backboard Walker Memory**
Each walker is a Backboard assistant with its own persistent memory thread scoped to the Jac repository. The Security Auditor remembers every vulnerability pattern it has flagged historically. The Compatibility Checker accumulates a record of which API changes caused breakage. The Blast Radius Mapper builds a running risk model based on historical impact data. Walkers get smarter with every PR review instead of starting fresh.

---

## System 2: Ghostwatch

### What it does
Ghostwatch is a fully autonomous, out-of-loop security pipeline that fires on any push touching dependency files — no human trigger required. It detects malicious dependencies, executes them in an isolated sandbox, generates a fix, opens a PR, and pings maintainers. The only human action required is clicking Merge on the auto-generated fix PR.

### User flow
1. Any commit pushed to `jaseci-labs/jaseci` that touches `package.json` or `jac.toml`
2. Ghostwatch fires automatically — no human trigger
3. Dependency Diff Walker analyzes the manifest change against the import graph
4. If suspicious: E2B sandbox installs and executes the flagged dependency in isolation
5. If malicious behavior detected: Fix Walker generates a corrected manifest
6. Auto-Fix PR Creator opens a PR with the fix and full behavioral evidence
7. Escalation Notifier pings maintainers in Discord with a one-click merge link
8. Re-pings if no response within 2 hours

### Features

**Dependency Diff Walker**
Fires on any push touching `package.json` or `jac.toml`. Compares the new manifest against the known import graph. Flags any dependency that appears in the manifest but is never imported in the actual codebase — the exact signature of the Axios attack's `plain-crypto-js` injection. Also flags: packages with less than 30 days publishing history, postinstall scripts, and manifest changes with no corresponding GitHub tag or SLSA provenance.

**E2B Sandbox Executor**
Installs flagged dependencies in an isolated Firecracker microVM — dedicated kernel, no shared-kernel Docker escape risk, 150ms boot time. Observes behavior for 30 seconds: outbound network connections, file system writes outside the workspace, process spawns, credential file access, and self-deletion. The sandbox is destroyed after execution. If the Axios attack's `setup.js` ran here, the C2 beacon to `sfrclak[.]com:8000` would be observed and recorded within seconds of install completing.

**Post-Merge Gap Analysis Walker**
Triggers when a PR is successfully merged. Traverses the updated graph looking for structural gaps: modules with no connected test nodes, walker archetypes with no documentation node, features declared in the spec with no implementation node, plugin interfaces with no example. Posts a structured "Contributor Opportunities" card to Discord with three to five scoped, actionable suggestions linked to real gaps in the codebase.

**Fix Generation Walker**
Autonomously generates a corrected manifest: removes the malicious dependency, pins to the last known clean version, validates the fix compiles correctly. Runs a second E2B sandbox with the fixed manifest to confirm the malicious behavior is gone. Commits the fix to a new branch named `ghostwatch/auto-fix-{dep-name}-{timestamp}`.

**Auto-Fix PR Creator**
Opens a GitHub PR against the offending commit without any human involvement. The PR includes: which dependency was flagged and why, the full behavioral evidence from the sandbox execution (network connections attempted, file writes, process spawns), IOCs (C2 domain, file hashes, malware family if identified), and a clear merge prompt. No human triggered this. A human must only click Merge.

**Escalation Notifier**
Pings `@repo-owner` and `@committer` in the Jac Discord server immediately with a summary of the evidence and a direct link to the fix PR. If no merge action is taken within two hours, re-pings with escalation. Respects role-based auth — only designated maintainer roles receive security escalations.

**Role-Based Auth**
Admins can approve PR reviews, trigger analysis, and receive security escalations. Contributors can trigger analysis and receive gap analysis suggestions. Guests can view the live graph visualization only. Discord server roles map to Sentree permission levels.

---

## Success Metrics

- PR verdict card delivered in under 30 seconds from trigger
- Ghostwatch fires and posts Discord alert in under 5 minutes from suspicious push
- Zero false negatives on the Axios attack pattern in demo
- Live graph visualization shows walker traversal animating within 3 seconds of trigger
- Backboard memory demonstrably improves walker findings on repeated similar PRs

---

## Out of Scope

- Auto-merging any fix PR — human approval gate on merge is non-negotiable
- Analyzing private repositories — scoped to `jaseci-labs/jaseci` for the hackathon
- Supporting languages other than Python and Jac for AST parsing in v1
