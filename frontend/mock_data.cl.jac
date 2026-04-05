cl glob:pub LANDING_FEATURES: list[dict[str, str]] = [
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

cl glob:pub FLOW_STEPS: list[dict[str, str]] = [
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

cl glob:pub SIDEBAR_ITEMS: list[dict[str, str]] = [
    {"label": "Overview", "meta": "Defense desk snapshot"},
    {"label": "Issue radar", "meta": "Open issues + AI triage"},
    {"label": "PR Review", "meta": "PRs under watch"},
    {"label": "Dependency Alerts", "meta": "Manifest & supply chain"},
    {"label": "Incidents", "meta": "Escalation feed"},
    {"label": "Settings", "meta": "Desk & repositories"}
];

cl glob:pub SUMMARY_CARDS: list[dict[str, str]] = [
    {
        "label": "Open PRs (linked repo)",
        "value": "—",
        "delta": "—",
        "tone": "frost",
        "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
    },
    {
        "label": "Critical Findings",
        "value": "—",
        "delta": "—",
        "tone": "cyan",
        "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
    },
    {
        "label": "Dependency Drift",
        "value": "—",
        "delta": "—",
        "tone": "aqua",
        "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
    },
    {
        "label": "Review Throughput",
        "value": "—",
        "delta": "—",
        "tone": "amber",
        "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
    },
    {
        "label": "Open GitHub issues",
        "value": "—",
        "delta": "live from GraphStateWalker",
        "tone": "frost",
        "spark": "6,30 42,20 80,22 122,18 160,14 198,12 236,14 274,10"
    }
];

cl glob:pub CONTRIBUTOR_SIDEBAR_ITEMS: list[dict[str, str]] = [
    {"label": "Overview", "meta": "Repository snapshot"},
    {"label": "Suggestions", "meta": "Issues and AI picks"},
    {"label": "Docs & tests", "meta": "Coverage and gaps"},
    {"label": "Activity", "meta": "Recent merges"},
    {"label": "Settings", "meta": "Account and repos"}
];

# Demo repo is fixed to jaseci-labs/jaseci. Live issue lists need GITHUB_TOKEN; digest needs ANTHROPIC_API_KEY.

# Static briefing derived from the upstream README (Claude-preprocessed for the demo UI).
cl glob:pub CLAUDE_JASECI_CONTEXT_PARAS: list[str] = [
    (
        "The official Jaseci monorepo hosts the Jac stack: jaclang (Jac to Python bytecode, JavaScript, and native code), "
        "byllm for LLM integration, jac-client for full-stack apps with the npm/Vite ecosystem, jac-scale for deployment "
        "(FastAPI, Redis, MongoDB, Kubernetes), jac-super, and jac-mcp. The convenience bundle installs with pip install jaseci."
    ),
    (
        "Jac emphasizes AI-native Meaning Typed Programming, building backend and frontend in one language, graph-native domain "
        "modeling with walkers, and cloud-style serving via jac start (with optional scaling flags). Documentation, tutorials, "
        "and contribution guidelines live in the same repository."
    ),
    (
        "GhostWatch scopes this demo to jaseci-labs/jaseci; GraphStateWalker streams open issues (capped at 100) and a TTL-cached Anthropic digest for maintainer triage."
    )
];

cl glob:pub CONTRIBUTOR_SUMMARY_CARDS: list[dict[str, str]] = [
    {
        "label": "Open issues (linked repo)",
        "value": "—",
        "delta": "from latest gap run",
        "tone": "frost",
        "spark": "6,32 42,22 80,18 122,24 160,12 198,16 236,14 274,10"
    },
    {
        "label": "Untested paths",
        "value": "—",
        "delta": "—",
        "tone": "cyan",
        "spark": "6,30 42,28 80,20 122,26 160,16 198,14 236,12 274,11"
    },
    {
        "label": "Docs gaps",
        "value": "—",
        "delta": "—",
        "tone": "aqua",
        "spark": "6,26 42,22 80,24 122,18 160,20 198,11 236,14 274,9"
    },
    {
        "label": "Merge velocity",
        "value": "—",
        "delta": "—",
        "tone": "amber",
        "spark": "6,34 42,24 80,22 122,18 160,20 198,13 236,10 274,12"
    }
];
