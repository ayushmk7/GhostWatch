# GhostWatch — Frontend PRD
**Version 1.0 | JacHacks 2026**

---

## Overview

This document defines the full frontend product requirements for GhostWatch as a Jac-native web application. It is intentionally implementation-ready. The goal is not to produce a generic dashboard or a safe startup landing page. The goal is to ship a memorable dark-mode-only interface that feels like Apple liquid glass filtered through the stricter anti-generic rules in [docs/distinctive-frontend.md](./distinctive-frontend.md).

The frontend must live in Jac, use `cl {}` / `jac-client` patterns, and feel complete even while parts of the underlying backend are still mocked. For this phase, the graph visualization area in the main app should remain an intentionally blank reserved canvas. Everything around it should feel production-grade.

---

## Product Intent

GhostWatch is a code guardian. The frontend should make that feel cinematic, premium, calm, and watchful rather than noisy, gamer-ish, or template-driven. The visual language should communicate:

- precision
- depth
- high trust
- active monitoring
- premium craft
- restrained motion

This is not a neon cyberpunk UI. It is not a bland SaaS analytics template. It is not a white-glass Apple clone. It is a dark, liquid, atmospheric control room with Apple-style glass behavior and a more distinctive visual identity.

---

## Non-Negotiable Design Directives

The frontend must follow [docs/distinctive-frontend.md](./distinctive-frontend.md) very closely. That means:

1. Avoid generic font choices and safe typography.
2. Use strong typography contrast rather than medium-weight sameness.
3. Use a cohesive dark palette with clear accents and no default purple-gradient drift.
4. Include orchestrated page-load animation, not random hover gimmicks.
5. Build layered backgrounds with atmospheric depth, texture, gradients, and SVG structure.
6. Make every major surface feel intentional, not like interchangeable dashboard cards.

In addition:

1. The app is dark mode only for v1.
2. The visual model is Apple liquid glass in dark mode only.
3. The landing page and auth page must both include a visible corner button that skips auth and routes straight to the app shell.
4. The app must be fully designed as a complete frontend experience in Jac.
5. Hardcoded values are allowed and expected for now, but they must be isolated for later removal.
6. The graph area in the app shell must remain a blank placeholder panel with clear visual framing and a “coming soon / reserved” treatment.

---

## Design Reference

### Primary Reference

Apple liquid glass in dark mode:

- layered translucent surfaces
- luminous edges
- soft internal highlights
- subtle refraction feel
- floating panels over deep atmospheric backgrounds
- depth achieved through blur, shadow, glow, and transparency instead of flat borders

### Secondary Reference

Use the four-vector system from the distinctive frontend document:

- Typography: extreme hierarchy
- Color: coherent graphite, smoke, frost, cyan, and ember accents
- Motion: orchestrated entrances and floating objects
- Background: layered gradients, mesh lighting, noise, SVG linework

### Final Interpretation

Think “midnight observatory for autonomous code defense” rendered as dark liquid glass.

---

## User Experience Goals

The frontend should make a first-time user feel:

- “This is premium.”
- “This is different from every other AI tool landing page.”
- “I understand what GhostWatch does within seconds.”
- “The app already feels alive, even before real backend data is connected.”
- “I can bypass auth and explore the demo immediately.”

---

## Information Architecture

The frontend has three primary routes/states:

1. Landing page
2. Auth page
3. Main app shell

### Route Map

- `/` → landing page
- `/auth` → sign-in / access page
- `/app` → main application shell

### Routing Principle

Do not overcomplicate routing. For v1, route transitions can be simple client-side state or lightweight path-based navigation within Jac. The UI experience matters more than router sophistication.

---

## Brand and Tone

### Product Voice

Calm, technical, premium, protective.

### Copy Style

- concise
- high-signal
- no startup cliches
- no “revolutionize your workflow”
- no filler paragraphs
- no lorem ipsum

### Messaging Themes

- autonomous review
- dependency threat awareness
- graph-native intelligence
- maintainers stay in control

---

## Visual System

### Typography

The typography must obey the “use extremes” guidance from the distinctive frontend doc.

### Font Pairing

- Display font: `Sora` or `Clash Display`
- Body font: `Manrope`
- Mono font: `JetBrains Mono`

If one of these is unavailable in Jac setup, use the closest equivalent that still feels premium and non-generic. Do not use Inter or Roboto as the lead brand font.

### Weight Strategy

- Hero headlines: 800-900
- Section headings: 700-800
- Body copy: 200-300
- Labels and eyebrow text: 500-600
- Numeric telemetry: mono 600-700

### Type Character

- Tight tracking on large headlines
- airy line-height on body copy
- sharp metric readouts
- elegant contrast between giant display type and soft lightweight descriptive text

---

### Color System

The palette must feel like illuminated black glass, not gray boxes.

### Core Tokens

```css
:root {
  --bg-0: #050608;
  --bg-1: #0a0c10;
  --bg-2: #10141a;
  --surface-0: rgba(16, 20, 26, 0.58);
  --surface-1: rgba(21, 27, 35, 0.66);
  --surface-2: rgba(28, 36, 46, 0.72);
  --glass-highlight: rgba(255, 255, 255, 0.12);
  --glass-stroke: rgba(255, 255, 255, 0.10);
  --glass-stroke-strong: rgba(210, 233, 255, 0.18);
  --text-primary: #f4f7fb;
  --text-secondary: #aab4c3;
  --text-tertiary: #7d8898;
  --accent-frost: #dcefff;
  --accent-cyan: #7dd3ff;
  --accent-aqua: #52e5d5;
  --accent-amber: #ffbf69;
  --accent-red: #ff7b90;
  --accent-lime: #a7f3b0;
}
```

### Color Rules

- The base must stay dark everywhere.
- Glass surfaces should be translucent, never opaque slabs.
- Cyan and aqua are the primary active accents.
- Amber is used for warnings and callouts.
- Red is used only for critical risk or malicious dependency states.
- Avoid purple as a core brand accent.
- Avoid bright saturated blue default gradients that feel generic.

---

### Background System

Every screen needs atmospheric depth.

### Required Layers

1. Deep charcoal-to-graphite base gradient
2. Large soft radial light pools
3. Fine noise texture overlay
4. SVG linework or contour field
5. Slow-moving glass orbs / light blobs

### Background Behavior

- Background elements should move slowly enough to feel ambient.
- Motion should be independent from content animation.
- The app should still look rich with motion disabled.

---

### Glass Surface System

Every primary panel should use a consistent liquid-glass recipe:

- translucent dark fill
- subtle backdrop blur
- faint top-left highlight
- soft inner glow
- low-contrast outer shadow
- hairline border with cool light tint

### Glass Formula

```css
.glass-panel {
  background:
    linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.02)),
    rgba(18, 24, 31, 0.58);
  border: 1px solid rgba(220, 239, 255, 0.14);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.10),
    inset 0 0 24px rgba(255,255,255,0.03),
    0 20px 80px rgba(0,0,0,0.42);
  backdrop-filter: blur(24px) saturate(140%);
  -webkit-backdrop-filter: blur(24px) saturate(140%);
}
```

No flat cards. No plain gray borders. No default Tailwind dashboard feel.

---

### Motion System

Motion should feel deliberate and premium.

### Entrance Choreography

On initial load:

1. Background light pools fade in first.
2. Floating SVG objects appear second.
3. Navigation and skip-auth button rise in softly.
4. Hero headline resolves in with upward drift.
5. Supporting copy follows.
6. CTAs and metric capsules appear in stagger.
7. Lower sections reveal as the user scrolls.

### Motion Characteristics

- easing: smooth, slightly elastic, never bouncy
- duration: 500ms to 1200ms
- transform bias: opacity + translateY + slight scale
- hover motion: subtle, no exaggerated jumps
- ambient motion: 8s to 18s loops

### Accessibility

Respect `prefers-reduced-motion`:

- disable ambient float loops
- shorten reveals
- remove parallax

---

### SVG and Animated Object Direction

The landing page and auth page must contain custom SVG-driven visual objects. These should not feel like stock icon decorations.

### Landing Page SVG Set

1. A large ghost-shield emblem behind the hero, built from layered rings and contour strokes
2. Two or three floating glass capsules containing tiny telemetry lines
3. A diagonal arc-field or topographic contour mesh behind the feature area
4. A signal-path SVG line that subtly pulses near the “How GhostWatch Operates” section

### Auth Page SVG Set

1. A compact orbiting trust-ring graphic beside or behind the auth card
2. A shield-lock glyph rendered with translucent layered paths
3. Two small animated particles sweeping across the background at low opacity

### Main App SVG Set

1. Subtle ambient header glow and linework
2. Small status pulse indicators
3. Decorative node constellation accents around the blank graph area frame

These SVGs should use strokes, blur, opacity stacks, and gradients rather than cartoonish illustrations.

---

## Landing Page Requirements

### Purpose

The landing page should explain GhostWatch immediately, showcase the aesthetic system, and route users either into auth or directly into the app demo.

### Header

Include:

- GhostWatch wordmark or text lockup
- compact nav links: Product, Capabilities, Flow, Demo
- primary CTA: “Enter GhostWatch”
- top-right corner skip button: “Skip Auth”

### Skip Auth Rule

The skip button must be visible without scrolling and must route directly to `/app`.

### Header Style

- floating glass nav bar
- slight transparency
- pill-shaped controls
- hover sheen on interactive items

### Hero Section

### Content

Headline direction:

`Autonomous code defense, rendered in graph-native clarity.`

Supporting copy:

GhostWatch reviews pull requests, monitors dependency changes, and surfaces risk through an interface that feels alive before the first live graph ever renders.

Primary CTA:

- `Launch Demo`

Secondary CTA:

- `View Access`

### Layout

- left column: copy stack
- right column: large visual composition with SVG emblem, floating telemetry capsules, glowing arcs, and layered glass panels
- asymmetric composition preferred over perfectly balanced symmetry

### Hero Supporting Elements

- 3 small metric chips under the headline
- 1 featured glass card showing a mock “Risk Event”
- 1 translucent system strip with labels like `PR Review`, `Supply Chain`, `Blast Radius`

### Hero Hardcoded Metrics

- `42 open findings reviewed`
- `3 suspicious dependency events`
- `11.8s median verdict delivery`

### Mid-Page Sections

### Section 1: Why It Feels Different

Three glass panels:

- `Graph-native awareness`
- `Specialist walker verdicts`
- `Maintainer-first control`

Each panel needs:

- short title
- one punchy paragraph
- small inline SVG or icon accent

### Section 2: How GhostWatch Operates

A horizontal or stacked sequence of five liquid-glass steps:

1. Detect
2. Traverse
3. Score
4. Escalate
5. Prepare Fix

Each step should have:

- number
- verb
- 1-line explanation
- tiny animated accent line or pulse

### Section 3: Interface Preview

Show a polished mock preview strip of the app shell:

- top bar glimpse
- sidebar glimpse
- summary cards glimpse
- framed blank graph region

This is still hardcoded, but visually rich.

### Final CTA Section

- stronger headline
- one-line confidence-building copy
- two actions: `Continue to Auth` and `Skip Straight to App`

### Landing Page Acceptance Criteria

- clearly non-generic at first glance
- dark-only liquid glass applied consistently
- skip-auth button visible in the corner
- visible SVG motion and ambient animation
- no empty or placeholder-looking sections

---

## Auth Page Requirements

### Purpose

The auth page should feel like a premium access gateway, not a boring login form.

### Layout

- full-screen dark atmospheric background
- centered or slightly offset glass auth card
- orbiting or halo-like SVG visual nearby
- corner skip-auth button routing to `/app`

### Content

### Title

`Enter the GhostWatch control room`

### Supporting Copy

Use one calm sentence explaining that maintainers can sign in to access live review workflows, while the demo can be explored immediately without authentication.

### Auth Card Elements

- GitHub sign-in button
- Discord sign-in button
- email input
- password input
- primary submit button
- divider text
- tiny legal/support copy

These controls can be non-functional in v1, but they must look complete.

### Skip Auth Placement

The auth page must also have a corner-level skip button. Do not hide it inside the card. It should sit at the top right and clearly say:

`Skip Auth for Now`

### Extra Surface

Add a small side panel or lower card with hardcoded environment notes:

- `Demo mode enabled`
- `Live graph disabled`
- `Using local placeholder incidents`

This helps explain why the app works before backend integration.

### Auth Page Acceptance Criteria

- auth screen looks premium and intentional
- skip-auth button is obvious
- no dead empty space
- Apple-like dark liquid glass feel is preserved

---

## Main App Shell Requirements

### Purpose

The main app should feel fully built except for the graph canvas itself. The reserved graph space must be blank on purpose, while the rest of the shell is polished and populated with hardcoded data.

### App Layout

Use a multi-panel desktop-first shell that also collapses well on mobile.

### Primary Regions

1. Left navigation rail
2. Top utility bar
3. Main content column
4. Right activity / incident rail

### Left Navigation Rail

Include:

- GhostWatch mark / logo
- nav items:
  - Overview
  - PR Review
  - Dependency Alerts
  - Incidents
  - Settings
- small environment badge: `Demo Mode`
- bottom user profile stub

### Active State

Overview can be active by default.

### Top Utility Bar

Include:

- page title: `Repository Command Surface`
- repository selector stub
- search field stub
- notification bell
- quick action button: `Run Analysis`

All surfaces should use glass treatments and refined spacing.

### Main Content Above the Graph

### Summary Cards Row

At least four fully designed cards:

- `Open PRs Under Watch`
- `Critical Findings`
- `Dependency Drift`
- `Review Throughput`

### Hardcoded Values

- `12`
- `03`
- `07`
- `94%`

Each card should include:

- numeric value
- small delta or label
- tiny status spark or mini chart line

### Threat Feed / Incident Panel

A wider panel listing recent events:

- Suspicious manifest delta
- High-risk PR path touched
- Auto-fix branch prepared

Each row should include:

- timestamp
- severity pill
- short summary
- small right-arrow or action hint

### Graph Area Placeholder

This is intentionally blank for now.

### Requirements

- large central glass-framed panel
- visually prominent
- subtle dashed or luminous internal frame
- headline like `Graph Canvas Reserved`
- supporting line like `Live topology playback will attach here in the next build.`
- optional tiny corner label: `Placeholder`

### What Not To Do

- do not render a fake graph
- do not scatter fake nodes across the area
- do not leave it visually unstyled

The blank region should feel intentional, premium, and clearly reserved.

### Right Rail

Add two or three stacked panels:

### Panel 1: Walker Status

- Security Auditor: `Active`
- Compatibility Checker: `Queued`
- Blast Radius Mapper: `Watching`

### Panel 2: Attention Needed

- `2 maintainer approvals pending`
- `1 dependency lockfile mismatch`
- `4 comments ready to post`

### Panel 3: Session Notes

Short hardcoded notes describing that this build uses local placeholder data.

### Mobile Behavior

On mobile:

- nav rail collapses into a top drawer or icon row
- right rail stacks under main content
- graph placeholder remains tall and central
- skip-auth is not needed inside the app shell

### Main App Acceptance Criteria

- graph region is blank but elegant
- all other regions feel complete
- shell reads as a real product, not a wireframe
- hardcoded data feels realistic and removable

---

## Hardcoded Data Strategy

All mock values must be centralized and easy to remove later.

### Requirement

Do not scatter literals across components. Store all placeholder values in a clearly isolated mock data object or set of constants.

### Suggested Structure

```jac
glob DEMO_MODE: bool = True;

glob MOCK_APP_DATA: dict = {
    "repo_name": "jaseci-labs/jaseci",
    "summary_cards": [
        {"label": "Open PRs Under Watch", "value": "12", "delta": "+2 today"},
        {"label": "Critical Findings", "value": "03", "delta": "-1 since yesterday"},
        {"label": "Dependency Drift", "value": "07", "delta": "2 unresolved"},
        {"label": "Review Throughput", "value": "94%", "delta": "median stable"}
    ],
    "walker_status": [
        {"name": "Security Auditor", "state": "Active"},
        {"name": "Compatibility Checker", "state": "Queued"},
        {"name": "Blast Radius Mapper", "state": "Watching"}
    ],
    "events": [
        {"time": "14:02", "severity": "critical", "title": "Suspicious manifest delta"},
        {"time": "13:44", "severity": "high", "title": "Core auth path modified"},
        {"time": "13:08", "severity": "medium", "title": "Auto-fix branch prepared"}
    ]
};
```

### Removal Principle

Future backend integration should only require swapping mock sources with walker responses, not rewriting layout code.

---

## Jac Implementation Requirements

The frontend must be implementable directly in Jac.

### Structure

The likely shape is:

```jac
cl {
    import from react { useState, useEffect }

    cl def:pub app() -> JsxElement {
        // route state, mock data, layout shell
    }
}
```

### Component Breakdown

Recommended Jac frontend component structure:

- `AppRoot`
- `AmbientBackground`
- `FloatingGlassNav`
- `LandingHero`
- `FeaturePanelGrid`
- `FlowSequence`
- `AuthCard`
- `AppShell`
- `SidebarNav`
- `TopUtilityBar`
- `SummaryCardRow`
- `ThreatFeedPanel`
- `GraphPlaceholderPanel`
- `RightRailPanels`

These may live in one `.jac` file for the hackathon, but they should still be logically separated into small render helpers.

### Styling Approach

Use:

- CSS variables for all tokens
- explicit glass utility classes
- motion classes for staggered reveal
- dedicated classes for panel types

Do not bury styles inline everywhere unless Jac constraints force it. Favor a coherent token-driven styling layer.

### State Model

At minimum, support:

- current route
- nav active state
- mock notification count
- mock search field state
- demo mode flag

### Build Philosophy

Even if the frontend lives in one Jac file, it should feel like a productized UI system, not a one-off demo blob.

---

## Content Requirements

Use meaningful hardcoded content. Avoid placeholder copy like:

- `Lorem ipsum`
- `Card title`
- `Feature one`
- `Sample graph data`

Every visible string should reinforce product identity.

### Suggested Product Copy Fragments

- `Autonomous review without losing maintainer control`
- `Every touched path carries context`
- `Dependency changes should never arrive silently`
- `Reserved for live graph traversal`
- `Demo mode is using local placeholder telemetry`

---

## Accessibility Requirements

Even with a premium visual style, the UI must remain usable.

### Required

- sufficient text contrast against dark glass surfaces
- visible focus states on all buttons and fields
- semantic button and input labeling
- reduced motion support
- responsive layout from laptop down to phone width

### Avoid

- low-contrast ghost text
- tiny interaction targets
- glass opacity so strong that text becomes unreadable

---

## Engineering Constraints

1. Dark mode only for v1.
2. No real auth integration required yet.
3. No real graph rendering required yet.
4. All non-graph areas should appear complete.
5. Hardcoded data should be isolated and swappable.
6. The frontend must preserve headroom for backend walker integration.

---

## Anti-Patterns To Reject

Do not ship any of the following:

- generic SaaS hero with centered text on a purple gradient
- default dashboard cards with light borders and no depth
- stock icons only, with no custom SVG compositions
- a login page that is just a centered form on a flat background
- fake graph nodes filling the blank graph space
- mixed dark and light theme behavior
- medium-weight typography everywhere
- filler copy or dead placeholder skeletons

---

## Acceptance Criteria Summary

The frontend PRD is successful only if the resulting implementation would:

1. Feel obviously non-generic and aligned with [docs/distinctive-frontend.md](./distinctive-frontend.md).
2. Use Apple-like liquid glass behavior in dark mode only.
3. Include a complete landing page with animated SVG compositions.
4. Include a polished auth page with a visible corner skip-auth button.
5. Include a fully designed main app shell in Jac.
6. Leave only the graph area blank, but in an intentional premium placeholder state.
7. Centralize hardcoded values for easy replacement later.

---

## Implementation Prompt

Use the following prompt directly when building the frontend:

> Build a Jac-native web frontend for GhostWatch as a dark-mode-only premium interface. Follow `docs/distinctive-frontend.md` very strictly and avoid generic AI SaaS styling. The visual language should be Apple liquid glass in dark mode only, adapted into a more distinctive “midnight code observatory” aesthetic. Use strong typography contrast, cohesive dark graphite and frost color tokens, layered gradients, subtle noise, and custom SVG objects with ambient animation. Create three routes or route states: landing page, auth page, and main app shell. The landing page must have a floating glass header, a top-right `Skip Auth` button that routes straight to `/app`, a cinematic hero with animated SVG objects, metric chips, feature panels, an operating-flow section, and a polished preview of the app shell. The auth page must look premium, include GitHub and Discord sign-in options plus email/password fields, and also include a top-right `Skip Auth for Now` button that routes to `/app`. The main app shell must feel fully built with sidebar navigation, top utility bar, summary cards, event feed, walker status panels, and right-rail supporting panels. Leave the graph section as a large intentionally blank placeholder panel labeled as reserved for future live graph playback. Do not render a fake graph. Use hardcoded demo data for now, but isolate it in centralized constants or a mock data object so it can be removed later. Use Jac `cl {}` frontend patterns, CSS variables for tokens, glass utility classes, staggered entrance motion, and reduced-motion support. Avoid purple gradients, bland cards, generic system-font styling, filler copy, and template-like layouts.

---

## Delivery Expectation

If this PRD is implemented correctly, the result should look like a polished demo-ready product frontend rather than a scaffold. The only obviously unfinished area should be the intentionally reserved graph canvas.
