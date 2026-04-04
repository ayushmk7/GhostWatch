# GhostWatch Frontend Debug & Activation Design
**Date:** 2026-04-04  
**Status:** Approved  
**Approach:** A — Fix in-place + init.jac + jac.toml

---

## Goal

Make `frontend/frontend.jac` (a) pass `jac check` and (b) serve as a live web app via `jac start --dev` with all three routes navigable in a browser.

---

## Scope

Four deliverables, no other changes:

1. Fix 5 syntax bugs in `frontend/frontend.jac`
2. Create `jac.toml` at project root
3. Recreate `frontend/init.jac`
4. Create `frontend/NAVIGATION.md`

---

## Bug Fixes in `frontend/frontend.jac`

All five are the same class of error: nested `def` functions missing return-type annotations, which Jac requires on all function declarations.

### Bug 1 — `handleClick` in `SidebarNavButton` (~line 2580)

```jac
# WRONG
def handleClick {
    onPick(item["label"]);
}

# RIGHT
def handleClick() -> None {
    onPick(item["label"]);
}
```

### Bug 2 — `handleClick` in `IncidentFeedButton` (~line 2605)

```jac
# WRONG
def handleClick {
    onPick(incident["title"]);
}

# RIGHT
def handleClick() -> None {
    onPick(incident["title"]);
}
```

### Bug 3 — `runAnalysis` in `AppPage` (~line 3146)

```jac
# WRONG
def runAnalysis {
    commandNote = "Mock analysis queued...";
}

# RIGHT
def runAnalysis() -> None {
    commandNote = "Mock analysis queued...";
}
```

### Bug 4 — `setSection` in `AppPage` (~line 3141)

```jac
# WRONG
def setSection(label: str) {
    activeSection = label;
    commandNote = label + " is now centered in the command surface.";
}

# RIGHT
def setSection(label: str) -> None {
    activeSection = label;
    commandNote = label + " is now centered in the command surface.";
}
```

### Bug 5 — `focusIncident` in `AppPage` (~line 3150)

```jac
# WRONG
def focusIncident(title: str) {
    selectedEvent = title;
    commandNote = "Focused incident: " + title + ".";
}

# RIGHT
def focusIncident(title: str) -> None {
    selectedEvent = title;
    commandNote = "Focused incident: " + title + ".";
}
```

---

## New File: `jac.toml` (project root)

Required by `jac start` to locate the entry point and enable the client plugin.

```toml
[project]
name = "ghostwatch"
version = "1.0.0"
description = "GhostWatch autonomous code defense frontend"
entry-point = "frontend/frontend.jac"

[serve]
base_route_app = "app"

[plugins.client]
```

---

## New File: `frontend/init.jac`

Thin local entry for running directly from the `frontend/` directory. Restores the deleted placeholder with proper content.

```jac
import from frontend { }

with entry {
    pass;
}
```

---

## New File: `frontend/NAVIGATION.md`

Documents:
- All three routes (`/`, `/auth`, `/app`) and their purpose
- How to navigate between them (skip-auth buttons, nav links, CTAs)
- How to run the app (`jac start --dev` command + URL)
- Demo mode explanation

---

## Run Instructions

```bash
# From project root
jac start --dev

# Open in browser
http://localhost:8000/cl/app
```

Routes:
- `http://localhost:8000/cl/app/` → Landing page
- `http://localhost:8000/cl/app/auth` → Auth page  
- `http://localhost:8000/cl/app/app` → Main app shell

---

## What is NOT changing

- The CSS design system (no visual changes)
- The mock data constants
- The component structure
- The routing setup (already correct)
- The glass/motion/typography system

---

## Acceptance Criteria

- [ ] `jac check frontend/frontend.jac` passes with no errors
- [ ] `jac start --dev` starts without errors
- [ ] All three routes render in browser
- [ ] Skip-auth buttons navigate from `/` and `/auth` directly to `/app`
- [ ] `frontend/NAVIGATION.md` exists and is accurate
