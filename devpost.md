# GhostWatch — Devpost submission

**Team:** GhostWatch  
**Hackathon:** Jac Hacks  
**Project:** GhostWatch — autonomous code defense with graph-native clarity  

---

## Tagline

GhostWatch watches repos for risky dependency and PR signals, explains impact with a living graph model, and can drive sandbox-backed evidence, optional auto-fix PRs, Discord alerts, and post-merge contributor guidance.

---

## Inspiration

We started GhostWatch at **Jac Hacks** because dependency and PR risk is both urgent and easy to drown in. Supply-chain incidents, typosquatting, and surprising install scripts keep showing up in the news; at the same time, maintainers already face review fatigue and noisy alerts. We wanted something that feels less like “another scanner” and more like **trust and speed**: signals that are explainable, tied to the actual repo structure, and wired into a real workflow.

The name stuck after a late-night whiteboard session: **ghost dependencies**—packages that land in a manifest but never show up in import traces, or changes that *look* innocent in a diff until you see **blast radius** on a graph. We are team **GhostWatch**; the product name and the team name share the same story.

---

## What we learned

1. **System 1 vs System 2**  
   We split the problem cleanly: *System 1* is the static, living model of the repo (files, imports, dependencies, tests/docs hooks, review-style walkers). *System 2* is the webhook-driven pipeline (manifest diffs, sandbox evidence, fix validation, PR automation, Discord, post-merge gap analysis). That separation kept graph building from melting into incident lifecycle code.

2. **Determinism before models**  
   We adopted a hard rule from our design: **do not use LLMs to parse manifests, classify core security signals, or decide whether a structural gap exists**. Parsing, normalization, rule codes, dedupe keys, and ranking stay repeatable. LLMs are for interpretation, wording, and tightly bounded generation when deterministic repair is not enough. That boundary is what makes demos and post-mortems honest.

3. **Integrations fail; state must not**  
   GitHub, Discord, and sandboxes retry, time out, or disagree with you at the worst moment. We learned to treat **persisted incident state and idempotency** as product requirements: one logical incident should not spawn duplicate fix PRs, and a half-finished GitHub call should not “lose” an incident in memory.

4. **Graph-native reasoning**  
   Expressing the repo as nodes and edges turns questions like “phantom import” or “what does this dependency actually touch?” into **query-shaped** problems instead of endless grepping. A little graph vocabulary goes a long way in both the backend and the UI.

---

## How we built it

**Stack**

- **Jac** — shared graph declarations, walkers, and client-aligned patterns where we use Jac on the frontend.
- **GitHub** — webhooks and API for push/merge triggers, manifests at specific refs, branches, and PRs.
- **Discord** — incident alerts and digest-style notifications for maintainers.
- **Sandbox execution** — isolated runs with structured evidence (network, filesystem, processes), not prose-only summaries.
- **Frontend** — maintainer and contributor flows: landing, role selection, security/incident views, graph-oriented summaries, and contributor gap surfaces.

**Architecture (high level)**

\[
\text{GitHub} \xrightarrow{\text{webhook}} \text{Jac backend / walkers} \xrightarrow{} \text{graph + incidents} \xrightarrow{} \text{UI} \parallel \text{Discord} \parallel \text{PRs}
\]

**System 2 pipeline (conceptual)**  
We walk from suspicious manifest changes to typed incidents, run **SandboxExecutor**-style steps for evidence, generate and **re-validate** fixes in a second sandbox when we are confident, then open PRs with structured bodies. After merges, **GapAnalysis** emits a **small, ranked** set of contributor suggestions—on the order of a handful—not a wall of noise.

**Risk levels (deterministic intuition)**  
We treat rule firings as discrete signals. If \(s_i \in \{0,1\}\) indicates rule \(i\), product decisions look like: **critical** when certain high-signal pairs co-occur (for example phantom import plus a material install-script change), **high** when multiple strong signals fire together, **medium** for a single suspicious signal—always backed by explicit rule codes, not a black-box score.

**Repo layout**  
Backend logic lives under `walkers/` (including `ghostwatch/` for System 2), `graph/` for nodes and edges, `integrations/` for GitHub and Discord, and `lib/` for manifests and sandbox helpers. The app entry and shared wiring are rooted at `main.jac` and `jac.toml`. The UI lives under `frontend/` with pages for maintainer and contributor experiences and security/gaps flows.

---

## Challenges we faced

1. **Idempotency** — Natural keys look like (repo, commit SHA, manifest path, dependency name). Retries and webhook duplicates taught us to **update** one incident record instead of spawning parallel “ghost incidents” and duplicate auto-fix PRs.

2. **Sandbox evidence that survives scrutiny** — Summarizing logs is easy; producing **structured IOCs** (outbound attempts, writes outside the workspace, suspicious paths, child processes) is not. We iterated on instrumentation until maintainers could skim a PR body and see *why* we flagged something.

3. **Scope under hackathon time** — Full live autonomy is the north star; **guarded, persisted state** for every mutating external action is the guardrail. We had to be explicit about what ships as “real” versus “demo-shaped” for judges.

4. **Frontend stability while the backend grew** — We prioritized **stable contracts** (graph summaries, incident payloads, gap suggestions) so pages like security and gaps could evolve without throwing away UI work.

---

## Anecdotes from the build (Jac Hacks war stories)

**The duplicate PR that taught us idempotency.**  
On day two, we replayed the same push webhook from GitHub’s delivery UI to debug a 500. Within minutes we had **two** branches named almost the same and two PRs with identical titles. That was the moment we stopped treating “create PR” as a happy path only and wrote dedupe keys into the incident model. Now retries are boring—which is exactly what you want for automation touching real repos.

**The “phantom import” that was just a workspace path.**  
Our graph builder first linked imports using raw strings from the manifest delta without normalizing package names. One dependency looked unused in the graph but was clearly imported in the IDE—turns out we had collapsed **underscores vs hyphens** inconsistently. We added normalization (lowercase, collapse `_` / `.` / `-`, small alias map) and suddenly the phantom-import rule stopped crying wolf on clean changes. **Lesson:** deterministic rules are only as good as deterministic normalization.

**Discord pinged three times in one minute.**  
We wired alerts early and fired on every status transition without checking **stable outcome**. The team channel got “sandboxed,” then “needs_human_review,” then a stray retry. We tightened the contract: Discord fires when the incident reaches a **stable** state (for example malicious with or without fix PR, or inconclusive), and we persist `next_escalation_at` so a 2-hour reminder does not get lost on restart.

**Sandbox timeout vs “maybe malicious.”**  
A flagged package sat on `npm install` until the runner killed the job. We first interpreted that as “no evidence” and almost cleared it. We changed the model: **timeout is its own signal** that bumps toward human review, not auto-clear, because the absence of captured evidence is not the same as benign behavior.

---

## Accomplishments we are proud of

- A clear **System 1 / System 2** architecture that matches how maintainers think: model the repo, then react to events.
- **Deterministic-first** detection and gap ranking, with LLMs scoped to explanation and bounded generation.
- A **Jac Hacks**-ready story: graph-native clarity, webhook-driven pipeline, and a UI that speaks maintainer and contributor languages.

---

## What’s next

- Broader manifest ecosystems and policy packs for org-wide rollout.  
- Deeper graph visualization and drill-down from an incident to exact importers and tests.  
- Hardening the manual test checklist into automated `jac check` / integration smoke tests while keeping live GitHub, Discord, and sandboxes out of CI flakiness.

---

## Try it / links

- **Repository:** (add your public GitHub URL)  
- **Live demo:** (add your deployed URL)  
- **Video:** (add Devpost demo link if required)  

---

## Built with

Jac · GitHub (webhooks & API) · Discord · Sandbox runners (e.g. isolated cloud sandboxes) · Vite / Jac client (frontend toolchain as configured in the repo)

---

*Submitted by team **GhostWatch** for **Jac Hacks**.*
