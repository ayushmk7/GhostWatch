# GhostWatch — hackathon deck outline (10 slides)

Use this as a speaker guide: each section lists **what belongs on the slide** and **what to say**. Replace placeholders with your team name, live demo URL, and repo link before presenting.

---

## Slide 1 — Title & hook

**On the slide**

- Project name **GhostWatch** and one-line tagline (e.g. *Autonomous code defense with graph-native clarity*).
- Optional: logo / wordmark, hackathon name, team names.

**Describe / emphasize**

- The problem space in one breath: supply-chain risk and noisy PR review, without drowning maintainers in alerts.
- Why this project exists *now* (dependency attacks, typosquatting, install-script surprises).

---

## Slide 2 — The problem (judges care about pain)

**On the slide**

- 2–4 bullets: real maintainer pain (dependency changes slip in, hard to see blast radius, review fatigue).
- Optional: one stat or news headline style line (no need for a real citation on the slide—keep it honest if you quote numbers).

**Describe / emphasize**

- You are not solving “linting”; you are solving **trust and speed** when dependencies move.
- Connect to **who gets hurt** when a bad package lands (users, org reputation, on-call).

---

## Slide 3 — What GhostWatch is (solution in plain language)

**On the slide**

- One sentence: *GhostWatch watches repos for risky dependency and PR signals, explains impact, and can drive automated response.*
- Three pillars aligned with the product (examples: **PR intelligence**, **supply chain / dependencies**, **blast radius & control room**).

**Describe / emphasize**

- **System 1** (conceptually): static understanding of the repo—graph of files, imports, dependencies, tests/docs linkage, orchestrated “walkers” for review-style insights.
- **System 2** (conceptually): **webhook-driven** pipeline on push/merge—diff manifests, flag suspicious changes, **sandbox** suspicious packages, optional **auto-fix PR** + **Discord** alerts, **post-merge gap analysis** for contributors.
- Keep jargon light; say “we build a living model of the repo” if you show the graph UI.

---

## Slide 4 — How it works (architecture, high level)

**On the slide**

- Simple diagram: **GitHub** → **webhook** → **Jac backend / walkers** → **graph state** → **UI + Discord + PRs**.
- Label the main stages: *detect* → *sandbox / evidence* → *fix / alert* → *learn after merge*.

**Describe / emphasize**

- **Deterministic first**: manifest parsing, rules, graph build—so behavior is explainable and demo-repeatable.
- **LLM where it helps**: interpretation and wording, not “magic guesses” for core security decisions (matches the design intent in `docs/system2design.md`).
- **Idempotency**: same incident should not spam duplicate PRs or lose state if something retries.

---

## Slide 5 — How people use it (two audiences)

**On the slide**

- Two columns: **Maintainer / lead** vs **Contributor**.
- 2–3 bullets each for concrete actions (not features).

**Describe / emphasize**

- **Maintainers**: connect the repo; on suspicious dependency pushes they get **evidence-backed** signals; for clear malicious cases the system can open a **fix PR**; **Discord** for escalation/digest; use the **control room** UI for incidents and posture.
- **Contributors**: after merges, see **gap-style suggestions** (e.g. missing tests/docs near touched areas)—actionable, ranked, not a wall of noise.
- **Onboarding path in the app**: landing → **Get started** → pick role → `/app/maintainer` or `/app/contributor` (see `frontend/NAVIGATION.md`).

---

## Slide 6 — Live demo script (what judges should see)

**On the slide**

- Numbered demo steps (4–6 steps max).
- Backup slide note: “If live fails, we show recording + repo.”

**Describe / emphasize**

- Show **one happy path**: e.g. open the **landing** page → role flow → **incident** or **security** view → **graph** or summary card.
- If System 2 is wired in your environment: trigger or narrate a **manifest change** → **flag** → **sandbox evidence** → **PR** narrative.
- Call out **one wow moment**: graph-native clarity, structured IOCs, or autonomous PR—pick the strongest thing you actually run live.

---

## Slide 7 — Tech stack & why it’s interesting

**On the slide**

- Logos or bullets: **Jac** (graph / walkers / same language frontend where applicable), **GitHub** webhooks/API, **Discord**, sandbox execution (e.g. E2B or your runner), **Vite** / Jac client for UI.
- “Built for hackathon velocity, designed for production shape” (only if true).

**Describe / emphasize**

- **Why Jac**: walkers over a shared graph model, typed objects, one stack from backend logic to UI patterns—good “novel stack” story for judges.
- **Integration surface**: not a script—**signature-validated** webhooks, persistent **incident** state, clear contracts for the UI.

---

## Slide 8 — Traction, validation, or honesty (hackathons reward rigor)

**On the slide**

- What you **finished** vs **stubbed** (checklist or progress bar).
- Tests or `jac check` / manual test plan reference if you have them.

**Describe / emphasize**

- Point to **docs** (`docs/system2design.md`, manual test notes) as proof of thought, not slides alone.
- If something is mocked for demo, say it once, clearly: judges prefer honesty over vapor.

---

## Slide 9 — Differentiation & future work

**On the slide**

- “vs. generic SCA”: **graph context** (phantom imports, blast radius), **sandbox evidence**, **optional auto-fix PR**, **post-merge contributor gaps**.
- 2 bullets: **next 30 days** if you had them (e.g. more ecosystems, org-wide dashboard, policy packs).

**Describe / emphasize**

- You are combining **SCA + behavior + repo structure + maintainer workflow**—not only a CVE database lookup.
- One sentence on **responsible disclosure** posture if you touch real vulns (stay high-level).

---

## Slide 10 — Team, links, ask

**On the slide**

- Team names, roles (who built backend, UI, integrations).
- **QR or URL**: repo, demo, Discord dev server if applicable.
- Thank-you + one **ask** (feedback, intros to design partners, job interest—pick one).

**Describe / emphasize**

- Recap **one-line value**: *GhostWatch turns dependency and PR risk into explainable, actionable automation with a maintainer-grade UI.*
- End on time; offer to show **repo** or **architecture** in Q&A.

---

## Optional speaker notes (hackathon judges often ask)

- **Scale**: per-repo first; multi-repo is a roadmap story.
- **Privacy / secrets**: sandboxes are isolated; say you avoid exfiltration in the demo environment.
- **False positives**: rules + human review path (`needs_human_review`)—signal with guardrails.
- **Open source**: license and contribution path if the repo is public.
