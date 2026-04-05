# GhostWatch — URL Navigation Guide

## Running the App

From the project root:

```bash
jac build
```

Then from `.jac/client` run Vite dev (see repo `README` or use `npx vite dev --config configs/vite.config.js`), or with the full stack:

```bash
jac start frontend/frontend.jac --dev
```

Then open the URL your toolchain prints (e.g. **http://localhost:8000/cl/app** for `jac start`).

> `jac start --dev` alone looks for `main.jac`. Always pass the file explicitly if you use `frontend/frontend.jac`.

---

## Routes

### `/` — Landing Page

**URL:** `/` (e.g. `http://localhost:5173/` in Vite)

The entry point. Explains what GhostWatch does, shows the cinematic hero with animated SVG, metric chips, feature panels, and the five-step operating flow.

**How to get here:**
- Direct URL
- Click the GhostWatch wordmark from the app shell (when in-app, wordmark links home)

**Navigation from here:**
| Element | Destination |
|---|---|
| `Getting started` (header) | `/start` |
| `Getting started` (hero primary CTA) | `/start` |
| `Explore product` (hero secondary) | `#capabilities` (on-page) |
| `Getting started` (bottom CTA) | `/start` |

---

### `/start` — Role selection

**URL:** `/start`

Asks whether the visitor is a **Contributor** or **Lead maintainer**, then routes to the matching in-app home.

**Navigation from here:**
| Element | Destination |
|---|---|
| Contributor card | `/app/contributor` |
| Lead maintainer card | `/app/maintainer` |
| Back to marketing site | `/` |

---

### `/app/contributor` — Contributor home

Contributor-oriented shell: gap-style suggestions, doc/test cues, and lighter copy aligned with post-merge gap analysis (see `docs/system2design.md`). Same layout family as the maintainer view, different mock data and labels.

**Navigation from here:**
| Element | Destination |
|---|---|
| GhostWatch wordmark (sidebar) | `/` |
| `Switch role` (sidebar footer) | `/start` |
| Sidebar sections | In-page section focus (no route change) |

---

### `/app/maintainer` — Lead maintainer home

**URL:** `/app/maintainer`

The maintainer control room: sidebar navigation, summary cards, incident-style feed, walker status panels, and the intentionally blank graph canvas placeholder (as in the original demo shell).

**Navigation from here:**
| Element | Destination |
|---|---|
| GhostWatch wordmark (sidebar) | `/` |
| `Switch role` | `/start` |
| Sidebar nav items | Switches active section in-page (no route change) |
| Primary action button | Updates command note (mock, no route change) |
| Feed rows | Focuses item in command note (no route change) |

---

### Redirects

| Path | Behavior |
|---|---|
| `/app` | Redirects to `/start` (choose a role) |
| `/auth` | Redirects to `/start` (legacy path; auth UI removed from demo) |

---

## Catch-All

Any other unrecognised path redirects back to `/` via `<Navigate to="/">`.

---

## Local Development Notes

- The app runs in **demo mode only** (`DEMO_MODE = True`)
- Data is hardcoded in centralized constants at the top of `frontend/frontend.jac`
- The graph canvas is intentionally blank — a live topology playback area reserved for the next build
- No real auth or backend in this slice; `./docs/system2design.md` describes how the backend will feed incidents and gap analysis later

---

## File Reference

| File | Purpose |
|---|---|
| `frontend/frontend.jac` | Entire frontend — CSS tokens, mock data, all components, router |
| `frontend/init.jac` | Local entry stub (not used by root `jac.toml`) |
| `jac.toml` | Project config — entry point `main.jac`, client plugin, serve settings |
