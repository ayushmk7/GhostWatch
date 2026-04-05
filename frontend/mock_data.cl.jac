cl glob:pub DEMO_MODE: bool = True;

cl glob:pub LANDING_METRICS: list[dict[str, str]] = [
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
         {"icon": "OV", "label": "Overview", "meta": "Command surface"},
         {"icon": "PR", "label": "PR Review", "meta": "Touched paths"},
         {"icon": "DP", "label": "Dependency Alerts", "meta": "Manifest drift"},
         {"icon": "IN", "label": "Incidents", "meta": "Escalation feed"},
         {"icon": "ST", "label": "Settings", "meta": "Demo controls"}
     ];

cl glob:pub SUMMARY_CARDS: list[dict[str, str]] = [
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

cl glob:pub INCIDENTS: list[dict[str, str]] = [
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

cl glob:pub WALKER_STATUS: list[dict[str, str]] = [
         {"name": "Security Auditor", "state": "Active"},
         {"name": "Compatibility Checker", "state": "Queued"},
         {"name": "Blast Radius Mapper", "state": "Watching"}
     ];

cl glob:pub ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Maintainer approvals pending", "value": "2 pending"},
         {"title": "Dependency lockfile mismatch", "value": "1 unresolved"},
         {"title": "Comments ready to post", "value": "4 prepared"}
     ];

cl glob:pub SESSION_NOTES: list[str] = [
         "Demo mode is using local placeholder telemetry so the shell stays expressive before live walkers are connected.",
         "The graph canvas is intentionally reserved for future playback and remains visually framed instead of mocked.",
         "Every hardcoded value in this screen lives in centralized constants so backend walker responses can replace them later."
     ];

cl glob:pub CONTRIBUTOR_SIDEBAR_ITEMS: list[dict[str, str]] = [
         {"icon": "OV", "label": "Overview", "meta": "Your workspace"},
         {"icon": "SG", "label": "Suggestions", "meta": "Gap analysis picks"},
         {"icon": "DC", "label": "Docs & tests", "meta": "Coverage hints"},
         {"icon": "AC", "label": "Activity", "meta": "Recent merges"},
         {"icon": "ST", "label": "Settings", "meta": "Demo controls"}
     ];

cl glob:pub CONTRIBUTOR_SUMMARY_CARDS: list[dict[str, str]] = [
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

cl glob:pub CONTRIBUTOR_SUGGESTIONS: list[dict[str, str]] = [
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

cl glob:pub CONTRIBUTOR_WALKER_STATUS: list[dict[str, str]] = [
         {"name": "GapAnalysisWalker", "state": "Watching"},
         {"name": "Graph doc linker", "state": "Queued"},
         {"name": "Contributor ranker", "state": "Active"}
     ];

cl glob:pub CONTRIBUTOR_ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Suggestions ready to pick up", "value": "3 open"},
         {"title": "Docs requested for PR #184", "value": "1 thread"},
         {"title": "Merge follow-ups", "value": "2 notes"}
     ];

cl glob:pub CONTRIBUTOR_SESSION_NOTES: list[str] = [
         "Contributor view highlights gap-analysis output and documentation signals—placeholders until GapAnalysisWalker is live on your repo.",
         "Suggestions map to System 2 contributor picks: a small, ranked set rather than the full maintainer escalation feed.",
         "Switch to the lead maintainer home anytime via the marketing site path to compare control-room telemetry."
     ];
