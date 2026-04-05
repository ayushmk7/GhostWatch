cl import from "@jac/runtime" { Router, Routes, Route, Link, Navigate }

cl glob DEMO_MODE: bool = True;

cl glob APP_STYLES: str = """
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@700;800&family=Manrope:wght@200;300;500;700&family=JetBrains+Mono:wght@500;700&display=swap');

:root {
  --font-display: 'Sora', 'Avenir Next', sans-serif;
  --font-body: 'Manrope', 'Helvetica Neue', sans-serif;
  --font-mono: 'JetBrains Mono', 'SFMono-Regular', monospace;
  --weight-light: 200;
  --weight-body: 300;
  --weight-label: 500;
  --weight-bold: 700;
  --weight-black: 800;
  --bg-0: #050608;
  --bg-1: #0a0c10;
  --bg-2: #10141a;
  --bg-3: #141b23;
  --surface-0: rgba(16, 20, 26, 0.58);
  --surface-1: rgba(21, 27, 35, 0.7);
  --surface-2: rgba(28, 36, 46, 0.8);
  --glass-highlight: rgba(255, 255, 255, 0.12);
  --glass-stroke: rgba(220, 239, 255, 0.12);
  --glass-stroke-strong: rgba(220, 239, 255, 0.2);
  --glass-fill: linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)), rgba(18, 24, 31, 0.58);
  --shadow-soft: 0 24px 80px rgba(0, 0, 0, 0.42);
  --text-primary: #f4f7fb;
  --text-secondary: #aab4c3;
  --text-tertiary: #7d8898;
  --accent-frost: #dcefff;
  --accent-cyan: #7dd3ff;
  --accent-aqua: #52e5d5;
  --accent-amber: #ffbf69;
  --accent-red: #ff7b90;
  --accent-lime: #a7f3b0;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-soft: cubic-bezier(0.23, 1, 0.32, 1);
  --page-width: min(1400px, calc(100vw - 48px));
  color-scheme: dark;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-height: 100vh;
  background:
    radial-gradient(circle at top, rgba(125, 211, 255, 0.08), transparent 26%),
    linear-gradient(180deg, var(--bg-0), var(--bg-1) 32%, var(--bg-2));
  color: var(--text-primary);
  font-family: var(--font-body);
  font-weight: var(--weight-body);
  letter-spacing: 0.01em;
}

a {
  color: inherit;
  text-decoration: none;
}

button,
input {
  font: inherit;
}

button {
  background: none;
  border: 0;
  color: inherit;
}

input {
  color: inherit;
}

::selection {
  background: rgba(125, 211, 255, 0.24);
  color: var(--text-primary);
}

.gw-root {
  min-height: 100vh;
  position: relative;
  overflow-x: hidden;
}

.gw-page {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
}

.gw-page-inner {
  position: relative;
  z-index: 2;
  width: var(--page-width);
  margin: 0 auto;
  padding: 24px 0 56px;
}

.gw-page-inner--landing {
  padding-top: 28px;
}

.gw-page-inner--auth {
  padding-top: 32px;
}

.gw-page-inner--app {
  padding-top: 24px;
}

.gw-ambient {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.gw-light-pool {
  position: absolute;
  border-radius: 999px;
  filter: blur(26px);
  opacity: 0.8;
}

.gw-light-pool-one {
  width: 36rem;
  height: 36rem;
  left: -8rem;
  top: -8rem;
  background: radial-gradient(circle, rgba(125, 211, 255, 0.3) 0%, rgba(125, 211, 255, 0.06) 45%, transparent 72%);
  animation: gwDrift 16s ease-in-out infinite alternate;
}

.gw-light-pool-two {
  width: 42rem;
  height: 42rem;
  right: -10rem;
  top: 10rem;
  background: radial-gradient(circle, rgba(82, 229, 213, 0.18) 0%, rgba(82, 229, 213, 0.04) 46%, transparent 72%);
  animation: gwDriftAlt 18s ease-in-out infinite alternate;
}

.gw-light-pool-three {
  width: 30rem;
  height: 30rem;
  left: 32%;
  bottom: -8rem;
  background: radial-gradient(circle, rgba(255, 191, 105, 0.12) 0%, rgba(255, 191, 105, 0.03) 48%, transparent 72%);
  animation: gwDrift 14s ease-in-out infinite alternate;
}

.gw-orb {
  position: absolute;
  border-radius: 999px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.14), rgba(255, 255, 255, 0.04)),
    rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(220, 239, 255, 0.08);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    0 24px 60px rgba(0, 0, 0, 0.24);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
}

.gw-orb-one {
  width: 14rem;
  height: 14rem;
  right: 12%;
  top: 7%;
  animation: gwFloatSlow 15s var(--ease-soft) infinite;
}

.gw-orb-two {
  width: 9rem;
  height: 9rem;
  left: 12%;
  bottom: 18%;
  animation: gwFloatAlt 11s var(--ease-soft) infinite;
}

.gw-ambient-lines {
  position: absolute;
  inset: -2% -5%;
  width: 110%;
  height: 104%;
  opacity: 0.18;
}

.gw-ambient-auth .gw-ambient-lines {
  opacity: 0.14;
}

.gw-noise-layer {
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
  opacity: 0.055;
  mix-blend-mode: soft-light;
}

.gw-glass-panel {
  position: relative;
  background: var(--glass-fill);
  border: 1px solid var(--glass-stroke);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.1),
    inset 0 0 24px rgba(255, 255, 255, 0.03),
    var(--shadow-soft);
  backdrop-filter: blur(24px) saturate(145%);
  -webkit-backdrop-filter: blur(24px) saturate(145%);
}

.gw-glass-panel::before {
  content: "";
  position: absolute;
  inset: 1px;
  border-radius: inherit;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.05), transparent 40%);
  opacity: 0.8;
  pointer-events: none;
}

.gw-glass-button {
  position: relative;
  overflow: hidden;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.7rem;
  border-radius: 999px;
  padding: 0.92rem 1.35rem;
  border: 1px solid rgba(220, 239, 255, 0.15);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.12), rgba(255, 255, 255, 0.04)),
    rgba(17, 22, 29, 0.74);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 16px 32px rgba(0, 0, 0, 0.28);
  color: var(--text-primary);
  cursor: pointer;
  transition:
    transform 220ms var(--ease-out),
    border-color 220ms var(--ease-out),
    background 220ms var(--ease-out),
    box-shadow 220ms var(--ease-out);
}

.gw-glass-button::before {
  content: "";
  position: absolute;
  inset: -150% 28%;
  transform: rotate(24deg);
  background: linear-gradient(180deg, transparent, rgba(255, 255, 255, 0.18), transparent);
  opacity: 0;
  transition: opacity 220ms var(--ease-out);
}

.gw-glass-button:hover,
.gw-glass-button:focus-visible {
  transform: translateY(-2px);
  border-color: rgba(220, 239, 255, 0.26);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.14),
    0 22px 40px rgba(0, 0, 0, 0.34);
}

.gw-glass-button:hover::before,
.gw-glass-button:focus-visible::before {
  opacity: 1;
}

.gw-glass-button:focus-visible,
.gw-nav-link:focus-visible,
.gw-sidebar-item:focus-visible,
.gw-feed-row:focus-visible,
.gw-provider-button:focus-visible,
.gw-auth-input:focus-visible {
  outline: 2px solid rgba(125, 211, 255, 0.62);
  outline-offset: 2px;
}

.gw-button-primary {
  background:
    linear-gradient(180deg, rgba(220, 239, 255, 0.18), rgba(220, 239, 255, 0.07)),
    rgba(125, 211, 255, 0.16);
  border-color: rgba(125, 211, 255, 0.28);
}

.gw-button-secondary {
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)),
    rgba(17, 22, 29, 0.62);
}

.gw-button-ghost {
  background: transparent;
  border-color: rgba(220, 239, 255, 0.1);
}

.gw-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  border-radius: 999px;
  padding: 0.4rem 0.8rem;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(255, 255, 255, 0.03);
  font-size: 0.78rem;
  color: var(--text-secondary);
}

.gw-kicker {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-weight: var(--weight-label);
  color: rgba(220, 239, 255, 0.76);
}

.gw-kicker::before {
  content: "";
  width: 44px;
  height: 1px;
  background: linear-gradient(90deg, rgba(82, 229, 213, 0), rgba(82, 229, 213, 0.8));
}

.gw-shell-nav {
  position: sticky;
  top: 18px;
  z-index: 10;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 18px;
  padding: 18px 22px;
  border-radius: 28px;
}

.gw-header-links {
  display: flex;
  justify-content: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.gw-nav-link {
  padding: 0.7rem 0.92rem;
  border-radius: 999px;
  font-size: 0.9rem;
  color: var(--text-secondary);
  transition: color 180ms var(--ease-out), background 180ms var(--ease-out);
}

.gw-nav-link:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--text-primary);
}

.gw-wordmark {
  display: inline-flex;
  align-items: center;
  gap: 0.95rem;
}

.gw-wordmark-copy {
  display: flex;
  flex-direction: column;
  gap: 0.16rem;
}

.gw-wordmark-title {
  font-family: var(--font-display);
  font-size: 1.08rem;
  font-weight: var(--weight-bold);
  letter-spacing: -0.03em;
}

.gw-wordmark-subtitle {
  color: var(--text-tertiary);
  font-size: 0.78rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.gw-mark {
  position: relative;
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background:
    radial-gradient(circle at 30% 25%, rgba(255, 255, 255, 0.24), transparent 42%),
    linear-gradient(180deg, rgba(220, 239, 255, 0.18), rgba(17, 22, 29, 0.7));
  border: 1px solid rgba(220, 239, 255, 0.16);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 10px 26px rgba(0, 0, 0, 0.28);
}

.gw-mark-core {
  position: absolute;
  inset: 13px;
  border-radius: 999px;
  background: radial-gradient(circle, rgba(125, 211, 255, 0.9), rgba(82, 229, 213, 0.36) 54%, transparent 70%);
  filter: blur(0.5px);
}

.gw-mark-orbit {
  position: absolute;
  inset: 7px;
  border-radius: 999px;
  border: 1px solid rgba(220, 239, 255, 0.2);
}

.gw-mark-orbit-one {
  inset: 8px 11px 16px 11px;
}

.gw-mark-orbit-two {
  inset: 15px 8px 9px 15px;
}

.gw-role-panel {
  max-width: 920px;
  margin: 0 auto;
  padding-top: 48px;
}

.gw-role-head {
  text-align: center;
  margin-bottom: 36px;
}

.gw-role-title {
  margin: 12px 0 14px;
  font-family: var(--font-display);
  font-size: clamp(2rem, 4vw, 2.75rem);
  font-weight: var(--weight-black);
  letter-spacing: -0.04em;
  line-height: 1.1;
}

.gw-role-sub {
  margin: 0 auto;
  max-width: 52ch;
  color: var(--text-secondary);
  font-size: 1.05rem;
  line-height: 1.75;
}

.gw-role-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.gw-role-card {
  display: block;
  padding: 26px 26px 24px;
  border-radius: 22px;
  color: inherit;
  text-decoration: none;
  border: 1px solid rgba(220, 239, 255, 0.14);
  transition: border-color 0.25s var(--ease-out), transform 0.25s var(--ease-out);
}

.gw-role-card:hover {
  border-color: rgba(125, 211, 255, 0.4);
  transform: translateY(-3px);
}

.gw-role-card-kicker {
  font-size: 0.78rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--accent-cyan);
  font-weight: var(--weight-label);
  margin-bottom: 10px;
}

.gw-role-card-title {
  font-family: var(--font-display);
  font-size: 1.35rem;
  margin: 0 0 10px;
  font-weight: var(--weight-bold);
}

.gw-role-card-body {
  margin: 0;
  color: var(--text-secondary);
  font-size: 0.98rem;
  line-height: 1.65;
}

.gw-role-back {
  display: inline-flex;
  margin-bottom: 22px;
  font-size: 0.92rem;
  color: var(--text-secondary);
}

.gw-role-back:hover {
  color: var(--text-primary);
}

.gw-landing-main {
  display: grid;
  gap: 54px;
  padding-top: 46px;
}

.gw-hero {
  display: grid;
  grid-template-columns: minmax(0, 1.04fr) minmax(0, 0.96fr);
  gap: 32px;
  align-items: center;
}

.gw-hero-copy {
  position: relative;
  z-index: 2;
}

.gw-hero-title {
  margin: 18px 0 18px;
  font-family: var(--font-display);
  font-size: clamp(3.2rem, 7vw, 6.4rem);
  line-height: 0.92;
  letter-spacing: -0.06em;
  font-weight: var(--weight-black);
  max-width: 11ch;
}

.gw-hero-text {
  margin: 0 0 28px;
  max-width: 58ch;
  color: var(--text-secondary);
  font-size: clamp(1.02rem, 1.5vw, 1.24rem);
  line-height: 1.88;
}

.gw-hero-actions {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  margin-bottom: 26px;
}

.gw-chip-row {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 26px;
}

.gw-metric-chip {
  border-radius: 20px;
  padding: 18px;
}

.gw-metric-value {
  font-family: var(--font-display);
  font-size: 1.8rem;
  font-weight: var(--weight-black);
  letter-spacing: -0.05em;
}

.gw-metric-label {
  margin-top: 0.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.gw-metric-detail {
  margin-top: 0.25rem;
  color: var(--text-tertiary);
  font-size: 0.78rem;
}

.gw-system-strip {
  border-radius: 24px;
  padding: 16px 18px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.gw-system-strip span {
  font-size: 0.82rem;
  font-weight: var(--weight-label);
  color: rgba(220, 239, 255, 0.84);
  padding: 0.58rem 0.78rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.gw-hero-visual {
  position: relative;
  min-height: 640px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.gw-ghost-emblem {
  width: min(100%, 560px);
  height: auto;
}

.gw-hero-alert-card,
.gw-hero-telemetry {
  position: absolute;
  border-radius: 22px;
  padding: 18px 20px;
}

.gw-hero-alert-card {
  left: 2%;
  bottom: 6%;
  width: min(320px, 72%);
}

.gw-hero-alert-label,
.gw-telemetry-label {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-hero-alert-label::before,
.gw-telemetry-label::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-red);
  box-shadow: 0 0 18px rgba(255, 123, 144, 0.65);
}

.gw-hero-alert-title,
.gw-telemetry-value {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.28rem;
  font-weight: var(--weight-bold);
  letter-spacing: -0.03em;
}

.gw-hero-alert-copy,
.gw-telemetry-copy {
  margin-top: 0.55rem;
  color: var(--text-secondary);
  line-height: 1.6;
  font-size: 0.92rem;
}

.gw-telemetry {
  width: min(240px, 46%);
}

.gw-telemetry-top {
  right: -2%;
  top: 10%;
}

.gw-telemetry-middle {
  left: 6%;
  top: 13%;
}

.gw-telemetry-bottom {
  right: 8%;
  bottom: 18%;
}

.gw-section {
  position: relative;
}

.gw-section-head {
  margin-bottom: 22px;
  max-width: 760px;
}

.gw-section-title {
  margin: 12px 0 10px;
  font-family: var(--font-display);
  font-size: clamp(2.2rem, 4.3vw, 3.6rem);
  line-height: 0.98;
  letter-spacing: -0.05em;
  font-weight: var(--weight-black);
}

.gw-section-copy {
  margin: 0;
  color: var(--text-secondary);
  font-size: 1rem;
  line-height: 1.8;
}

.gw-feature-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.gw-feature-card {
  min-height: 250px;
  border-radius: 28px;
  padding: 24px;
}

.gw-feature-icon {
  width: 56px;
  height: 56px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 18px;
  background:
    radial-gradient(circle at 30% 25%, rgba(255, 255, 255, 0.14), transparent 46%),
    rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(220, 239, 255, 0.08);
  margin-bottom: 22px;
}

.gw-feature-title {
  margin: 0;
  font-family: var(--font-display);
  font-size: 1.34rem;
  letter-spacing: -0.03em;
}

.gw-feature-body {
  margin: 0.9rem 0 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-flow-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 18px;
}

.gw-flow-card {
  border-radius: 26px;
  padding: 22px 18px;
}

.gw-flow-step {
  color: rgba(220, 239, 255, 0.78);
  font-size: 0.74rem;
  font-weight: var(--weight-label);
  letter-spacing: 0.2em;
  text-transform: uppercase;
}

.gw-flow-name {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.18rem;
  letter-spacing: -0.03em;
}

.gw-flow-copy {
  margin-top: 0.7rem;
  color: var(--text-secondary);
  line-height: 1.7;
  font-size: 0.92rem;
}

.gw-flow-pulse {
  margin-top: 1.15rem;
  height: 2px;
  width: 100%;
  background: linear-gradient(90deg, rgba(125, 211, 255, 0), rgba(125, 211, 255, 0.92), rgba(82, 229, 213, 0));
  opacity: 0.82;
  animation: gwScan 4.8s linear infinite;
}

.gw-preview-shell {
  border-radius: 30px;
  padding: 22px;
}

.gw-preview-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 18px;
  margin-bottom: 18px;
}

.gw-preview-topbar-left,
.gw-preview-topbar-right {
  display: flex;
  gap: 10px;
  align-items: center;
}

.gw-preview-pill,
.gw-preview-dot {
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(220, 239, 255, 0.08);
}

.gw-preview-pill {
  height: 34px;
}

.gw-preview-pill-wide {
  width: 180px;
}

.gw-preview-pill-small {
  width: 98px;
}

.gw-preview-dot {
  width: 34px;
  height: 34px;
}

.gw-preview-body {
  display: grid;
  grid-template-columns: 170px minmax(0, 1fr);
  gap: 16px;
  min-height: 320px;
}

.gw-preview-sidebar {
  border-radius: 24px;
  padding: 16px;
  display: grid;
  gap: 12px;
}

.gw-preview-sidebar-line {
  height: 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.06);
}

.gw-preview-content {
  display: grid;
  gap: 16px;
}

.gw-preview-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.gw-preview-card {
  min-height: 92px;
  border-radius: 22px;
  padding: 16px;
}

.gw-preview-card-label {
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-preview-card-value {
  margin-top: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.45rem;
  letter-spacing: -0.04em;
}

.gw-preview-graph {
  position: relative;
  min-height: 192px;
  border-radius: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  text-align: center;
}

.gw-preview-graph::after {
  content: "";
  position: absolute;
  inset: 18px;
  border-radius: 20px;
  border: 1px dashed rgba(220, 239, 255, 0.18);
}

.gw-cta-panel {
  border-radius: 30px;
  padding: 30px;
  display: flex;
  justify-content: space-between;
  gap: 22px;
  align-items: flex-end;
}

.gw-cta-copy h3 {
  margin: 0 0 12px;
  font-family: var(--font-display);
  font-size: clamp(1.8rem, 4vw, 3rem);
  letter-spacing: -0.05em;
}

.gw-cta-copy p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-cta-actions {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
}

.gw-auth-grid {
  display: grid;
  grid-template-columns: minmax(0, 0.92fr) minmax(0, 1.08fr);
  gap: 30px;
  align-items: center;
  min-height: calc(100vh - 72px);
}

.gw-auth-story {
  position: relative;
  display: grid;
  gap: 20px;
}

.gw-auth-title {
  margin: 8px 0 0;
  max-width: 10ch;
  font-family: var(--font-display);
  font-size: clamp(2.8rem, 6vw, 5.2rem);
  line-height: 0.94;
  letter-spacing: -0.06em;
  font-weight: var(--weight-black);
}

.gw-auth-copy {
  margin: 0;
  max-width: 48ch;
  color: var(--text-secondary);
  line-height: 1.85;
}

.gw-auth-visual {
  width: min(100%, 520px);
  margin-top: 10px;
}

.gw-auth-surface {
  display: grid;
  gap: 18px;
}

.gw-auth-card,
.gw-auth-note-card {
  border-radius: 30px;
}

.gw-auth-card {
  padding: 30px;
}

.gw-auth-form {
  display: grid;
  gap: 16px;
}

.gw-auth-card-header h2 {
  margin: 0 0 10px;
  font-family: var(--font-display);
  font-size: 2rem;
  letter-spacing: -0.04em;
}

.gw-auth-card-header p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.7;
}

.gw-provider-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.gw-provider-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 0.96rem 1rem;
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02)),
    rgba(18, 24, 31, 0.62);
  color: var(--text-primary);
  cursor: pointer;
  transition: transform 180ms var(--ease-out), border-color 180ms var(--ease-out);
}

.gw-provider-button:hover {
  transform: translateY(-2px);
  border-color: rgba(220, 239, 255, 0.2);
}

.gw-provider-icon {
  width: 20px;
  height: 20px;
}

.gw-auth-divider {
  display: flex;
  align-items: center;
  gap: 0.9rem;
  color: var(--text-tertiary);
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-auth-divider::before,
.gw-auth-divider::after {
  content: "";
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, rgba(220, 239, 255, 0), rgba(220, 239, 255, 0.18), rgba(220, 239, 255, 0));
}

.gw-auth-field {
  display: grid;
  gap: 0.55rem;
}

.gw-auth-label {
  font-size: 0.8rem;
  color: rgba(220, 239, 255, 0.7);
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.gw-auth-input {
  width: 100%;
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(8, 11, 15, 0.5);
  padding: 1rem 1.05rem;
  min-height: 56px;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  transition: border-color 180ms var(--ease-out), background 180ms var(--ease-out);
}

.gw-auth-input::placeholder {
  color: rgba(125, 136, 152, 0.72);
}

.gw-auth-input:hover,
.gw-auth-input:focus-visible {
  border-color: rgba(125, 211, 255, 0.3);
  background: rgba(10, 14, 19, 0.65);
}

.gw-auth-legal {
  color: var(--text-tertiary);
  font-size: 0.82rem;
  line-height: 1.7;
}

.gw-auth-note-card {
  padding: 22px 24px;
}

.gw-note-list {
  display: grid;
  gap: 12px;
  margin-top: 16px;
}

.gw-note-item {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 0.88rem 0.96rem;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
  color: var(--text-secondary);
}

.gw-note-item span:first-child {
  color: var(--text-primary);
}

.gw-app-shell {
  display: grid;
  grid-template-columns: 286px minmax(0, 1fr);
  gap: 22px;
  min-height: calc(100vh - 48px);
}

.gw-sidebar {
  border-radius: 32px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.gw-sidebar-nav {
  display: grid;
  gap: 10px;
}

.gw-sidebar-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.92rem 1rem;
  border-radius: 20px;
  border: 1px solid transparent;
  cursor: pointer;
  color: var(--text-secondary);
  transition:
    background 180ms var(--ease-out),
    border-color 180ms var(--ease-out),
    transform 180ms var(--ease-out),
    color 180ms var(--ease-out);
}

.gw-sidebar-item:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--text-primary);
}

.gw-sidebar-item.is-active {
  background:
    linear-gradient(180deg, rgba(220, 239, 255, 0.12), rgba(220, 239, 255, 0.03)),
    rgba(125, 211, 255, 0.08);
  border-color: rgba(125, 211, 255, 0.16);
  color: var(--text-primary);
  transform: translateX(2px);
}

.gw-sidebar-icon {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.08);
  font-family: var(--font-mono);
  font-size: 0.74rem;
  color: rgba(220, 239, 255, 0.84);
}

.gw-sidebar-copy {
  display: grid;
  gap: 0.16rem;
  text-align: left;
}

.gw-sidebar-copy strong {
  font-size: 0.94rem;
  letter-spacing: -0.02em;
}

.gw-sidebar-copy span {
  font-size: 0.76rem;
  color: var(--text-tertiary);
}

.gw-sidebar-footer {
  margin-top: auto;
  display: grid;
  gap: 14px;
}

.gw-demo-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  width: fit-content;
  padding: 0.7rem 0.88rem;
  border-radius: 999px;
  background: rgba(82, 229, 213, 0.07);
  border: 1px solid rgba(82, 229, 213, 0.14);
  color: rgba(220, 255, 250, 0.92);
  font-size: 0.8rem;
  font-weight: var(--weight-label);
}

.gw-demo-badge::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-aqua);
  box-shadow: 0 0 18px rgba(82, 229, 213, 0.5);
}

.gw-profile-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.92rem 1rem;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.08);
}

.gw-avatar {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 35% 30%, rgba(255, 255, 255, 0.18), transparent 40%),
    linear-gradient(180deg, rgba(125, 211, 255, 0.24), rgba(17, 22, 29, 0.8));
  border: 1px solid rgba(220, 239, 255, 0.16);
  font-family: var(--font-display);
  font-weight: var(--weight-bold);
}

.gw-profile-meta {
  display: grid;
  gap: 0.2rem;
}

.gw-profile-meta strong {
  font-size: 0.92rem;
}

.gw-profile-meta span {
  color: var(--text-tertiary);
  font-size: 0.78rem;
}

.gw-workspace {
  display: grid;
  gap: 18px;
}

.gw-topbar {
  border-radius: 30px;
  padding: 18px 20px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 18px;
  align-items: center;
}

.gw-topbar-heading {
  display: grid;
  gap: 0.5rem;
}

.gw-topbar-heading h1 {
  margin: 0;
  font-family: var(--font-display);
  font-size: clamp(1.8rem, 3vw, 2.8rem);
  letter-spacing: -0.04em;
}

.gw-topbar-heading p {
  margin: 0;
  color: var(--text-secondary);
}

.gw-topbar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.gw-repo-select,
.gw-icon-button,
.gw-search-shell {
  border-radius: 18px;
  border: 1px solid rgba(220, 239, 255, 0.1);
  background: rgba(8, 11, 15, 0.34);
  min-height: 52px;
}

.gw-repo-select {
  display: inline-flex;
  align-items: center;
  gap: 0.78rem;
  padding: 0 1rem;
}

.gw-repo-label {
  display: grid;
  gap: 0.16rem;
  text-align: left;
}

.gw-repo-label strong {
  font-size: 0.92rem;
}

.gw-repo-label span {
  font-size: 0.76rem;
  color: var(--text-tertiary);
}

.gw-search-shell {
  display: inline-flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0 0.9rem;
  min-width: 280px;
}

.gw-search-shell svg {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.gw-search-input {
  width: 100%;
  background: transparent;
  border: 0;
  outline: none;
}

.gw-icon-button {
  width: 52px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: pointer;
}

.gw-icon-badge {
  position: absolute;
  top: 9px;
  right: 9px;
  min-width: 18px;
  height: 18px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 123, 144, 0.92);
  color: #10131a;
  font-size: 0.68rem;
  font-weight: var(--weight-bold);
}

.gw-command-banner {
  border-radius: 24px;
  padding: 16px 18px;
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: center;
}

.gw-command-banner strong {
  font-size: 0.88rem;
  text-transform: uppercase;
  letter-spacing: 0.16em;
  color: rgba(220, 239, 255, 0.78);
}

.gw-command-banner p {
  margin: 0.45rem 0 0;
  color: var(--text-secondary);
  line-height: 1.7;
}

.gw-main-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 330px;
  gap: 20px;
}

.gw-main-column {
  display: grid;
  gap: 18px;
}

.gw-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 18px;
}

.gw-summary-card {
  border-radius: 24px;
  padding: 20px;
  display: grid;
  gap: 1rem;
}

.gw-summary-card.is-frost {
  border-color: rgba(220, 239, 255, 0.18);
}

.gw-summary-card.is-cyan {
  border-color: rgba(125, 211, 255, 0.2);
}

.gw-summary-card.is-aqua {
  border-color: rgba(82, 229, 213, 0.2);
}

.gw-summary-card.is-amber {
  border-color: rgba(255, 191, 105, 0.22);
}

.gw-summary-label {
  color: var(--text-tertiary);
  font-size: 0.76rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-summary-value {
  font-family: var(--font-display);
  font-size: 2rem;
  font-weight: var(--weight-black);
  letter-spacing: -0.05em;
}

.gw-summary-delta {
  color: var(--text-secondary);
  font-size: 0.88rem;
}

.gw-summary-spark {
  width: 100%;
  height: 48px;
}

.gw-threat-panel,
.gw-graph-panel,
.gw-right-panel {
  border-radius: 28px;
  padding: 22px;
}

.gw-panel-head {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 18px;
}

.gw-panel-head h2,
.gw-right-panel h3 {
  margin: 0;
  font-family: var(--font-display);
  font-size: 1.32rem;
  letter-spacing: -0.03em;
}

.gw-panel-head p,
.gw-right-panel p {
  margin: 0.55rem 0 0;
  color: var(--text-secondary);
  line-height: 1.65;
  font-size: 0.92rem;
}

.gw-feed-list {
  display: grid;
  gap: 12px;
}

.gw-feed-row {
  width: 100%;
  display: grid;
  grid-template-columns: auto auto minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
  padding: 1rem 1.04rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.035);
  border: 1px solid rgba(220, 239, 255, 0.06);
  text-align: left;
  cursor: pointer;
  transition:
    transform 180ms var(--ease-out),
    border-color 180ms var(--ease-out),
    background 180ms var(--ease-out);
}

.gw-feed-row:hover {
  transform: translateY(-1px);
  border-color: rgba(220, 239, 255, 0.14);
  background: rgba(255, 255, 255, 0.05);
}

.gw-feed-time {
  color: var(--text-tertiary);
  font-family: var(--font-mono);
  font-size: 0.76rem;
}

.gw-feed-copy strong {
  display: block;
  font-size: 0.94rem;
  letter-spacing: -0.02em;
}

.gw-feed-copy span {
  display: block;
  margin-top: 0.32rem;
  color: var(--text-secondary);
  font-size: 0.84rem;
  line-height: 1.6;
}

.gw-feed-hint {
  color: rgba(220, 239, 255, 0.7);
  font-size: 0.8rem;
}

.gw-severity-pill,
.gw-state-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 0.44rem 0.7rem;
  font-size: 0.72rem;
  font-weight: var(--weight-label);
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.gw-severity-critical {
  background: rgba(255, 123, 144, 0.12);
  color: rgba(255, 189, 199, 0.94);
  border: 1px solid rgba(255, 123, 144, 0.18);
}

.gw-severity-high {
  background: rgba(255, 191, 105, 0.12);
  color: rgba(255, 214, 164, 0.96);
  border: 1px solid rgba(255, 191, 105, 0.18);
}

.gw-severity-medium {
  background: rgba(125, 211, 255, 0.12);
  color: rgba(210, 239, 255, 0.96);
  border: 1px solid rgba(125, 211, 255, 0.18);
}

.gw-state-active {
  background: rgba(82, 229, 213, 0.1);
  color: rgba(196, 255, 248, 0.94);
  border: 1px solid rgba(82, 229, 213, 0.18);
}

.gw-state-queued {
  background: rgba(255, 191, 105, 0.08);
  color: rgba(255, 224, 184, 0.92);
  border: 1px solid rgba(255, 191, 105, 0.16);
}

.gw-state-watching {
  background: rgba(125, 211, 255, 0.1);
  color: rgba(219, 244, 255, 0.94);
  border: 1px solid rgba(125, 211, 255, 0.16);
}

.gw-graph-panel {
  position: relative;
  min-height: 470px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.gw-graph-inner-frame {
  position: absolute;
  inset: 22px;
  border-radius: 26px;
  border: 1px dashed rgba(220, 239, 255, 0.18);
  box-shadow:
    inset 0 0 80px rgba(125, 211, 255, 0.02),
    inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.gw-graph-copy {
  position: relative;
  z-index: 2;
  max-width: 560px;
  text-align: center;
}

.gw-graph-copy span {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  border-radius: 999px;
  padding: 0.48rem 0.82rem;
  border: 1px solid rgba(220, 239, 255, 0.12);
  background: rgba(255, 255, 255, 0.04);
  color: rgba(220, 239, 255, 0.84);
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.18em;
}

.gw-graph-copy span::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent-cyan);
  box-shadow: 0 0 14px rgba(125, 211, 255, 0.5);
}

.gw-graph-copy h2 {
  margin: 1.15rem 0 0.8rem;
  font-family: var(--font-display);
  font-size: clamp(2rem, 4vw, 3.1rem);
  line-height: 0.96;
  letter-spacing: -0.05em;
}

.gw-graph-copy p {
  margin: 0;
  color: var(--text-secondary);
  line-height: 1.8;
}

.gw-graph-foot {
  margin-top: 1.15rem;
  color: var(--text-tertiary);
  font-size: 0.88rem;
}

.gw-graph-constellation {
  position: absolute;
  inset: 6px;
  width: calc(100% - 12px);
  height: calc(100% - 12px);
  opacity: 0.42;
}

.gw-right-rail {
  display: grid;
  gap: 18px;
}

.gw-right-panel {
  border-radius: 28px;
}

.gw-right-list {
  display: grid;
  gap: 12px;
  margin-top: 14px;
}

.gw-right-item {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  align-items: center;
  padding: 0.88rem 0.95rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
}

.gw-right-item strong {
  font-size: 0.9rem;
  letter-spacing: -0.02em;
}

.gw-right-item span {
  color: var(--text-secondary);
  font-size: 0.78rem;
}

.gw-session-notes {
  display: grid;
  gap: 10px;
  margin-top: 14px;
}

.gw-session-note {
  padding: 0.9rem 0.98rem;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(220, 239, 255, 0.06);
  color: var(--text-secondary);
  line-height: 1.7;
  font-size: 0.88rem;
}

.gw-fade-up {
  opacity: 0;
  transform: translateY(26px) scale(0.985);
  animation: gwFadeUp 0.88s var(--ease-out) forwards;
}

.gw-stagger-1 {
  animation-delay: 0.08s;
}

.gw-stagger-2 {
  animation-delay: 0.16s;
}

.gw-stagger-3 {
  animation-delay: 0.24s;
}

.gw-stagger-4 {
  animation-delay: 0.32s;
}

.gw-stagger-5 {
  animation-delay: 0.4s;
}

.gw-stagger-6 {
  animation-delay: 0.48s;
}

.gw-stagger-7 {
  animation-delay: 0.56s;
}

.gw-float-slow {
  animation: gwFloatSlow 14s var(--ease-soft) infinite;
}

.gw-float-medium {
  animation: gwFloatMedium 10s var(--ease-soft) infinite;
}

.gw-float-delay {
  animation: gwFloatAlt 12s var(--ease-soft) infinite;
}

@keyframes gwFadeUp {
  from {
    opacity: 0;
    transform: translateY(26px) scale(0.985);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes gwFloatSlow {
  0%,
  100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-12px);
  }
}

@keyframes gwFloatMedium {
  0%,
  100% {
    transform: translate3d(0, 0, 0);
  }
  50% {
    transform: translate3d(0, -18px, 0);
  }
}

@keyframes gwFloatAlt {
  0%,
  100% {
    transform: translate3d(0, 0, 0);
  }
  50% {
    transform: translate3d(0, 12px, 0);
  }
}

@keyframes gwDrift {
  0% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  100% {
    transform: translate3d(30px, 18px, 0) scale(1.04);
  }
}

@keyframes gwDriftAlt {
  0% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  100% {
    transform: translate3d(-24px, -18px, 0) scale(1.05);
  }
}

@keyframes gwScan {
  0% {
    transform: scaleX(0.65);
    transform-origin: left center;
    opacity: 0.45;
  }
  50% {
    transform: scaleX(1);
    transform-origin: center center;
    opacity: 0.92;
  }
  100% {
    transform: scaleX(0.65);
    transform-origin: right center;
    opacity: 0.45;
  }
}

@media (max-width: 1240px) {
  .gw-hero {
    grid-template-columns: 1fr;
  }

  .gw-hero-copy {
    order: 1;
  }

  .gw-hero-visual {
    order: 0;
    min-height: 560px;
  }

  .gw-flow-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .gw-main-grid {
    grid-template-columns: 1fr;
  }

  .gw-right-rail {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .gw-summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 980px) {
  .gw-page-inner {
    width: min(100vw - 28px, 100%);
  }

  .gw-shell-nav {
    grid-template-columns: 1fr;
    justify-items: start;
  }

  .gw-header-links {
    justify-content: flex-start;
  }

  .gw-feature-grid,
  .gw-flow-grid,
  .gw-chip-row,
  .gw-summary-grid,
  .gw-right-rail,
  .gw-provider-grid {
    grid-template-columns: 1fr;
  }

  .gw-preview-body,
  .gw-auth-grid,
  .gw-app-shell {
    grid-template-columns: 1fr;
  }

  .gw-role-grid {
    grid-template-columns: 1fr;
  }

  .gw-sidebar {
    order: 0;
  }

  .gw-topbar {
    grid-template-columns: 1fr;
  }

  .gw-topbar-actions {
    justify-content: stretch;
  }

  .gw-search-shell {
    min-width: 0;
    width: 100%;
  }
}

@media (max-width: 720px) {
  .gw-page-inner {
    padding-top: 18px;
  }

  .gw-shell-nav {
    padding-top: 12px;
  }

  .gw-hero-telemetry,
  .gw-hero-alert-card {
    position: static;
    width: 100%;
    margin-top: 16px;
  }

  .gw-hero-visual {
    display: grid;
    justify-items: center;
    gap: 16px;
    min-height: auto;
  }

  .gw-hero-actions,
  .gw-cta-actions,
  .gw-topbar-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .gw-provider-grid {
    grid-template-columns: 1fr;
  }

  .gw-feed-row {
    grid-template-columns: 1fr;
    justify-items: start;
  }

  .gw-command-banner {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }

  .gw-fade-up {
    opacity: 1;
    transform: none;
  }
}
""";

cl glob LANDING_METRICS: list[dict[str, str]] = [
         {
             "value": "42",
             "label": "open findings reviewed",
             "detail": "Critical paths triaged before merge.",
             "delay": "gw-stagger-3"
         },
         {
             "value": "3",
             "label": "suspicious dependency events",
             "detail": "Flagged in demo telemetry this afternoon.",
             "delay": "gw-stagger-4"
         },
         {
             "value": "11.8s",
             "label": "median verdict delivery",
             "detail": "Mock pipeline tuned for live traversal.",
             "delay": "gw-stagger-5"
         }
     ];

cl glob LANDING_FEATURES: list[dict[str, str]] = [
         {
             "title": "Graph-native awareness",
             "body": "GhostWatch treats the repository as topology, not a folder list, so review context feels spatial instead of isolated.",
             "kind": "graph",
             "delay": "gw-stagger-2"
         },
         {
             "title": "Specialist walker verdicts",
             "body": "Security, compatibility, and blast-radius perspectives stay distinct, visible, and composable instead of melting into one vague answer.",
             "kind": "walkers",
             "delay": "gw-stagger-3"
         },
         {
             "title": "Maintainer-first control",
             "body": "Automation moves fast, but human approval remains legible, central, and calm inside the control room.",
             "kind": "shield",
             "delay": "gw-stagger-4"
         }
     ];

cl glob FLOW_STEPS: list[dict[str, str]] = [
         {
             "step": "01",
             "title": "Detect",
             "body": "Spot pull request movement or manifest drift before the change disappears into the background.",
             "delay": "gw-stagger-2"
         },
         {
             "step": "02",
             "title": "Traverse",
             "body": "Move through connected files and dependency paths with topology-aware context.",
             "delay": "gw-stagger-3"
         },
         {
             "step": "03",
             "title": "Score",
             "body": "Translate structural impact into a risk surface that stays understandable at a glance.",
             "delay": "gw-stagger-4"
         },
         {
             "step": "04",
             "title": "Escalate",
             "body": "Surface the right severity to maintainers without turning the interface into an alarm storm.",
             "delay": "gw-stagger-5"
         },
         {
             "step": "05",
             "title": "Prepare Fix",
             "body": "Keep the UI ready for auto-fix evidence, branch context, and merge handoff the moment it is available.",
             "delay": "gw-stagger-6"
         }
     ];

cl glob SIDEBAR_ITEMS: list[dict[str, str]] = [
         {"icon": "OV", "label": "Overview", "meta": "Command surface"},
         {"icon": "PR", "label": "PR Review", "meta": "Touched paths"},
         {"icon": "DP", "label": "Dependency Alerts", "meta": "Manifest drift"},
         {"icon": "IN", "label": "Incidents", "meta": "Escalation feed"},
         {"icon": "ST", "label": "Settings", "meta": "Demo controls"}
     ];

cl glob SUMMARY_CARDS: list[dict[str, str]] = [
         {
             "label": "Open PRs Under Watch",
             "value": "12",
             "delta": "+2 today",
             "tone": "frost",
             "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
         },
         {
             "label": "Critical Findings",
             "value": "03",
             "delta": "1 path cooling",
             "tone": "cyan",
             "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
         },
         {
             "label": "Dependency Drift",
             "value": "07",
             "delta": "2 unresolved",
             "tone": "aqua",
             "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
         },
         {
             "label": "Review Throughput",
             "value": "94%",
             "delta": "median stable",
             "tone": "amber",
             "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
         }
     ];

cl glob INCIDENTS: list[dict[str, str]] = [
         {
             "time": "14:02",
             "severity": "critical",
             "title": "Suspicious manifest delta",
             "detail": "A runtime package appeared without an import trail across the watched subgraph.",
             "hint": "Inspect manifest drift"
         },
         {
             "time": "13:44",
             "severity": "high",
             "title": "High-risk PR path touched",
             "detail": "A core auth boundary changed near configuration loading and transport code.",
             "hint": "Trace blast radius"
         },
         {
             "time": "13:08",
             "severity": "medium",
             "title": "Auto-fix branch prepared",
             "detail": "The demo pipeline staged a clean manifest candidate and attached evidence notes.",
             "hint": "Open review handoff"
         }
     ];

cl glob WALKER_STATUS: list[dict[str, str]] = [
         {"name": "Security Auditor", "state": "Active"},
         {"name": "Compatibility Checker", "state": "Queued"},
         {"name": "Blast Radius Mapper", "state": "Watching"}
     ];

cl glob ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Maintainer approvals pending", "value": "2 pending"},
         {"title": "Dependency lockfile mismatch", "value": "1 unresolved"},
         {"title": "Comments ready to post", "value": "4 prepared"}
     ];

cl glob SESSION_NOTES: list[str] = [
         "Demo mode is using local placeholder telemetry so the shell stays expressive before live walkers are connected.",
         "The graph canvas is intentionally reserved for future playback and remains visually framed instead of mocked.",
         "Every hardcoded value in this screen lives in centralized constants so backend walker responses can replace them later."
     ];

cl glob CONTRIBUTOR_SIDEBAR_ITEMS: list[dict[str, str]] = [
         {"icon": "OV", "label": "Overview", "meta": "Your workspace"},
         {"icon": "SG", "label": "Suggestions", "meta": "Gap analysis picks"},
         {"icon": "DC", "label": "Docs & tests", "meta": "Coverage hints"},
         {"icon": "AC", "label": "Activity", "meta": "Recent merges"},
         {"icon": "ST", "label": "Settings", "meta": "Demo controls"}
     ];

cl glob CONTRIBUTOR_SUMMARY_CARDS: list[dict[str, str]] = [
         {
             "label": "Open suggestions",
             "value": "05",
             "delta": "from latest gap run",
             "tone": "frost",
             "spark": "6,32 42,22 80,18 122,24 160,12 198,16 236,14 274,10"
         },
         {
             "label": "Untested paths",
             "value": "08",
             "delta": "3 quick wins",
             "tone": "cyan",
             "spark": "6,30 42,28 80,20 122,26 160,16 198,14 236,12 274,11"
         },
         {
             "label": "Docs gaps",
             "value": "04",
             "delta": "Jac modules noted",
             "tone": "aqua",
             "spark": "6,26 42,22 80,24 122,18 160,20 198,11 236,14 274,9"
         },
         {
             "label": "Merge velocity",
             "value": "72%",
             "delta": "rolling window",
             "tone": "amber",
             "spark": "6,34 42,24 80,22 122,18 160,20 198,13 236,10 274,12"
         }
     ];

cl glob CONTRIBUTOR_SUGGESTIONS: list[dict[str, str]] = [
         {
             "time": "10:22",
             "severity": "medium",
             "title": "Document public walker exports",
             "detail": "A Jac module exposes graph walkers without an adjacent docs section in the design tree.",
             "hint": "Open doc outline"
         },
         {
             "time": "09:58",
             "severity": "high",
             "title": "Add tests for dependency diff walker",
             "detail": "New manifest parsing paths are not linked to TestNode entries in the demo graph.",
             "hint": "View test graph"
         },
         {
             "time": "09:30",
             "severity": "medium",
             "title": "Fill stub in sandbox result view",
             "detail": "Placeholder module under core UI still reads as incomplete_feature in gap ranking.",
             "hint": "Claim slice"
         }
     ];

cl glob CONTRIBUTOR_WALKER_STATUS: list[dict[str, str]] = [
         {"name": "GapAnalysisWalker", "state": "Watching"},
         {"name": "Graph doc linker", "state": "Queued"},
         {"name": "Contributor ranker", "state": "Active"}
     ];

cl glob CONTRIBUTOR_ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Suggestions ready to pick up", "value": "3 open"},
         {"title": "Docs requested for PR #184", "value": "1 thread"},
         {"title": "Merge follow-ups", "value": "2 notes"}
     ];

cl glob CONTRIBUTOR_SESSION_NOTES: list[str] = [
         "Contributor view highlights gap-analysis output and documentation signals—placeholders until GapAnalysisWalker is live on your repo.",
         "Suggestions map to System 2 contributor picks: a small, ranked set rather than the full maintainer escalation feed.",
         "Switch to the lead maintainer home anytime via the marketing site path to compare control-room telemetry."
     ];

cl {
    def toneClass(tone: str) -> str {
        return (
            "gw-summary-card gw-glass-panel is-frost"
                if tone == "frost"
                else "gw-summary-card gw-glass-panel is-cyan"
                    if tone == "cyan"
                    else "gw-summary-card gw-glass-panel is-aqua"
                        if tone == "aqua"
                        else "gw-summary-card gw-glass-panel is-amber"
        );
    }

    def severityClass(severity: str) -> str {
        return (
            "gw-severity-pill gw-severity-critical"
                if severity == "critical"
                else "gw-severity-pill gw-severity-high"
                    if severity == "high"
                    else "gw-severity-pill gw-severity-medium"
        );
    }

    def walkerStateClass(state: str) -> str {
        return (
            "gw-state-pill gw-state-active"
                if state == "Active"
                else "gw-state-pill gw-state-queued"
                    if state == "Queued"
                    else "gw-state-pill gw-state-watching"
        );
    }

    def GhostWatchWordmark() -> JsxElement {
        return
            <div className="gw-wordmark">
                <div className="gw-mark" aria-hidden="true">
                    <span className="gw-mark-core"></span>
                    <span className="gw-mark-orbit gw-mark-orbit-one"></span>
                    <span className="gw-mark-orbit gw-mark-orbit-two"></span>
                </div>
                <div className="gw-wordmark-copy">
                    <span className="gw-wordmark-title">
                        GhostWatch
                    </span>
                    <span className="gw-wordmark-subtitle">
                        Autonomous code defense
                    </span>
                </div>
            </div>;
    }

    def AmbientBackground(screen: str) -> JsxElement {
        return
            <div className={"gw-ambient gw-ambient-" + screen} aria-hidden="true">
                <div className="gw-light-pool gw-light-pool-one"></div>
                <div className="gw-light-pool gw-light-pool-two"></div>
                <div className="gw-light-pool gw-light-pool-three"></div>
                <div className="gw-orb gw-orb-one"></div>
                <div className="gw-orb gw-orb-two"></div>
                <svg
                    className="gw-ambient-lines"
                    viewBox="0 0 1600 1000"
                    fill="none"
                    preserveAspectRatio="none"
                >
                    <path
                        d="M-40 320C220 210 520 210 740 326C982 454 1220 452 1640 280"
                        stroke="rgba(220,239,255,0.22)"
                        strokeWidth="1.5"
                    ></path>
                    <path
                        d="M-20 408C240 316 430 340 648 448C860 550 1160 582 1640 430"
                        stroke="rgba(125,211,255,0.18)"
                        strokeWidth="1.1"
                        strokeDasharray="8 12"
                    ></path>
                    <path
                        d="M60 760C320 680 470 624 702 700C980 790 1200 840 1540 738"
                        stroke="rgba(82,229,213,0.14)"
                        strokeWidth="1.1"
                    ></path>
                    <circle
                        cx="1180"
                        cy="180"
                        r="112"
                        stroke="rgba(220,239,255,0.08)"
                        strokeWidth="1"
                    ></circle>
                    <circle
                        cx="1180"
                        cy="180"
                        r="72"
                        stroke="rgba(220,239,255,0.08)"
                        strokeWidth="1"
                    ></circle>
                </svg>
                <div className="gw-noise-layer"></div>
            </div>;
    }

    def GhostShieldGraphic() -> JsxElement {
        return
            <svg
                className="gw-ghost-emblem gw-fade-up gw-stagger-2"
                viewBox="0 0 560 560"
                fill="none"
                aria-hidden="true"
            >
                <defs>
                    <linearGradient id="gwRing" x1="98" y1="74" x2="442" y2="486">
                        <stop stopColor="rgba(220,239,255,0.85)"></stop>
                        <stop offset="0.55" stopColor="rgba(125,211,255,0.3)"></stop>
                        <stop offset="1" stopColor="rgba(82,229,213,0.5)"></stop>
                    </linearGradient>
                    <linearGradient id="gwShield" x1="280" y1="114" x2="280" y2="420">
                        <stop stopColor="rgba(255,255,255,0.22)"></stop>
                        <stop offset="0.4" stopColor="rgba(125,211,255,0.16)"></stop>
                        <stop offset="1" stopColor="rgba(17,22,29,0.02)"></stop>
                    </linearGradient>
                    <filter
                        id="gwGhostBlur"
                        x="-40%"
                        y="-40%"
                        width="180%"
                        height="180%"
                    >
                        <feGaussianBlur stdDeviation="18"></feGaussianBlur>
                    </filter>
                </defs>
                <circle
                    cx="280"
                    cy="280"
                    r="196"
                    stroke="url(#gwRing)"
                    strokeWidth="1.4"
                    opacity="0.8"
                ></circle>
                <circle
                    cx="280"
                    cy="280"
                    r="156"
                    stroke="rgba(220,239,255,0.18)"
                    strokeWidth="1.2"
                    strokeDasharray="8 14"
                    opacity="0.8"
                ></circle>
                <circle
                    cx="280"
                    cy="280"
                    r="110"
                    stroke="rgba(82,229,213,0.18)"
                    strokeWidth="1.1"
                    opacity="0.9"
                ></circle>
                <circle
                    cx="280"
                    cy="280"
                    r="150"
                    fill="rgba(125,211,255,0.16)"
                    filter="url(#gwGhostBlur)"
                    opacity="0.22"
                ></circle>
                <path
                    d="M280 116C221 142 185 150 156 150V276C156 358 209 424 280 452C351 424 404 358 404 276V150C375 150 339 142 280 116Z"
                    fill="url(#gwShield)"
                    stroke="rgba(220,239,255,0.4)"
                    strokeWidth="1.5"
                ></path>
                <path
                    d="M222 204C222 168 246 148 280 148C314 148 338 168 338 204V287C338 329 308 356 280 372C252 356 222 329 222 287V204Z"
                    fill="rgba(9,12,16,0.52)"
                    stroke="rgba(220,239,255,0.18)"
                    strokeWidth="1.2"
                ></path>
                <circle cx="251" cy="228" r="12" fill="rgba(220,239,255,0.72)"></circle>
                <circle cx="309" cy="228" r="12" fill="rgba(220,239,255,0.72)"></circle>
                <path
                    d="M240 282C255 300 265 308 280 308C295 308 305 300 320 282"
                    stroke="rgba(125,211,255,0.7)"
                    strokeWidth="8"
                    strokeLinecap="round"
                ></path>
                <path
                    d="M188 164C214 190 234 204 260 212"
                    stroke="rgba(125,211,255,0.34)"
                    strokeWidth="1.2"
                    strokeDasharray="6 10"
                ></path>
                <path
                    d="M372 164C346 190 326 204 300 212"
                    stroke="rgba(82,229,213,0.34)"
                    strokeWidth="1.2"
                    strokeDasharray="6 10"
                ></path>
                <path
                    d="M160 366C218 334 248 322 280 322C312 322 342 334 400 366"
                    stroke="rgba(220,239,255,0.12)"
                    strokeWidth="1.2"
                ></path>
            </svg>;
    }

    def FeatureGlyph(kind: str) -> JsxElement {
        if kind == "graph" {
            return
                <svg
                    viewBox="0 0 32 32"
                    width="28"
                    height="28"
                    fill="none"
                    aria-hidden="true"
                >
                    <circle
                        cx="8"
                        cy="8"
                        r="4"
                        stroke="rgba(220,239,255,0.84)"
                        strokeWidth="1.8"
                    ></circle>
                    <circle
                        cx="24"
                        cy="10"
                        r="3.2"
                        stroke="rgba(125,211,255,0.86)"
                        strokeWidth="1.8"
                    ></circle>
                    <circle
                        cx="19"
                        cy="24"
                        r="4"
                        stroke="rgba(82,229,213,0.86)"
                        strokeWidth="1.8"
                    ></circle>
                    <path
                        d="M11.6 9.6L20.6 10.2L18.4 20.4L11 11.4"
                        stroke="rgba(220,239,255,0.72)"
                        strokeWidth="1.6"
                    ></path>
                </svg>;
        }
        if kind == "walkers" {
            return
                <svg
                    viewBox="0 0 32 32"
                    width="28"
                    height="28"
                    fill="none"
                    aria-hidden="true"
                >
                    <path
                        d="M5 16H27"
                        stroke="rgba(220,239,255,0.82)"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                    ></path>
                    <path
                        d="M9 8L16 16L9 24"
                        stroke="rgba(125,211,255,0.86)"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    ></path>
                    <path
                        d="M23 8L16 16L23 24"
                        stroke="rgba(82,229,213,0.86)"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    ></path>
                </svg>;
        }
        return
            <svg
                viewBox="0 0 32 32"
                width="28"
                height="28"
                fill="none"
                aria-hidden="true"
            >
                <path
                    d="M16 4C12.4 6.1 10.2 6.7 8.2 6.7V14.8C8.2 20.1 11.7 24.7 16 27.2C20.3 24.7 23.8 20.1 23.8 14.8V6.7C21.8 6.7 19.6 6.1 16 4Z"
                    stroke="rgba(220,239,255,0.82)"
                    strokeWidth="1.8"
                ></path>
                <path
                    d="M12.5 16.3L15 18.9L20 13.9"
                    stroke="rgba(82,229,213,0.9)"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                ></path>
            </svg>;
    }

    def GraphPlaceholderAccent() -> JsxElement {
        return
            <svg
                className="gw-graph-constellation"
                viewBox="0 0 900 540"
                fill="none"
                aria-hidden="true"
            >
                <path
                    d="M56 134H164M56 134V242"
                    stroke="rgba(220,239,255,0.26)"
                    strokeWidth="1.4"
                ></path>
                <path
                    d="M736 132H844M844 132V240"
                    stroke="rgba(220,239,255,0.26)"
                    strokeWidth="1.4"
                ></path>
                <path
                    d="M56 404H164M56 404V296"
                    stroke="rgba(220,239,255,0.26)"
                    strokeWidth="1.4"
                ></path>
                <path
                    d="M736 404H844M844 404V296"
                    stroke="rgba(220,239,255,0.26)"
                    strokeWidth="1.4"
                ></path>
                <circle cx="164" cy="134" r="4" fill="rgba(125,211,255,0.74)"></circle>
                <circle cx="736" cy="132" r="4" fill="rgba(82,229,213,0.74)"></circle>
                <circle cx="164" cy="404" r="4" fill="rgba(82,229,213,0.74)"></circle>
                <circle cx="736" cy="404" r="4" fill="rgba(125,211,255,0.74)"></circle>
            </svg>;
    }

    def MetricChip(metric: dict[str, str]) -> JsxElement {
        return
            <div
                className={"gw-metric-chip gw-glass-panel gw-fade-up " + metric[
                    "delay"
                ]}
            >
                <div className="gw-metric-value">
                    {metric["value"]}
                </div>
                <div className="gw-metric-label">
                    {metric["label"]}
                </div>
                <div className="gw-metric-detail">
                    {metric["detail"]}
                </div>
            </div>;
    }

    def FeatureCard(feature: dict[str, str]) -> JsxElement {
        return
            <article
                className={"gw-feature-card gw-glass-panel gw-fade-up " + feature[
                    "delay"
                ]}
            >
                <div className="gw-feature-icon">
                    <FeatureGlyph kind={feature["kind"]}/>
                </div>
                <h3 className="gw-feature-title">
                    {feature["title"]}
                </h3>
                <p className="gw-feature-body">
                    {feature["body"]}
                </p>
            </article>;
    }

    def FlowCard(step: dict[str, str]) -> JsxElement {
        return
            <article
                className={"gw-flow-card gw-glass-panel gw-fade-up " + step["delay"]}
            >
                <div className="gw-flow-step">
                    Step{step["step"]}
                </div>
                <div className="gw-flow-name">
                    {step["title"]}
                </div>
                <div className="gw-flow-copy">
                    {step["body"]}
                </div>
                <div className="gw-flow-pulse"></div>
            </article>;
    }

    def SidebarNavButton(
        item: dict[str, str], activeSection: str, onPick: object
    ) -> JsxElement {
        buttonClass = (
            "gw-sidebar-item is-active"
                if activeSection == item["label"]
                else "gw-sidebar-item"
        );

        def handleClick() -> None {
            onPick(item["label"]);
        }

        return
            <button
                type="button"
                className={buttonClass}
                onClick={handleClick}
            >
                <span className="gw-sidebar-icon">
                    {item["icon"]}
                </span>
                <span className="gw-sidebar-copy">
                    <strong>
                        {item["label"]}
                    </strong>
                    <span>
                        {item["meta"]}
                    </span>
                </span>
            </button>;
    }

    def IncidentFeedButton(incident: dict[str, str], onPick: object) -> JsxElement {
        def handleClick() -> None {
            onPick(incident["title"]);
        }

        return
            <button
                type="button"
                className="gw-feed-row"
                onClick={handleClick}
            >
                <span className="gw-feed-time">
                    {incident["time"]}
                </span>
                <span className={severityClass(incident["severity"])}>
                    {incident["severity"]}
                </span>
                <span className="gw-feed-copy">
                    <strong>
                        {incident["title"]}
                    </strong>
                    <span>
                        {incident["detail"]}
                    </span>
                </span>
                <span className="gw-feed-hint">
                    {incident["hint"]}
                </span>
            </button>;
    }

    def WalkerStatusItem(status_item: dict[str, str]) -> JsxElement {
        return
            <div className="gw-right-item">
                <div>
                    <strong>
                        {status_item["name"]}
                    </strong>
                </div>
                <span className={walkerStateClass(status_item["state"])}>
                    {status_item["state"]}
                </span>
            </div>;
    }

    def AttentionItem(item: dict[str, str]) -> JsxElement {
        return
            <div className="gw-right-item">
                <div>
                    <strong>
                        {item["title"]}
                    </strong>
                </div>
                <span>
                    {item["value"]}
                </span>
            </div>;
    }

    def SessionNoteCard(note: str) -> JsxElement {
        return
            <div className="gw-session-note">
                {note}
            </div>;
    }

    def SummaryCard(card: dict[str, str]) -> JsxElement {
        return
            <article className={toneClass(card["tone"])}>
                <div className="gw-summary-label">
                    {card["label"]}
                </div>
                <div className="gw-summary-value">
                    {card["value"]}
                </div>
                <div className="gw-summary-delta">
                    {card["delta"]}
                </div>
                <svg
                    className="gw-summary-spark"
                    viewBox="0 0 280 48"
                    fill="none"
                    aria-hidden="true"
                >
                    <polyline
                        points={card["spark"]}
                        stroke="rgba(220,239,255,0.82)"
                        strokeWidth="2.4"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    ></polyline>
                </svg>
            </article>;
    }

    def PreviewShellStrip() -> JsxElement {
        return
            <div className="gw-preview-shell gw-glass-panel gw-fade-up gw-stagger-3">
                <div className="gw-preview-topbar">
                    <div className="gw-preview-topbar-left">
                        <div className="gw-preview-pill gw-preview-pill-wide"></div>
                        <div className="gw-preview-pill gw-preview-pill-small"></div>
                    </div>
                    <div className="gw-preview-topbar-right">
                        <div className="gw-preview-dot"></div>
                        <div className="gw-preview-dot"></div>
                    </div>
                </div>
                <div className="gw-preview-body">
                    <div className="gw-preview-sidebar gw-glass-panel">
                        <div
                            className="gw-preview-sidebar-line"
                            style={{"width": "80%"}}
                        ></div>
                        <div
                            className="gw-preview-sidebar-line"
                            style={{"width": "92%"}}
                        ></div>
                        <div
                            className="gw-preview-sidebar-line"
                            style={{"width": "86%"}}
                        ></div>
                        <div
                            className="gw-preview-sidebar-line"
                            style={{"width": "68%"}}
                        ></div>
                        <div
                            className="gw-preview-sidebar-line"
                            style={{"width": "74%"}}
                        ></div>
                    </div>
                    <div className="gw-preview-content">
                        <div className="gw-preview-summary">
                            <div className="gw-preview-card gw-glass-panel">
                                <div className="gw-preview-card-label">
                                    PR Review
                                </div>
                                <div className="gw-preview-card-value">
                                    12
                                </div>
                            </div>
                            <div className="gw-preview-card gw-glass-panel">
                                <div className="gw-preview-card-label">
                                    Drift Alerts
                                </div>
                                <div className="gw-preview-card-value">
                                    07
                                </div>
                            </div>
                            <div className="gw-preview-card gw-glass-panel">
                                <div className="gw-preview-card-label">
                                    Verdict Pace
                                </div>
                                <div className="gw-preview-card-value">
                                    94%
                                </div>
                            </div>
                        </div>
                        <div className="gw-preview-graph gw-glass-panel">
                            Graph canvas reserved for live traversal playback
                        </div>
                    </div>
                </div>
            </div>;
    }

    def LandingPage() -> JsxElement {
        return
            <div className="gw-page">
                <AmbientBackground screen="landing"/>
                <div className="gw-page-inner gw-page-inner--landing">
                    <header
                        className="gw-shell-nav gw-glass-panel gw-fade-up gw-stagger-1"
                    >
                        <GhostWatchWordmark/>
                        <nav className="gw-header-links">
                            <a href="#product" className="gw-nav-link">
                                Product
                            </a>
                            <a href="#capabilities" className="gw-nav-link">
                                Capabilities
                            </a>
                            <a href="#flow" className="gw-nav-link">
                                Flow
                            </a>
                            <a href="#demo" className="gw-nav-link">
                                Demo
                            </a>
                        </nav>
                        <Link to="/start" className="gw-glass-button gw-button-primary">
                            Getting started
                        </Link>
                    </header>
                    <main className="gw-landing-main">
                        <section className="gw-hero" id="product">
                            <div className="gw-hero-copy">
                                <div className="gw-kicker gw-fade-up gw-stagger-2">
                                    Midnight observatory for code guardians
                                </div>
                                <h1 className="gw-hero-title gw-fade-up gw-stagger-3">
                                    Autonomous code defense, rendered in graph-native clarity.
                                </h1>
                                <p className="gw-hero-text gw-fade-up gw-stagger-4">
                                    GhostWatch reviews pull requests, monitors dependency movement, and surfaces risk through a premium control room that already feels alive before the live graph ever attaches.
                                </p>
                                <div className="gw-chip-row">
                                    {[<MetricChip key={metric["value"]} metric={metric}/> for metric in LANDING_METRICS]}
                                </div>
                                <div className="gw-hero-actions gw-fade-up gw-stagger-6">
                                    <Link
                                        to="/start"
                                        className="gw-glass-button gw-button-primary"
                                    >
                                        Getting started
                                    </Link>
                                    <a
                                        href="#capabilities"
                                        className="gw-glass-button gw-button-secondary"
                                    >
                                        Explore product
                                    </a>
                                </div>
                                <div
                                    className="gw-system-strip gw-glass-panel gw-fade-up gw-stagger-7"
                                >
                                    <span>
                                        PR Review
                                    </span>
                                    <span>
                                        Supply Chain
                                    </span>
                                    <span>
                                        Blast Radius
                                    </span>
                                    <span>
                                        Maintainer Control
                                    </span>
                                </div>
                            </div>
                            <div className="gw-hero-visual">
                                <GhostShieldGraphic/>
                                <div
                                    className="gw-hero-alert-card gw-glass-panel gw-fade-up gw-stagger-5"
                                >
                                    <div className="gw-hero-alert-label">
                                        Risk Event
                                    </div>
                                    <div className="gw-hero-alert-title">
                                        Suspicious manifest delta
                                    </div>
                                    <div className="gw-hero-alert-copy">
                                        A runtime dependency arrived without a matching import path and is waiting for maintainer review.
                                    </div>
                                </div>
                                <div
                                    className="gw-hero-telemetry gw-telemetry-top gw-glass-panel gw-float-medium gw-fade-up gw-stagger-6"
                                >
                                    <div className="gw-telemetry-label">
                                        Verdict latency
                                    </div>
                                    <div className="gw-telemetry-value">
                                        11.8s
                                    </div>
                                    <div className="gw-telemetry-copy">
                                        Median decision timing across the demo queue.
                                    </div>
                                </div>
                                <div
                                    className="gw-hero-telemetry gw-telemetry-middle gw-glass-panel gw-float-delay gw-fade-up gw-stagger-4"
                                >
                                    <div className="gw-telemetry-label">
                                        Blast scan
                                    </div>
                                    <div className="gw-telemetry-value">
                                        26 nodes
                                    </div>
                                    <div className="gw-telemetry-copy">
                                        Downstream impact projected from the current branch touch points.
                                    </div>
                                </div>
                                <div
                                    className="gw-hero-telemetry gw-telemetry-bottom gw-glass-panel gw-float-slow gw-fade-up gw-stagger-7"
                                >
                                    <div className="gw-telemetry-label">
                                        Maintainer state
                                    </div>
                                    <div className="gw-telemetry-value">
                                        Watching
                                    </div>
                                    <div className="gw-telemetry-copy">
                                        Human approval remains visible and in control.
                                    </div>
                                </div>
                            </div>
                        </section>
                        <section className="gw-section" id="capabilities">
                            <div className="gw-section-head">
                                <div className="gw-kicker gw-fade-up gw-stagger-1">
                                    Why it feels different
                                </div>
                                <h2 className="gw-section-title gw-fade-up gw-stagger-2">
                                    Premium calm instead of dashboard sameness.
                                </h2>
                                <p className="gw-section-copy gw-fade-up gw-stagger-3">
                                    GhostWatch leans into liquid glass depth, high-trust typography, and structured motion so the interface looks intentional before you even inspect the data layer.
                                </p>
                            </div>
                            <div className="gw-feature-grid">
                                {[<FeatureCard key={feature["kind"]} feature={feature}/> for feature in LANDING_FEATURES]}
                            </div>
                        </section>
                        <section className="gw-section" id="flow">
                            <div className="gw-section-head">
                                <div className="gw-kicker gw-fade-up gw-stagger-1">
                                    How GhostWatch operates
                                </div>
                                <h2 className="gw-section-title gw-fade-up gw-stagger-2">
                                    Five deliberate beats, not one opaque black box.
                                </h2>
                                <p className="gw-section-copy gw-fade-up gw-stagger-3">
                                    The frontend should make each stage legible so maintainers can feel the review pipeline breathing instead of guessing what happened behind the screen.
                                </p>
                            </div>
                            <div className="gw-flow-grid">
                                {[<FlowCard key={step["step"]} step={step}/> for step in FLOW_STEPS]}
                            </div>
                        </section>
                        <section className="gw-section" id="demo">
                            <div className="gw-section-head">
                                <div className="gw-kicker gw-fade-up gw-stagger-1">
                                    Interface preview
                                </div>
                                <h2 className="gw-section-title gw-fade-up gw-stagger-2">
                                    A Jac frontend shell that already feels complete.
                                </h2>
                                <p className="gw-section-copy gw-fade-up gw-stagger-3">
                                    The graph stays intentionally blank for now, but the surrounding command surface should still read as a polished product instead of a placeholder.
                                </p>
                            </div>
                            <PreviewShellStrip/>
                        </section>
                        <section className="gw-section">
                            <div
                                className="gw-cta-panel gw-glass-panel gw-fade-up gw-stagger-2"
                            >
                                <div className="gw-cta-copy">
                                    <h3>
                                        Choose how you want to explore GhostWatch.
                                    </h3>
                                    <p>
                                        Contributors see gap-analysis style suggestions; lead maintainers open the incident control room. No sign-in in this demo—just pick a role and go.
                                    </p>
                                </div>
                                <div className="gw-cta-actions">
                                    <Link
                                        to="/start"
                                        className="gw-glass-button gw-button-primary"
                                    >
                                        Getting started
                                    </Link>
                                </div>
                            </div>
                        </section>
                    </main>
                </div>
            </div>;
    }

    def RoleSelectPage() -> JsxElement {
        return
            <div className="gw-page">
                <AmbientBackground screen="landing"/>
                <div className="gw-page-inner gw-page-inner--landing">
                    <Link to="/" className="gw-role-back gw-fade-up gw-stagger-1">
                        Back to marketing site
                    </Link>
                    <div className="gw-role-panel">
                        <div className="gw-role-head">
                            <div className="gw-kicker gw-fade-up gw-stagger-1">
                                GhostWatch
                            </div>
                            <h1 className="gw-role-title gw-fade-up gw-stagger-2">
                                How will you use GhostWatch?
                            </h1>
                            <p className="gw-role-sub gw-fade-up gw-stagger-3">
                                Pick the workspace that matches your responsibilities. This demo keeps both paths local until real accounts and repo scopes are wired in.
                            </p>
                        </div>
                        <div className="gw-role-grid">
                            <Link
                                to="/app/contributor"
                                className="gw-role-card gw-glass-panel gw-fade-up gw-stagger-4"
                            >
                                <div className="gw-role-card-kicker">
                                    I ship changes
                                </div>
                                <h2 className="gw-role-card-title">
                                    Contributor
                                </h2>
                                <p className="gw-role-card-body">
                                    See ranked gap suggestions after merges—tests, docs, and small implementation prompts—without the maintainer incident desk.
                                </p>
                            </Link>
                            <Link
                                to="/app/maintainer"
                                className="gw-role-card gw-glass-panel gw-fade-up gw-stagger-5"
                            >
                                <div className="gw-role-card-kicker">
                                    I own review & merge
                                </div>
                                <h2 className="gw-role-card-title">
                                    Lead maintainer
                                </h2>
                                <p className="gw-role-card-body">
                                    Open the control room for dependency incidents, walker status, escalation feeds, and the surfaces aligned with autonomous defense.
                                </p>
                            </Link>
                        </div>
                    </div>
                </div>
            </div>;
    }

    def AppPage(mode: str) -> JsxElement {
        isContributor = mode == "contributor";
        has activeSection: str = "Overview",
            commandNote: str = (
                "Gap-analysis suggestions are mocked locally until live graph and GapAnalysisWalker output are connected."
                    if isContributor
                    else "Demo telemetry synchronized. The graph canvas remains intentionally reserved for the next build."
            ),
            selectedEvent: str = (
                "Document public walker exports"
                    if isContributor
                    else "Suspicious manifest delta"
            );

        sidebarItems = CONTRIBUTOR_SIDEBAR_ITEMS if isContributor else SIDEBAR_ITEMS;
        summaryCards = CONTRIBUTOR_SUMMARY_CARDS if isContributor else SUMMARY_CARDS;
        feedItems = CONTRIBUTOR_SUGGESTIONS if isContributor else INCIDENTS;
        walkerItems = CONTRIBUTOR_WALKER_STATUS if isContributor else WALKER_STATUS;
        attentionItems = CONTRIBUTOR_ATTENTION_ITEMS if isContributor else ATTENTION_ITEMS;
        sessionNotesList = CONTRIBUTOR_SESSION_NOTES if isContributor else SESSION_NOTES;

        def setSection(label: str) -> None {
            activeSection = label;
            place = "workspace" if isContributor else "command surface";
            commandNote = label + " is now centered in your " + place + ".";
        }

        def runAnalysis() -> None {
            commandNote = (
                "Refreshing suggestion rankings for " + activeSection + " (demo)."
                    if isContributor
                    else "Mock analysis queued across the highest-risk paths for " + activeSection + "."
            );
        }

        def focusIncident(title: str) -> None {
            selectedEvent = title;
            commandNote = (
                "Focused suggestion: " + title + "."
                    if isContributor
                    else "Focused incident: " + title + "."
            );
        }

        panelTitle = (
            "Contributor workspace"
                if activeSection == "Overview" and isContributor
                else "Repository Command Surface"
                    if activeSection == "Overview"
                    else activeSection
        );

        topDescription = (
            "Gap-focused overview from post-merge analysis—lightweight cues for contributors rather than the maintainer defense desk."
                if isContributor
                else "Dark liquid-glass overview of the active demo telemetry around review flow, dependency alerts, and maintainer attention."
        );

        searchPlaceholder = (
            "Search suggestions, docs, or file paths"
                if isContributor
                else "Search alerts, walkers, or file paths"
        );

        feedTitle = "Suggestion feed" if isContributor else "Threat Feed";
        feedSubtitle = (
            "Placeholder picks mirror future GapAnalysisWalker output: a short ranked list instead of maintainer escalations."
                if isContributor
                else "Recent placeholder incidents keep the shell realistic while live walker output is still being wired in."
        );
        feedPill = "Gap picks" if isContributor else "Live feed reserved";

        graphKicker = "Contributor map" if isContributor else "Placeholder";
        graphTitle = (
            "Contribution graph reserved"
                if isContributor
                else "Graph Canvas Reserved"
        );
        graphBody = (
            "When live, this panel would tie suggestions to repo topology. The canvas stays blank so we do not fake a graph."
                if isContributor
                else "Live topology playback will attach here in the next build. The shell deliberately keeps this area blank rather than pretending a graph already exists."
        );
        graphFoot = (
            "Reserved for linking gap suggestions to nodes you touched in recent merges."
                if isContributor
                else "Reserved for live graph traversal, walker movement, and affected-node emphasis."
        );

        walkerRailTitle = "Walker & gap signals" if isContributor else "Walker Status";
        walkerRailCopy = (
            "Gap analysis and doc-linking walkers would surface here instead of the full incident stack."
                if isContributor
                else "Distinct specialist states stay visible instead of collapsing into one undifferentiated agent badge."
        );

        attentionTitle = "Your queue" if isContributor else "Attention Needed";
        attentionCopy = (
            "Contributor-sized tasks distilled from analysis—claimable slices, not org-wide escalations."
                if isContributor
                else "High-signal tasks stay short, legible, and ready for a future live handoff."
        );

        commandBannerLabel = "Workspace note" if isContributor else "Demo command note";
        focusPillPrefix = "Focused item: " if isContributor else "Focused incident: ";

        profileStrong = "Contributor view" if isContributor else "Repository Watch";
        profileSpan = (
            "Gap analysis preview"
                if isContributor
                else "Maintainer preview shell"
        );
        analysisButtonLabel = "Refresh suggestions" if isContributor else "Run Analysis";

        return
            <div className="gw-page">
                <AmbientBackground screen="app"/>
                <div className="gw-page-inner gw-page-inner--app">
                    <div className="gw-app-shell">
                        <aside
                            className="gw-sidebar gw-glass-panel gw-fade-up gw-stagger-1"
                        >
                            <Link to="/">
                                <GhostWatchWordmark/>
                            </Link>
                            <div className="gw-sidebar-nav">
                                {[
                                    <SidebarNavButton key={item["icon"]} item={item} activeSection={activeSection} onPick={setSection}/>
                                    for item in sidebarItems
                                ]}
                            </div>
                            <div className="gw-sidebar-footer">
                                <div className="gw-demo-badge">
                                    Demo Mode
                                </div>
                                <Link
                                    to="/start"
                                    className="gw-role-back"
                                    style={{"marginBottom": "12px"}}
                                >
                                    Switch role
                                </Link>
                                <div className="gw-profile-card">
                                    <div className="gw-avatar">
                                        GW
                                    </div>
                                    <div className="gw-profile-meta">
                                        <strong>
                                            {profileStrong}
                                        </strong>
                                        <span>
                                            {profileSpan}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </aside>
                        <div className="gw-workspace">
                            <header
                                className="gw-topbar gw-glass-panel gw-fade-up gw-stagger-2"
                            >
                                <div className="gw-topbar-heading">
                                    <h1>
                                        {panelTitle}
                                    </h1>
                                    <p>
                                        {topDescription}
                                    </p>
                                </div>
                                <div className="gw-topbar-actions">
                                    <button type="button" className="gw-repo-select">
                                        <svg
                                            width="18"
                                            height="18"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            aria-hidden="true"
                                        >
                                            <path
                                                d="M12 3L4 7V17L12 21L20 17V7L12 3Z"
                                                stroke="rgba(220,239,255,0.82)"
                                                strokeWidth="1.6"
                                            ></path>
                                            <path
                                                d="M4 7L12 11L20 7"
                                                stroke="rgba(125,211,255,0.82)"
                                                strokeWidth="1.6"
                                            ></path>
                                        </svg>
                                        <span className="gw-repo-label">
                                            <strong>
                                                jaseci-labs/jaseci
                                            </strong>
                                            <span>
                                                Demo repository selector
                                            </span>
                                        </span>
                                    </button>
                                    <div className="gw-search-shell">
                                        <svg
                                            width="18"
                                            height="18"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            aria-hidden="true"
                                        >
                                            <circle
                                                cx="11"
                                                cy="11"
                                                r="6.5"
                                                stroke="rgba(220,239,255,0.58)"
                                                strokeWidth="1.6"
                                            ></circle>
                                            <path
                                                d="M16 16L20 20"
                                                stroke="rgba(220,239,255,0.58)"
                                                strokeWidth="1.6"
                                                strokeLinecap="round"
                                            ></path>
                                        </svg>
                                        <input
                                            className="gw-search-input"
                                            placeholder={searchPlaceholder}
                                        />
                                    </div>
                                    <button
                                        type="button"
                                        className="gw-icon-button"
                                        aria-label="Notifications"
                                    >
                                        <svg
                                            width="18"
                                            height="18"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            aria-hidden="true"
                                        >
                                            <path
                                                d="M12 4.5C9.8 4.5 8 6.3 8 8.5V10.1C8 11 7.7 11.9 7.2 12.7L6 14.5H18L16.8 12.7C16.3 11.9 16 11 16 10.1V8.5C16 6.3 14.2 4.5 12 4.5Z"
                                                stroke="rgba(220,239,255,0.82)"
                                                strokeWidth="1.5"
                                                strokeLinejoin="round"
                                            ></path>
                                            <path
                                                d="M10.2 17.5C10.6 18.4 11.2 18.8 12 18.8C12.8 18.8 13.4 18.4 13.8 17.5"
                                                stroke="rgba(125,211,255,0.82)"
                                                strokeWidth="1.5"
                                                strokeLinecap="round"
                                            ></path>
                                        </svg>
                                        <span className="gw-icon-badge">
                                            3
                                        </span>
                                    </button>
                                    <button
                                        type="button"
                                        className="gw-glass-button gw-button-primary"
                                        onClick={runAnalysis}
                                    >
                                        {analysisButtonLabel}
                                    </button>
                                </div>
                            </header>
                            <section
                                className="gw-command-banner gw-glass-panel gw-fade-up gw-stagger-3"
                            >
                                <div>
                                    <strong>
                                        {commandBannerLabel}
                                    </strong>
                                    <p>
                                        {commandNote}
                                    </p>
                                </div>
                                <div className="gw-pill">
                                    {focusPillPrefix}{selectedEvent}
                                </div>
                            </section>
                            <div className="gw-main-grid">
                                <main className="gw-main-column">
                                    <section className="gw-summary-grid">
                                        {[<SummaryCard key={card["label"]} card={card}/> for card in summaryCards]}
                                    </section>
                                    <section
                                        className="gw-threat-panel gw-glass-panel gw-fade-up gw-stagger-4"
                                    >
                                        <div className="gw-panel-head">
                                            <div>
                                                <h2>
                                                    {feedTitle}
                                                </h2>
                                                <p>
                                                    {feedSubtitle}
                                                </p>
                                            </div>
                                            <div className="gw-pill">
                                                {feedPill}
                                            </div>
                                        </div>
                                        <div className="gw-feed-list">
                                            {[
                                                <IncidentFeedButton key={incident["title"]} incident={incident} onPick={focusIncident}/>
                                                for incident in feedItems
                                            ]}
                                        </div>
                                    </section>
                                    <section
                                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                                    >
                                        <div className="gw-graph-inner-frame"></div>
                                        <GraphPlaceholderAccent/>
                                        <div className="gw-graph-copy">
                                            <span>
                                                {graphKicker}
                                            </span>
                                            <h2>
                                                {graphTitle}
                                            </h2>
                                            <p>
                                                {graphBody}
                                            </p>
                                            <div className="gw-graph-foot">
                                                {graphFoot}
                                            </div>
                                        </div>
                                    </section>
                                </main>
                                <aside className="gw-right-rail">
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-3"
                                    >
                                        <h3>
                                            {walkerRailTitle}
                                        </h3>
                                        <p>
                                            {walkerRailCopy}
                                        </p>
                                        <div className="gw-right-list">
                                            {[
                                                <WalkerStatusItem key={status_item["name"]} status_item={status_item}/>
                                                for status_item in walkerItems
                                            ]}
                                        </div>
                                    </section>
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-4"
                                    >
                                        <h3>
                                            {attentionTitle}
                                        </h3>
                                        <p>
                                            {attentionCopy}
                                        </p>
                                        <div className="gw-right-list">
                                            {[
                                                <AttentionItem key={item["title"]} item={item}/>
                                                for item in attentionItems
                                            ]}
                                        </div>
                                    </section>
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-5"
                                    >
                                        <h3>
                                            Session Notes
                                        </h3>
                                        <p>
                                            This build is designed to feel complete now and easy to de-hardcode later.
                                        </p>
                                        <div className="gw-session-notes">
                                            {[
                                                <SessionNoteCard key={note} note={note}/>
                                                for note in sessionNotesList
                                            ]}
                                        </div>
                                    </section>
                                </aside>
                            </div>
                        </div>
                    </div>
                </div>
            </div>;
    }

    def:pub app -> JsxElement {
        return
            <Router>
                <div className="gw-root">
                    <style>
                        {APP_STYLES}
                    </style>
                    <Routes>
                        <Route path="/" element={<LandingPage/>}></Route>
                        <Route
                            path="/auth"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route path="/start" element={<RoleSelectPage/>}></Route>
                        <Route
                            path="/app/maintainer"
                            element={<AppPage mode="maintainer"/>}
                        ></Route>
                        <Route
                            path="/app/contributor"
                            element={<AppPage mode="contributor"/>}
                        ></Route>
                        <Route
                            path="/app"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route path="*" element={<Navigate to="/"/>}></Route>
                    </Routes>
                </div>
            </Router>;
    }
}
