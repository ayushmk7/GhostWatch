cl import from "@jac/runtime" { Link }
cl import from .AmbientBackground { AmbientBackground }
cl import from .GhostWatchWordmark { GhostWatchWordmark }
cl import from .SidebarNavButton { SidebarNavButton }
cl import from .SummaryCard { SummaryCard }
cl import from .GraphPlaceholderAccent { GraphPlaceholderAccent }
cl import from .WalkerStatusItem { WalkerStatusItem }
cl import from .AttentionItem { AttentionItem }
cl import from .GraphView { GraphView }
cl import from ..mock_data {
    SIDEBAR_ITEMS,
    SUMMARY_CARDS,
    INCIDENTS,
    WALKER_STATUS,
    ATTENTION_ITEMS,
    CONTRIBUTOR_SIDEBAR_ITEMS,
    CONTRIBUTOR_SUMMARY_CARDS,
    CONTRIBUTOR_WALKER_STATUS,
    CONTRIBUTOR_ATTENTION_ITEMS,
    CONTRIBUTOR_GITHUB_ISSUES,
    CONTRIBUTOR_AI_ISSUES,
    CONTRIBUTOR_DOCS_ROWS,
    CONTRIBUTOR_TEST_ROWS,
    CONTRIBUTOR_ACTIVITY_ROWS,
    CONTRIBUTOR_SAVED_REPOS,
    MAINTAINER_PR_REVIEW_ROWS,
    MAINTAINER_DEPENDENCY_ROWS,
    MAINTAINER_WATCHED_REPOS,
    DEMO_PR_URL,
    DEMO_REPO_URL
}

def doFetch(url: str, opts: dict) -> Any {
    return fetch(url, opts);
}

def parse_repo_slug(raw: str) -> str {
    t = raw.strip();
    t = t.replace("https://github.com/", "");
    t = t.replace("http://github.com/", "");
    t = t.replace("github.com/", "");
    t = t.strip().strip("/");
    return t if t else "unknown/repo";
}

def:pub AppShell(mode: str) -> JsxElement {
    isContributor = mode == "contributor";
    has activeSection: str = "Overview",
        repoInput: str = "",
        repoLinked: bool = False,
        repoDisplay: str = "",
        graphState: dict | None = None,
        analysisLoading: bool = False,
        analysisResult: dict | None = None,
        animatingPath: list = [];

    async def fetchGraphState() -> None {
        res: Any = await doFetch(
            "/walker/GraphStateProxy",
            {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": "{}"}
        );
        data: Any = await res.json(); # jac:ignore[E1032]
        reports: Any = data.get("reports", []); # jac:ignore[E1032]
        if len(reports) > 0 { # jac:ignore[E1053]
            graphState = reports[0]; # jac:ignore[E1001]
        }
    }

    async def runAnalysis() -> None {
        analysisLoading = True;
        analysisResult = None;
        animatingPath = [];

        body_str: str = f'{{"pr_url": "{DEMO_PR_URL}"}}';
        res: Any = await doFetch(
            "/walker/OrchestratorProxy",
            {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": body_str
            }
        );
        data: Any = await res.json(); # jac:ignore[E1032]
        reports: Any = data.get("reports", []); # jac:ignore[E1032]

        if len(reports) > 0 { # jac:ignore[E1053]
            result: Any = reports[0]; # jac:ignore[E1001]
            analysisResult = result; # jac:ignore[E1001]
            paths: Any = result.get("traversal_paths", {}); # jac:ignore[E1032]
            blast_path: Any = paths.get("blast_radius", []); # jac:ignore[E1032]
            animatingPath = blast_path; # jac:ignore[E1001]
        }

        analysisLoading = False;
        await fetchGraphState();
    }

    async can with entry {
        await fetchGraphState();
    }

    sidebarItems = CONTRIBUTOR_SIDEBAR_ITEMS if isContributor else SIDEBAR_ITEMS;

    live_nodes: list = graphState["nodes"] if graphState else [];
    high_risk_count: int = len([n for n in live_nodes if int(n.get("risk_score", 0)) >= 14]);
    has_graph_live: bool = graphState["has_graph"] if graphState else False;
    latest_pr_live: dict | None = graphState["latest_analysis"] if graphState else None;

    live_summary_cards: list = [
        {
            "label": "Files scanned",
            "value": str(len(live_nodes)) if graphState else "—",
            "delta": "in graph",
            "tone": "frost",
            "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
        },
        {
            "label": "High-risk files",
            "value": str(high_risk_count) if graphState else "—",
            "delta": "above threshold",
            "tone": "cyan",
            "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
        },
        {
            "label": "Latest PR risk",
            "value": (
                latest_pr_live["verdict"].get("overall_risk", "?")
                if latest_pr_live else "None yet"
            ),
            "delta": "analyzed",
            "tone": "aqua",
            "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
        },
        {
            "label": "Graph status",
            "value": "Ready" if has_graph_live else "Building...",
            "delta": "system 1",
            "tone": "amber",
            "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
        }
    ];

    summaryCards = CONTRIBUTOR_SUMMARY_CARDS if isContributor else live_summary_cards;

    walker_state_str: str = "Running" if analysisLoading else ("Active" if has_graph_live else "Idle");
    live_walker_status: list = [
        {"name": "SecurityAuditorWalker", "state": walker_state_str},
        {"name": "CompatibilityCheckerWalker", "state": walker_state_str},
        {"name": "BlastRadiusMapperWalker", "state": walker_state_str}
    ];
    walkerItems = CONTRIBUTOR_WALKER_STATUS if isContributor else live_walker_status;

    latest_incident_live: dict | None = graphState["latest_incident"] if graphState else None;
    live_attention_items: list = [
        {
            "title": "Files in graph",
            "value": f"{len(live_nodes)} nodes"
        },
        {
            "title": "High-risk files",
            "value": f"{high_risk_count} detected"
        },
        {
            "title": "Latest incident",
            "value": latest_incident_live["status"] if latest_incident_live else "None"
        }
    ];
    attentionItems = CONTRIBUTOR_ATTENTION_ITEMS if isContributor else live_attention_items;

    def setSection(label: str) -> None {
        activeSection = label;
    }

    def linkRepository() -> None {
        if repoInput.strip() == "" {
            return;
        }
        repoDisplay = parse_repo_slug(repoInput);
        repoLinked = True;
    }

    panelTitle = "Connect a GitHub repository";
    topDescription = (
        "Paste a repository URL to scope this workspace. Overview and every tab stay limited to that project."
    );
    searchPlaceholder = "Available after you connect a repo";
    analysisButtonLabel = "Connect";

    if repoLinked {
        analysisButtonLabel = "Run Analysis";
        if isContributor {
            if activeSection == "Overview" {
                panelTitle = "Overview · " + repoDisplay;
                topDescription = (
                    "Open work, documentation pressure, and movement for "
                        + repoDisplay
                        + " only — not your whole GitHub account."
                );
                searchPlaceholder = "Search paths and symbols in " + repoDisplay;
                analysisButtonLabel = "Refresh overview";
            } else {
                if activeSection == "Suggestions" {
                    panelTitle = "Suggestions · " + repoDisplay;
                    topDescription = (
                        "GitHub issues from the repository alongside AI-ranked starter tasks for the same codebase."
                    );
                    searchPlaceholder = "Filter tables (demo)";
                    analysisButtonLabel = "Refresh suggestions";
                } else {
                    if activeSection == "Docs & tests" {
                        panelTitle = "Docs & tests · " + repoDisplay;
                        topDescription = (
                            "Where documentation and automated tests look thin or stale inside "
                                + repoDisplay
                                + "."
                        );
                        searchPlaceholder = "Search doc or test paths";
                        analysisButtonLabel = "Rescan docs & tests";
                    } else {
                        if activeSection == "Activity" {
                            panelTitle = "Activity · " + repoDisplay;
                            topDescription = (
                                "Recent merges and pushes GhostWatch has seen on " + repoDisplay + "."
                            );
                            searchPlaceholder = "Search commit messages (demo)";
                            analysisButtonLabel = "Refresh activity";
                        } else {
                            panelTitle = "Settings";
                            topDescription = (
                                "Notification defaults and every repository you have added to your contributor workspace."
                            );
                            searchPlaceholder = "Search settings";
                            analysisButtonLabel = "Save changes";
                        }
                    }
                }
            }
        } else {
            if activeSection == "Overview" {
                panelTitle = "Overview · " + repoDisplay;
                topDescription = (
                    "Live posture for "
                        + repoDisplay
                        + ": pull requests under watch, walker signals, and maintainer-sized attention items."
                );
                searchPlaceholder = "Search alerts, walkers, or paths in " + repoDisplay;
                analysisButtonLabel = "Run Analysis";
            } else {
                if activeSection == "PR Review" {
                    panelTitle = "PR Review · " + repoDisplay;
                    topDescription = (
                        "Pull requests GhostWatch is tracking on "
                            + repoDisplay
                            + " with risk hints and gate status."
                    );
                    searchPlaceholder = "Search PR titles or authors";
                    analysisButtonLabel = "Refresh PR list";
                } else {
                    if activeSection == "Dependency Alerts" {
                        panelTitle = "Dependency Alerts · " + repoDisplay;
                        topDescription = (
                            "Manifest drift, version jumps, and supply-chain signals scoped to " + repoDisplay + "."
                        );
                        searchPlaceholder = "Search packages or CVEs";
                        analysisButtonLabel = "Rescan dependencies";
                    } else {
                        if activeSection == "Incidents" {
                            panelTitle = "Incidents · " + repoDisplay;
                            topDescription = (
                                "Escalations and findings for "
                                    + repoDisplay
                                    + " — the same feed the defense desk would own in production."
                            );
                            searchPlaceholder = "Search incident titles";
                            analysisButtonLabel = "Refresh incidents";
                        } else {
                            panelTitle = "Settings";
                            topDescription = (
                                "How the maintainer desk notifies you and which repositories stay on the watch list."
                            );
                            searchPlaceholder = "Search settings";
                            analysisButtonLabel = "Save changes";
                        }
                    }
                }
            }
        }
    }

    graphKicker = "Placeholder";
    graphTitle = "Graph Canvas Reserved";
    graphBody = (
        "Live topology playback will attach here in the next build. The shell deliberately keeps this area blank rather than pretending a graph already exists."
    );
    graphFoot = (
        "Reserved for live graph traversal, walker movement, and affected-node emphasis."
    );

    walkerRailTitle = "Walker Status";
    walkerRailCopy = (
        "Distinct specialist states stay visible instead of collapsing into one undifferentiated agent badge."
    );

    attentionTitle = "Attention Needed";
    attentionCopy = (
        "High-signal tasks stay short, legible, and ready for a future live handoff."
    );

    profileStrong = "Lead maintainer";
    profileSpan = "Defense desk preview";

    if isContributor {
        graphKicker = "Contributor map";
        graphTitle = "Contribution graph reserved";
        graphBody = (
            "When live, this panel would tie suggestions to repo topology. The canvas stays blank so we do not fake a graph."
        );
        graphFoot = (
            "Reserved for linking gap suggestions to nodes you touched in recent merges."
        );

        walkerRailTitle = "Walker & gap signals";
        walkerRailCopy = (
            "Gap analysis and doc-linking walkers would surface here instead of the full incident stack."
        );

        attentionTitle = "Your queue";
        attentionCopy = (
            "Contributor-sized tasks distilled from analysis: claimable slices, not org-wide escalations."
        );

        profileStrong = "Contributor view";
        profileSpan = "Gap analysis preview";
    }

    return
        <div className="gw-page">
            <AmbientBackground screen="app"/>
            <div className="gw-page-inner gw-page-inner--app">
                <div className="gw-app-shell">
                    <aside
                        className="gw-sidebar gw-glass-panel gw-fade-up gw-stagger-1"
                    >
                        <Link to="/" className="gw-wordmark-link">
                            <GhostWatchWordmark showSubtitle={False}/>
                        </Link>
                        <div className="gw-sidebar-nav">
                            {[
                                <SidebarNavButton key={item["label"]} item={item} activeSection={activeSection} onPick={setSection}/>
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
                    <div
                        className={
                            "gw-workspace"
                                + (" gw-workspace--connect" if not repoLinked else "")
                        }
                    >
                        {not repoLinked and
                            <div className="gw-repo-connect gw-glass-panel gw-fade-up gw-stagger-2">
                                <h2 className="gw-repo-connect-title">
                                    Link your repository
                                </h2>
                                <p className="gw-repo-connect-lede">
                                    Enter a GitHub URL (for example
                                    <code className="gw-repo-connect-code">
                                        {" "}https://github.com/org/project
                                    </code>
                                    ). The overview and every tab below stay scoped to that repository.
                                </p>
                                <div className="gw-repo-connect-row">
                                    <input
                                        className="gw-repo-connect-input"
                                        type="url"
                                        placeholder="https://github.com/owner/repo"
                                        value={repoInput}
                                        onChange={lambda e: ChangeEvent { repoInput = e.target.value; }}
                                    />
                                    <button
                                        type="button"
                                        className="gw-glass-button gw-button-primary"
                                        onClick={lambda -> None { linkRepository(); }}
                                    >
                                        Continue
                                    </button>
                                </div>
                            </div>}
                        {repoLinked and
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
                                                {repoDisplay}
                                            </strong>
                                            <span>
                                                Active repository
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
                                        onClick={lambda -> None { runAnalysis(); }}
                                        disabled={analysisLoading}
                                    >
                                        {analysisButtonLabel if not analysisLoading else "Analyzing..."}
                                    </button>
                                </div>
                            </header>}
                        {isContributor and repoLinked and activeSection == "Suggestions" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Open issues on this repository
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        #
                                                    </th>
                                                    <th>
                                                        Title
                                                    </th>
                                                    <th>
                                                        Labels
                                                    </th>
                                                    <th>
                                                        State
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["id"]}>
                                                        <td>
                                                            {row["id"]}
                                                        </td>
                                                        <td>
                                                            {row["title"]}
                                                        </td>
                                                        <td>
                                                            {row["labels"]}
                                                        </td>
                                                        <td>
                                                            {row["state"]}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_GITHUB_ISSUES
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Recommended by AI
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        ID
                                                    </th>
                                                    <th>
                                                        Suggested task
                                                    </th>
                                                    <th>
                                                        Why it matters
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["id"]}>
                                                        <td>
                                                            {row["id"]}
                                                        </td>
                                                        <td>
                                                            {row["title"]}
                                                        </td>
                                                        <td>
                                                            {row["reason"]}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_AI_ISSUES
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {isContributor and repoLinked and activeSection == "Docs & tests" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Documentation
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Path
                                                    </th>
                                                    <th>
                                                        Status
                                                    </th>
                                                    <th>
                                                        Note
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["path"]}>
                                                        <td>
                                                            {row["path"]}
                                                        </td>
                                                        <td>
                                                            {row["status"]}
                                                        </td>
                                                        <td>
                                                            {row["note"]}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_DOCS_ROWS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Tests
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Suite / area
                                                    </th>
                                                    <th>
                                                        Status
                                                    </th>
                                                    <th>
                                                        Note
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["suite"]}>
                                                        <td>
                                                            {row["suite"]}
                                                        </td>
                                                        <td>
                                                            {row["status"]}
                                                        </td>
                                                        <td>
                                                            {row["note"]}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_TEST_ROWS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {isContributor and repoLinked and activeSection == "Activity" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Recent activity
                                        </h2>
                                        <table className="gw-data-table gw-data-table--compact">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        When
                                                    </th>
                                                    <th>
                                                        Event
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["when"] + row["what"]}>
                                                        <td>
                                                            {row["when"]}
                                                        </td>
                                                        <td>
                                                            {row["what"]}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_ACTIVITY_ROWS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {isContributor and repoLinked and activeSection == "Settings" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column gw-settings-column">
                                    <section className="gw-settings-block gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Notifications
                                        </h2>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={True}/>
                                            <span>
                                                Email when a new AI suggestion batch is ready
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={True}/>
                                            <span>
                                                Slack digest for assigned issues
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={False}/>
                                            <span>
                                                Desktop alerts for failing checks on watched repos
                                            </span>
                                        </label>
                                    </section>
                                    <section className="gw-settings-block gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Analysis
                                        </h2>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Default gap run depth
                                            </span>
                                            <select className="gw-settings-select" defaultValue="standard">
                                                <option value="shallow">
                                                    Shallow
                                                </option>
                                                <option value="standard">
                                                    Standard
                                                </option>
                                                <option value="deep">
                                                    Deep (slower)
                                                </option>
                                            </select>
                                        </label>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Time zone for digests
                                            </span>
                                            <select className="gw-settings-select" defaultValue="utc">
                                                <option value="utc">
                                                    UTC
                                                </option>
                                                <option value="local">
                                                    Local browser
                                                </option>
                                            </select>
                                        </label>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Repositories you contribute to
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Repository
                                                    </th>
                                                    <th>
                                                        Role
                                                    </th>
                                                    <th>
                                                        Pinned in sidebar
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr
                                                        key={row["slug"]}
                                                        className={
                                                            (
                                                                "gw-repo-row-current"
                                                                    if row["slug"] == repoDisplay
                                                                    else ""
                                                            )
                                                        }
                                                    >
                                                        <td>
                                                            {row["slug"]}
                                                        </td>
                                                        <td>
                                                            {row["role"]}
                                                        </td>
                                                        <td>
                                                            {(
                                                                "Yes"
                                                                    if row["pinned"] == "true"
                                                                    else "No"
                                                            )}
                                                        </td>
                                                    </tr>
                                                    for row in CONTRIBUTOR_SAVED_REPOS
                                                ]}
                                            </tbody>
                                        </table>
                                        <p className="gw-settings-hint">
                                            The repo you linked (
                                            {repoDisplay}
                                            ) is highlighted when it matches a row above (demo list).
                                        </p>
                                    </section>
                                </main>
                            </div>}
                        {(not isContributor) and repoLinked and activeSection == "PR Review" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Pull requests under watch
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        PR
                                                    </th>
                                                    <th>
                                                        Title
                                                    </th>
                                                    <th>
                                                        Author
                                                    </th>
                                                    <th>
                                                        Risk
                                                    </th>
                                                    <th>
                                                        Status
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["pr"]}>
                                                        <td>
                                                            {row["pr"]}
                                                        </td>
                                                        <td>
                                                            {row["title"]}
                                                        </td>
                                                        <td>
                                                            {row["author"]}
                                                        </td>
                                                        <td>
                                                            {row["risk"]}
                                                        </td>
                                                        <td>
                                                            {row["status"]}
                                                        </td>
                                                    </tr>
                                                    for row in MAINTAINER_PR_REVIEW_ROWS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {(not isContributor) and repoLinked and activeSection == "Dependency Alerts" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Dependency & manifest signals
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Package / source
                                                    </th>
                                                    <th>
                                                        Change
                                                    </th>
                                                    <th>
                                                        Severity
                                                    </th>
                                                    <th>
                                                        Note
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["package"]}>
                                                        <td>
                                                            {row["package"]}
                                                        </td>
                                                        <td>
                                                            {row["change"]}
                                                        </td>
                                                        <td>
                                                            {row["severity"]}
                                                        </td>
                                                        <td>
                                                            {row["note"]}
                                                        </td>
                                                    </tr>
                                                    for row in MAINTAINER_DEPENDENCY_ROWS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {(not isContributor) and repoLinked and activeSection == "Incidents" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Escalation feed
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Time
                                                    </th>
                                                    <th>
                                                        Severity
                                                    </th>
                                                    <th>
                                                        Title
                                                    </th>
                                                    <th>
                                                        Detail
                                                    </th>
                                                    <th>
                                                        Next step
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={incident["title"]}>
                                                        <td>
                                                            {incident["time"]}
                                                        </td>
                                                        <td>
                                                            {incident["severity"]}
                                                        </td>
                                                        <td>
                                                            {incident["title"]}
                                                        </td>
                                                        <td>
                                                            {incident["detail"]}
                                                        </td>
                                                        <td>
                                                            {incident["hint"]}
                                                        </td>
                                                    </tr>
                                                    for incident in INCIDENTS
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}
                        {(not isContributor) and repoLinked and activeSection == "Settings" and
                            <div className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3">
                                <main className="gw-main-column gw-settings-column">
                                    <section className="gw-settings-block gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Notifications
                                        </h2>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={True}/>
                                            <span>
                                                Page me when a critical incident opens on a watched repo
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={True}/>
                                            <span>
                                                Slack #defense-desk for high+ dependency alerts
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input type="checkbox" defaultChecked={False}/>
                                            <span>
                                                Email digest of PRs blocked on maintainer approval
                                            </span>
                                        </label>
                                    </section>
                                    <section className="gw-settings-block gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Walker desk
                                        </h2>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Default blast-radius depth
                                            </span>
                                            <select className="gw-settings-select" defaultValue="standard">
                                                <option value="shallow">
                                                    Shallow
                                                </option>
                                                <option value="standard">
                                                    Standard
                                                </option>
                                                <option value="deep">
                                                    Deep (slower)
                                                </option>
                                            </select>
                                        </label>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Auto-escalate policy
                                            </span>
                                            <select className="gw-settings-select" defaultValue="manual">
                                                <option value="manual">
                                                    Manual approval only
                                                </option>
                                                <option value="trusted">
                                                    Auto for trusted authors
                                                </option>
                                            </select>
                                        </label>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Watched repositories
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>
                                                        Repository
                                                    </th>
                                                    <th>
                                                        Role
                                                    </th>
                                                    <th>
                                                        Default branch
                                                    </th>
                                                    <th>
                                                        Pinned
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr
                                                        key={row["slug"]}
                                                        className={
                                                            (
                                                                "gw-repo-row-current"
                                                                    if row["slug"] == repoDisplay
                                                                    else ""
                                                            )
                                                        }
                                                    >
                                                        <td>
                                                            {row["slug"]}
                                                        </td>
                                                        <td>
                                                            {row["role"]}
                                                        </td>
                                                        <td>
                                                            {row["branch"]}
                                                        </td>
                                                        <td>
                                                            {(
                                                                "Yes"
                                                                    if row["pinned"] == "true"
                                                                    else "No"
                                                            )}
                                                        </td>
                                                    </tr>
                                                    for row in MAINTAINER_WATCHED_REPOS
                                                ]}
                                            </tbody>
                                        </table>
                                        <p className="gw-settings-hint">
                                            The linked repo (
                                            {repoDisplay}
                                            ) is highlighted when it matches a row above (demo list).
                                        </p>
                                    </section>
                                </main>
                            </div>}
                        {isContributor and repoLinked and activeSection == "Overview" and
                            <div className="gw-main-grid gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-summary-grid">
                                        {[<SummaryCard key={card["label"]} card={card}/> for card in summaryCards]}
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
                                </aside>
                            </div>}
                        {(not isContributor) and repoLinked and activeSection == "Overview" and
                            <div className="gw-main-grid gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-summary-grid">
                                        {[<SummaryCard key={card["label"]} card={card}/> for card in summaryCards]}
                                    </section>
                                    {analysisResult and
                                        <section
                                            className="gw-glass-panel gw-fade-up"
                                            style={{
                                                "padding": "20px 24px",
                                                "marginBottom": "16px",
                                                "borderLeft": "3px solid " + (
                                                    "rgba(239,68,68,0.8)"
                                                    if analysisResult.get("overall_risk", "") in ["critical", "high"]
                                                    else "rgba(251,191,36,0.8)"
                                                    if analysisResult.get("overall_risk", "") == "medium"
                                                    else "rgba(125,211,255,0.6)"
                                                )
                                            }}
                                        >
                                            <div style={{"display": "flex", "alignItems": "center", "gap": "12px", "marginBottom": "10px"}}>
                                                <span style={{
                                                    "background": (
                                                        "rgba(239,68,68,0.25)"
                                                        if analysisResult.get("overall_risk", "") in ["critical", "high"]
                                                        else "rgba(251,191,36,0.25)"
                                                        if analysisResult.get("overall_risk", "") == "medium"
                                                        else "rgba(125,211,255,0.15)"
                                                    ),
                                                    "color": "rgba(220,239,255,0.9)",
                                                    "padding": "3px 10px",
                                                    "borderRadius": "20px",
                                                    "fontSize": "11px",
                                                    "fontWeight": "700",
                                                    "textTransform": "uppercase",
                                                    "letterSpacing": "0.05em"
                                                }}>
                                                    {analysisResult.get("overall_risk", "unknown")}
                                                </span>
                                                <span style={{"color": "rgba(220,239,255,0.5)", "fontSize": "12px"}}>
                                                    {str(len(analysisResult.get("security_findings", []))) + " security · " + str(len(analysisResult.get("compatibility_issues", []))) + " compat"}
                                                </span>
                                            </div>
                                            <p style={{"color": "rgba(220,239,255,0.82)", "fontSize": "13px", "marginBottom": "6px", "lineHeight": "1.5"}}>
                                                {analysisResult.get("blast_radius_summary", "")}
                                            </p>
                                            <p style={{"color": "rgba(125,211,255,0.82)", "fontSize": "12px", "fontStyle": "italic"}}>
                                                {analysisResult.get("recommendation", "")}
                                            </p>
                                        </section>}
                                    <section
                                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                                    >
                                        {(graphState and len(graphState["nodes"]) > 0) and
                                            <GraphView
                                                nodes_data={graphState["nodes"]}
                                                edges_data={graphState["edges"]}
                                                animatingPath={animatingPath}
                                                analysisLoading={analysisLoading}
                                            />}
                                        {(not graphState or len(graphState["nodes"]) == 0) and
                                            <div>
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
                                            </div>}
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
                                </aside>
                            </div>}
                    </div>
                </div>
            </div>
        </div>;
}
