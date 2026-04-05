# System 2 implementation summary

This document records what was implemented from [`docs/system2design.md`](docs/system2design.md), aligned with shared contracts from the System 1 plan/spec (without rebuilding the full System 1 orchestrator).

## Shared model

- **`graph/nodes.jac`**: `DependencyNode`, `DocumentationNode`, `TestNode`, `GhostwatchIncidentNode`, `GapAnalysisNode`; `PRAnalysisNode` field order fixed for Jac (required fields before defaulted ones).
- **`graph/edges.jac`**: `DependencyEdge`, `FindingEdge` (plus existing `ImportEdge`, `BlastEdge`).
- **`objects/verdict.jac`**: `ContributorSuggestion`, `VerdictObject` (field order fixed for Jac).
- **`objects/sandbox.jac`**: `SuspiciousDependency`, `SandboxResult`, `BehavioralTrace`, `FixValidationResult`.

## Deterministic core (no `by llm` for parsing/rules)

- **`lib/manifest.jac`** + **`lib/impl/manifest.impl.jac`**: normalization, dedupe key, manifest parsing (`package.json`, `requirements.txt`, `jac.toml` / `[dependencies]` + `[project.dependencies]` lines), delta, rule classification, manifest fix inversion, gap ranking helpers.
- **`lib/sandbox_exec.jac`** + **`lib/impl/sandbox_exec.impl.jac`**: local **subprocess** npm/pip install with structured fields (live **E2B** is not wired in code; design’s E2B key is in **`.env.example`** for manual use).

## Integrations

- **`integrations/github.jac`** + **`integrations/impl/github.impl.jac`**: webhook HMAC, tree/file fetch, commit files, parent SHA, branch/head SHA, file update, PR open; `fetch_pr_diff` returns a **`dict`** (Jac `obj` return typing was failing).
- **`integrations/discord.jac`** + **`integrations/impl/discord.impl.jac`**: PR-style notifications plus **incident**, **escalation**, **gap digest**.

## Graph builder

- **`graph/builder.jac`** + **`graph/impl/builder.impl.jac`**: deterministic build/upsert, manifest → dependency nodes, Python `ast` imports, docs/tests heuristics.

**Note:** Jac’s checker rejected typed `++> [SomeEdge]` in this walker body, so **default edges** are used for those links (connectivity matches intent; edge types remain in the model).

## System 2 walkers

- **`DependencyDiffWalker`** → **`SandboxExecutorWalker`** → **`FixGenerationWalker`** → **`GhostwatchPRCreatorWalker`**; **`GapAnalysisWalker`**; **`GitHubSystem2WebhookWalker`** (push → dep diff, merged PR → gap analysis); demo **`System2PushTriggerWalker`**, **`System2MergeTriggerWalker`**, **`System2EscalationTickWalker`**.
- **`by llm`**: sandbox interpretation, PR body formatting, optional gap wording (with try/fallbacks).

## Wiring and API surface

- **`frontend/main.jac`**: imports all `walker:pub` endpoints so `jac serve` / `jac start` can expose them (entry remains **`frontend/main.jac`** per **`jac.toml`**).
- **`jac.toml`**: `PyGithub`, `requests`, `byllm` default model.
- **`.env.example`**: GitHub, webhook secret, Anthropic, Discord, E2B.

## Graph state (System 2 summaries)

- **`walkers/static/graph_state.jac`** + **`walkers/static/impl/graph_state.impl.jac`**: adds **`latest_incident`** and **`latest_gap_analysis`** on the existing report payload.

## Tests

- **`tests/test_system2.jac`**: manifest parsing, normalization, dedupe, classification, fix inversion, gap ranking, HMAC, alias map.

**Verified:** `jac test tests/test_system2.jac` → **10 passed**.

## Other fixes

- **`frontend/init.jac`**: removed invalid `import from frontend { }` / `pass` so `jac check` succeeds.
- **`graph/impl/builder.impl.jac`**: removed unused edge imports after switching to default edges.

## Intentional gaps / tradeoffs vs the design doc

1. **Sandbox**: subprocess instrumented runner instead of E2B (no E2B SDK calls in code).
2. **`pypi_publish_age_days`**: always **`-1`** in `lib` (offline-safe); young-package only when you extend that function.
3. **Typed graph edges** in `GraphBuilderWalker`: default edges used where the compiler rejected typed connections.
4. **Root `main.jac`**: still a stub; **`frontend/main.jac`** is the wired entry per project config.

## Follow-ups (optional)

- Wire **`/security/:id`** and **`/gaps`** UI to `latest_incident` / `latest_gap_analysis` from `GraphStateWalker`.
- Full-repo `jac check`: exclude directories named `.jac` when batch-checking (e.g. `find … -type f`); `frontend/.jac` is a directory and must not be passed to `jac check` as a file path.
