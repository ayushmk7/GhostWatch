# GhostWatch — hackathon deck outline (10 slides)

**How to use this file:** Follow **On the slide** as a checklist. Do not skip items. Replace only text in `[BRACKETS]`. The **Describe / emphasize** section is what you say out loud.

---

## Slide 1 — Title & hook

**On the slide**

1. **Title (exact):** `GhostWatch`
2. **Subtitle (exact tagline):** *Autonomous code defense with graph-native clarity*
3. **Hackathon name (required):** `[HACKATHON NAME]` — full official title as printed on the event site
4. **Team line (required):** `Team: [Name1], [Name2], [Name3]` (list everyone; use “&” before the last name if two people)
5. **Visual (required):** GhostWatch wordmark or logotype — same type treatment you use on the landing page; no blank title slide

**Describe / emphasize**

- The problem space in one breath: supply-chain risk and noisy PR review, without drowning maintainers in alerts.
- Why this project exists *now* (dependency attacks, typosquatting, install-script surprises).

---

## Slide 2 — The problem (judges care about pain)

**On the slide**

1. **Slide title (exact):** `The problem`
2. **Four bullets — copy these verbatim** (one bullet per line, this order):

   - Dependency and lockfile changes slip through review; reviewers miss what actually shipped.
   - When a package changes, **blast radius** is unclear: which files, tests, and entry points actually depend on it?
   - **PR review fatigue** turns real risk into background noise; urgent signals look like every other comment.
   - A single malicious or compromised dependency hurts **users**, **org reputation**, and **on-call** — not “just” the security team.

3. **Pull quote / headline strip (required, one line, exact):**  
   `We are not building another linter. We are building trust and speed when dependencies move.`

**Describe / emphasize**

- You are not solving “linting”; you are solving **trust and speed** when dependencies move.
- Connect to **who gets hurt** when a bad package lands (users, org reputation, on-call).

---

## Slide 3 — What GhostWatch is (solution in plain language)

**On the slide**

1. **Slide title (exact):** `What GhostWatch is`
2. **One-sentence solution (exact, full sentence on the slide):**  
   *GhostWatch watches repos for risky dependency and PR signals, explains impact, and can drive automated response.*
3. **Section label (exact):** `Three pillars`
4. **Three pillar headings — use these exact labels** (one row or three columns):

   - **PR intelligence**
   - **Supply chain & dependencies**
   - **Blast radius & control room**

5. **Under each pillar, exactly one short line (copy verbatim):**

   - Under **PR intelligence:** `Signals and context for review — not a wall of generic alerts.`
   - Under **Supply chain & dependencies:** `Manifest-aware monitoring when dependencies change.`
   - Under **Blast radius & control room:** `Graph-native view of what could be affected — and what to do next.`

**Describe / emphasize**

- **System 1** (conceptually): static understanding of the repo—graph of files, imports, dependencies, tests/docs linkage, orchestrated “walkers” for review-style insights.
- **System 2** (conceptually): **webhook-driven** pipeline on push/merge—diff manifests, flag suspicious changes, **sandbox** suspicious packages, optional **auto-fix PR** + **Discord** alerts, **post-merge gap analysis** for contributors.
- Keep jargon light; say “we build a living model of the repo” if you show the graph UI.

---

## Slide 4 — How it works (architecture, high level)

**On the slide**

1. **Slide title (exact):** `How it works`
2. **Diagram (required):** One left-to-right flow. **Node text must read exactly:**

   `GitHub` → `Webhook` → `Jac backend / walkers` → `Graph state` → `UI + Discord + PRs`

3. **Stage strip below the diagram (required, exact labels in this order):**  
   `Detect` → `Sandbox / evidence` → `Fix / alert` → `Learn after merge`

**Describe / emphasize**

- **Deterministic first**: manifest parsing, rules, graph build—so behavior is explainable and demo-repeatable.
- **LLM where it helps**: interpretation and wording, not “magic guesses” for core security decisions (matches the design intent in `docs/system2design.md`).
- **Idempotency**: same incident should not spam duplicate PRs or lose state if something retries.

---

## Slide 5 — How people use it (two audiences)

**On the slide**

1. **Slide title (exact):** `Who it’s for`
2. **Two columns (required).** Column headers **exact:** `Maintainer / lead` | `Contributor`
3. **Maintainer column — exactly these three bullets (verbatim):**

   - Connect the repo; on suspicious dependency pushes, get **evidence-backed** signals (not vibes).
   - For clear malicious cases, the system can open a **fix PR**; use **Discord** for escalation or digest.
   - Use the **control room** UI for incidents and posture.

4. **Contributor column — exactly these three bullets (verbatim):**

   - After merges, get **gap-style suggestions** (e.g. missing tests or docs near code you touched).
   - Suggestions are **ranked and actionable**, not a dump of every possible issue.
   - Onboarding: landing → **Get started** → pick role → `/app/maintainer` or `/app/contributor` (see `frontend/NAVIGATION.md`).

**Describe / emphasize**

- **Maintainers**: connect the repo; on suspicious dependency pushes they get **evidence-backed** signals; for clear malicious cases the system can open a **fix PR**; **Discord** for escalation/digest; use the **control room** UI for incidents and posture.
- **Contributors**: after merges, see **gap-style suggestions** (e.g. missing tests/docs near touched areas)—actionable, ranked, not a wall of noise.
- **Onboarding path in the app**: landing → **Get started** → pick role → `/app/maintainer` or `/app/contributor` (see `frontend/NAVIGATION.md`).

---

## Slide 6 — Live demo script (what judges should see)

**On the slide**

1. **Slide title (exact):** `Live demo`
2. **Exactly five numbered steps — use this exact script on the slide** (edit only bracketed URLs if your routes differ):

   1. `Open the GhostWatch landing page.`
   2. `Walk through Get started and pick maintainer vs contributor.`
   3. `Show the maintainer path: incident / security posture view (whatever you ship in UI today).`
   4. `Show graph or summary card that explains impact (your “wow” visual).`
   5. `If System 2 is live: narrate manifest change → flag → sandbox evidence → PR or alert outcome; if not live, say explicitly what is recorded vs mocked.`

3. **Footer line (required, exact):**  
   `Backup: if live demo fails → show screen recording + GitHub repo.`

**Describe / emphasize**

- Show **one happy path**: e.g. open the **landing** page → role flow → **incident** or **security** view → **graph** or summary card.
- If System 2 is wired in your environment: trigger or narrate a **manifest change** → **flag** → **sandbox evidence** → **PR** narrative.
- Call out **one wow moment**: graph-native clarity, structured IOCs, or autonomous PR—pick the strongest thing you actually run live.

---

## Slide 7 — Tech stack & why it’s interesting

**On the slide**

1. **Slide title (exact):** `Stack`
2. **Bulleted list (required):** Include **every** line below on the slide — same wording, same order:

   - `Jac — graph model, walkers, shared backend/UI language patterns`
   - `GitHub — webhooks and API`
   - `Discord — alerts and escalation`
   - `Sandbox execution — [E2B or your runner name]`
   - `Vite + Jac client — UI delivery`

3. **Closing line (required, exact):**  
   `Built for hackathon velocity; shaped like something you could run in production.`

**Describe / emphasize**

- **Why Jac**: walkers over a shared graph model, typed objects, one stack from backend logic to UI patterns—good “novel stack” story for judges.
- **Integration surface**: not a script—**signature-validated** webhooks, persistent **incident** state, clear contracts for the UI.

---

## Slide 8 — Traction, validation, or honesty (hackathons reward rigor)

**On the slide**

1. **Slide title (exact):** `What we shipped`
2. **Two subheads (required):** `Done (demo-real)` and `Stubbed / mocked`
3. **Under `Done`, minimum three bullets you must write** — each starts with a past-tense verb. Fill with **your** truth, for example:

   - `Shipped: [concrete UI or API capability]`
   - `Shipped: [graph or walker behavior judges can see]`
   - `Shipped: [integration: GitHub / Discord / sandbox — name what actually runs]`

4. **Under `Stubbed / mocked`, minimum two bullets you must write** — no euphemisms. Example shape:

   - `Not live yet: [specific pipeline step]`
   - `Mocked for demo: [specific screen or data source]`

5. **Validation line (required, exact location: bottom of slide):**  
   `Validation: jac check + manual test notes + docs/system2design.md`  
   (If you did not run `jac check`, replace only the first clause with what you **did** run, e.g. `Manual QA on [date]`.)

**Describe / emphasize**

- Point to **docs** (`docs/system2design.md`, manual test notes) as proof of thought, not slides alone.
- If something is mocked for demo, say it once, clearly: judges prefer honesty over vapor.

---

## Slide 9 — Differentiation & future work

**On the slide**

1. **Slide title (exact):** `Why not generic SCA?`
2. **Comparison line (required, exact):**  
   `vs. CVE-only scanners: graph context, sandbox evidence, optional auto-fix PRs, post-merge contributor gaps.`
3. **Subhead (exact):** `Next 30 days`
4. **Exactly two roadmap bullets — copy verbatim** (delete neither):

   - `More language ecosystems and package managers in the graph.`
   - `Org-wide dashboard and policy packs for approve/deny patterns.`

**Describe / emphasize**

- You are combining **SCA + behavior + repo structure + maintainer workflow**—not only a CVE database lookup.
- One sentence on **responsible disclosure** posture if you touch real vulns (stay high-level).

---

## Slide 10 — Team, links, ask

**On the slide**

1. **Slide title (exact):** `Team & links`
2. **Team block (required format, one line per person):**  
   `[Full Name] — [Backend | Frontend | Integrations | Design | PM — pick one primary]`
3. **Links row (required, all three must appear as clickable text or QR):**

   - `Repo: [public GitHub URL]`
   - `Live demo: [deployed URL or “local — see repo README”]`
   - `Discord: [invite or “webhook bot — see README”]`

4. **Thank-you line (required, exact):** `Thank you.`
5. **Ask line (required — pick exactly one of the following and put only that sentence on the slide):**

   - `Ask: We want feedback on maintainer workflows.`
   - `Ask: Intros to teams who own critical OSS dependencies.`
   - `Ask: We’re hiring / open to internships — talk to us after.`

6. **Value recap (required, exact one line under the ask):**  
   *GhostWatch turns dependency and PR risk into explainable, actionable automation with a maintainer-grade UI.*

**Describe / emphasize**

- Recap **one-line value**: *GhostWatch turns dependency and PR risk into explainable, actionable automation with a maintainer-grade UI.*
- End on time; offer to show **repo** or **architecture** in Q&A.

---

## Speaker notes — Q&A (use if asked; do not put on slides)

- **Scale**: per-repo first; multi-repo is a roadmap story.
- **Privacy / secrets**: sandboxes are isolated; say you avoid exfiltration in the demo environment.
- **False positives**: rules + human review path (`needs_human_review`)—signal with guardrails.
- **Open source**: license and contribution path if the repo is public.
