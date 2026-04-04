# GhostWatch — URL Navigation Guide

## Running the App

From the project root:

```bash
jac start frontend/frontend.jac --dev
```

Then open: **http://localhost:8000/cl/app**

> `jac start --dev` alone looks for `main.jac`. Always pass the file explicitly.

---

## Routes

### `/` — Landing Page

**URL:** `http://localhost:8000/cl/app/`

The entry point. Explains what GhostWatch does, shows the cinematic hero with animated SVG, metric chips, feature panels, and the five-step operating flow.

**How to get here:**
- Direct URL
- Click the GhostWatch wordmark from the app shell

**Navigation from here:**
| Element | Destination |
|---|---|
| `Skip Auth` button (top-right corner) | `/app` directly |
| `Launch Demo` CTA | `/app` |
| `View Access` CTA | `/auth` |
| `Enter GhostWatch` nav button | `/auth` |
| `Continue to Auth` (bottom CTA) | `/auth` |
| `Skip Straight to App` (bottom CTA) | `/app` |

---

### `/auth` — Access Gateway

**URL:** `http://localhost:8000/cl/app/auth`

Premium auth screen. GitHub sign-in, Discord sign-in, and email/password fields are present but non-functional in demo mode. The environment notes panel explains the demo state.

**How to get here:**
- Click `Enter GhostWatch` or `View Access` / `Continue to Auth` from the landing page

**Navigation from here:**
| Element | Destination |
|---|---|
| `Skip Auth for Now` button (top-right corner) | `/app` directly |
| `Enter Demo Control Room` button | `/app` |
| GitHub / Discord buttons | `/app` (demo links) |

---

### `/app` — Main App Shell

**URL:** `http://localhost:8000/cl/app/app`

The full command surface. Sidebar navigation, top utility bar, four summary cards, incident feed, walker status panels, and the intentionally blank graph canvas placeholder.

**How to get here:**
- Click any skip-auth button from landing or auth
- Click `Launch Demo` from landing

**Navigation from here:**
| Element | Action |
|---|---|
| GhostWatch wordmark (sidebar) | Navigates back to `/` |
| Sidebar nav items | Switches active section in-page (no route change) |
| `Run Analysis` button | Updates command note (mock, no route change) |
| Incident feed rows | Focuses incident in command note (no route change) |

---

## Skip-Auth Shortcuts (Demo Mode)

Both pre-app screens have a visible corner button that bypasses authentication:

| Screen | Button label | Result |
|---|---|---|
| Landing (`/`) | `Skip Auth` | Goes to `/app` |
| Auth (`/auth`) | `Skip Auth for Now` | Goes to `/app` |

These buttons are always visible without scrolling, positioned top-right.

---

## Catch-All

Any unrecognised path redirects back to `/` via `<Navigate to="/">`.

---

## Local Development Notes

- The app runs in **demo mode only** (`DEMO_MODE = True`)
- All data is hardcoded in centralized constants at the top of `frontend/frontend.jac`
- The graph canvas is intentionally blank — a live topology playback area reserved for the next build
- No real auth, no real backend calls — swap mock constants for walker responses to go live

---

## File Reference

| File | Purpose |
|---|---|
| `frontend/frontend.jac` | Entire frontend — CSS tokens, mock data, all components, router |
| `frontend/init.jac` | Local entry point (use when running from `frontend/` dir) |
| `jac.toml` | Project config — entry point, client plugin, serve settings |
