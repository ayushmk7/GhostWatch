cl import from "@jac/runtime" { Link }
cl import from ..mock_data { LANDING_METRICS, LANDING_FEATURES, FLOW_STEPS }
cl import from ..components.AmbientBackground { AmbientBackground }
cl import from ..components.GhostWatchWordmark { GhostWatchWordmark }
cl import from ..components.GhostShieldGraphic { GhostShieldGraphic }
cl import from ..components.MetricChip { MetricChip }
cl import from ..components.FeatureCard { FeatureCard }
cl import from ..components.FlowCard { FlowCard }
cl import from ..components.PreviewShellStrip { PreviewShellStrip }

cl {
    def:pub IndexPage() -> JsxElement {
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
}
