# objects/verdict.jac — Shared verdict types for System 1 and System 2.

obj ContributorSuggestion {
    has title: str;
    has description: str;
    has difficulty: str;
    has file_path: str;
    has suggestion_type: str;
}

obj VerdictObject {
    has overall_risk: str;
    has risk_score: int;
    has affected_node_count: int;
    has blast_radius_summary: str;
    has recommendation: str;
    has security_findings: list = [];
    has compatibility_issues: list = [];
    has traversal_paths: dict = {};
}
