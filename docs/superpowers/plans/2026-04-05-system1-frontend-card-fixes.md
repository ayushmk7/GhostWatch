# System 1 Frontend Card & Report Display Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure all System 1 cards and verdict reports render correctly now that the URL input UI has been removed and `repoLinked` is hardcoded to `True`.

**Architecture:** Two targeted edits to `frontend/components/AppShell.cl.jac`:
1. Strip dead "Connect"-gate initial values and `repoLinked` guard conditions that are now always True.
2. Add a `safeLen` helper and fix the verdict panel finding count to survive if `security_findings` / `compatibility_issues` serialize as non-arrays.

**Tech Stack:** Jac `.cl.jac` (compiles to React/JS via Vite), backend Jac on port 8080.

---

### Task 1: Remove dead "Connect" initial values and simplify repoLinked guards

**Files:**
- Modify: `frontend/components/AppShell.cl.jac`

**Context:** With `repoLinked: bool = True` hardcoded, the block at lines 173–178:
```jac
    panelTitle = "Connect a GitHub repository";
    topDescription = "Paste a repository URL...";
    searchPlaceholder = "Available after you connect a repo";
    analysisButtonLabel = "Connect";
```
is dead — the `if repoLinked {` branch immediately overwrites all four. These are harmless but misleading. Also, every `repoLinked and` guard in JSX conditions is now a no-op constant `True and` — simplify them so the logic is obvious.

- [ ] **Step 1: Replace the four dead initial values**

Find lines ~173–178 in `AppShell.cl.jac`:
```jac
    panelTitle = "Connect a GitHub repository";
    topDescription = (
        "Paste a repository URL to scope this workspace. Overview and every tab stay limited to that project."
    );
    searchPlaceholder = "Available after you connect a repo";
    analysisButtonLabel = "Connect";

    if repoLinked {
```

Replace with (collapse the `if repoLinked` wrapper since it's always True):
```jac
    panelTitle = repoDisplay;
    topDescription = "";
    searchPlaceholder = "";
    analysisButtonLabel = "Run Analysis";

    if True {
```

Actually, since the entire `if repoLinked { ... }` block is always entered, just delete the `if repoLinked {` / closing `}` wrapper and keep the contents. Leave the inner if/else tree intact. The result should look like:

```jac
    panelTitle = repoDisplay;
    topDescription = "";
    searchPlaceholder = "";
    analysisButtonLabel = "Run Analysis";

    if isContributor {
        if activeSection == "Overview" {
            panelTitle = "Overview · " + repoDisplay;
            ...
```

- [ ] **Step 2: Remove `repoLinked and` from JSX conditions**

Find each occurrence of `repoLinked and` in the JSX return block and remove it. There are several:

```jac
{isContributor and repoLinked and activeSection == "Suggestions" and
```
→
```jac
{isContributor and activeSection == "Suggestions" and
```

```jac
{isContributor and repoLinked and activeSection == "Docs & tests" and
```
→
```jac
{isContributor and activeSection == "Docs & tests" and
```

```jac
{isContributor and repoLinked and activeSection == "Activity" and
```
→
```jac
{isContributor and activeSection == "Activity" and
```

```jac
{isContributor and repoLinked and activeSection == "Settings" and
```
→
```jac
{isContributor and activeSection == "Settings" and
```

```jac
{(not isContributor) and repoLinked and activeSection == "PR Review" and
```
→
```jac
{(not isContributor) and activeSection == "PR Review" and
```

```jac
{(not isContributor) and repoLinked and activeSection == "Dependency Alerts" and
```
→
```jac
{(not isContributor) and activeSection == "Dependency Alerts" and
```

```jac
{(not isContributor) and repoLinked and activeSection == "Incidents" and
```
→
```jac
{(not isContributor) and activeSection == "Incidents" and
```

```jac
{(not isContributor) and repoLinked and activeSection == "Settings" and
```
→
```jac
{(not isContributor) and activeSection == "Settings" and
```

```jac
{isContributor and repoLinked and activeSection == "Overview" and
```
→
```jac
{isContributor and activeSection == "Overview" and
```

```jac
{(not isContributor) and repoLinked and activeSection == "Overview" and
```
→
```jac
{(not isContributor) and activeSection == "Overview" and
```

- [ ] **Step 3: Remove dead `repoLinked` state variable and any unused imports/helpers**

Remove `repoLinked: bool = True,` from the `has` block (line 49). It's now a literal `True` sprinkled through JSX — removing it means replacing each of the already-simplified conditions (done above). Also remove `parse_repo_slug` if `repoDisplay` is the only call site and that call can be inlined:

`repoDisplay: str = parse_repo_slug(DEMO_REPO_URL)` — keep `parse_repo_slug` since it's still used here. Leave it.

Also remove `DEMO_REPO_URL` from the mock_data import if it is only used for `repoDisplay` init. Check — `DEMO_PR_URL` is still needed for `runAnalysis()`. `DEMO_REPO_URL` is only used at line 50 now. Keep the import.

- [ ] **Step 4: Verify build**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend && jac check main.jac
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add frontend/components/AppShell.cl.jac
git commit -m "refactor: remove URL input gate — repoLinked always True, strip dead connect-state"
```

---

### Task 2: Fix security/compatibility finding count in verdict panel

**Files:**
- Modify: `frontend/components/AppShell.cl.jac`

**Context:** After `runAnalysis()`, `analysisResult` is set to `reports[0]` from OrchestratorProxy. `security_findings` and `compatibility_issues` in the verdict dict are `list[SecurityFinding]` / `list[CompatibilityIssue]` Jac objects serialized via `dict(vars(verdict))`. If Jac's HTTP layer serializes nested Jac obj instances as empty dicts or nulls, `len(analysisResult["security_findings"] or [])` in JS silently returns 0 or throws. We need safe counting.

- [ ] **Step 1: Add `safeLen` helper above the AppShell component**

After the `parse_repo_slug` function (around line 44), insert:

```jac
def safeLen(val: Any) -> int {
    if not val { return 0; }
    if not Array.isArray(val) { return 0; } # jac:ignore[E1032]
    return len(val);
}
```

- [ ] **Step 2: Replace the count expression in the verdict panel**

Find (around line 1209–1211):
```jac
                                <span style={{"color": "rgba(220,239,255,0.5)", "fontSize": "12px"}}>
                                    {str(len(analysisResult["security_findings"] or [])) + " security · " + str(len(analysisResult["compatibility_issues"] or [])) + " compat"}
                                </span>
```

Replace with:
```jac
                                <span style={{"color": "rgba(220,239,255,0.5)", "fontSize": "12px"}}>
                                    {str(safeLen(analysisResult["security_findings"])) + " security findings · " + str(safeLen(analysisResult["compatibility_issues"])) + " compatibility issues"}
                                </span>
```

- [ ] **Step 3: Verify build**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend && jac check main.jac
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/components/AppShell.cl.jac
git commit -m "fix: safe count for security/compat findings in verdict panel"
```

---

### Task 3: Manual smoke test — all cards and reports

- [ ] **Step 1: Start backend (from project root)**

```bash
cd /home/asunaron/hackathons/GhostWatch
source .env 2>/dev/null || export $(cat .env | xargs)
jac start main.jac --port 8080
```

- [ ] **Step 2: Start frontend (separate terminal)**

```bash
cd /home/asunaron/hackathons/GhostWatch/frontend
jac start main.jac --dev
```

- [ ] **Step 3: Navigate to `/app/maintainer` and verify cards**

Open browser to `http://localhost:8000/app/maintainer`.

**On load (before Run Analysis):**
- [ ] Topbar shows immediately — no URL input prompt
- [ ] `repoDisplay` shows as `Aarosunn/ghostwatch-test-target` in the repo selector button
- [ ] Summary card "Files scanned" shows a number (e.g. `42`), not `—`
- [ ] Summary card "High-risk files" shows a number
- [ ] Summary card "Latest PR risk" shows `None yet` (if no prior analysis) or a risk level
- [ ] Summary card "Graph status" shows `Ready`
- [ ] Walker status rail shows `Active` for all three walkers
- [ ] Attention items show `N nodes`, `M detected`, `None`
- [ ] ReactFlow graph is visible with colored nodes

**After clicking Run Analysis:**
- [ ] Button shows `Analyzing...` while running
- [ ] Verdict panel appears with risk badge (e.g. `critical`)
- [ ] `blast_radius_summary` paragraph is populated
- [ ] `recommendation` italic text is populated
- [ ] Finding counts show (e.g. `3 security findings · 1 compatibility issues`) — not `0 · 0`
- [ ] Graph nodes animate in traversal order
- [ ] Summary cards refresh with updated risk scores

---

## Self-Review

**Spec coverage:**
- URL input removal → no code needed (user did it); dead state cleanup → Task 1 ✓
- `security_findings` safe count → Task 2 ✓
- All card values (Files scanned, High-risk files, Latest PR risk, Graph status) → wired correctly, no changes needed ✓
- Verdict panel (overall_risk badge, blast_radius_summary, recommendation, finding counts) → Task 2 fixes count; rest wired correctly ✓
- GraphView nodes/edges/animation → no changes needed, wired correctly ✓
- Smoke test → Task 3 ✓

**Placeholder scan:** No TBDs. All find-and-replace targets shown verbatim. ✓

**Type consistency:** `safeLen(Any) -> int` defined in Task 2 Step 1, used in Task 2 Step 2. ✓
