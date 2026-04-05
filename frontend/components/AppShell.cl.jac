cl import from "@jac/runtime" { Link }
cl import from .AmbientBackground { AmbientBackground }
cl import from .GhostWatchWordmark { GhostWatchWordmark }
cl import from .SidebarNavButton { SidebarNavButton }
cl import from .SummaryCard { SummaryCard }
cl import from .IncidentFeedButton { IncidentFeedButton }
cl import from .GraphPlaceholderAccent { GraphPlaceholderAccent }
cl import from .WalkerStatusItem { WalkerStatusItem }
cl import from .AttentionItem { AttentionItem }
cl import from .SessionNoteCard { SessionNoteCard }
cl import from ..mock_data {
    SIDEBAR_ITEMS,
    SUMMARY_CARDS,
    INCIDENTS,
    WALKER_STATUS,
    ATTENTION_ITEMS,
    SESSION_NOTES,
    CONTRIBUTOR_SIDEBAR_ITEMS,
    CONTRIBUTOR_SUMMARY_CARDS,
    CONTRIBUTOR_SUGGESTIONS,
    CONTRIBUTOR_WALKER_STATUS,
    CONTRIBUTOR_ATTENTION_ITEMS,
    CONTRIBUTOR_SESSION_NOTES
}

def:pub AppShell(mode: str) -> JsxElement {
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
