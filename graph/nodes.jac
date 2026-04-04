# graph/nodes.jac — Pure node declarations. No logic, no imports.

node FileNode {
    has path: str;
    has content: str;
    has language: str;
    has risk_score: int = 0;
    has is_test: bool = False;
}

node FindingNode {
    has walker_type: str;
    has severity: str;
    has description: str;
    has evidence: str;
    has line_number: int = 0;
}

node PRAnalysisNode {
    has pr_url: str;
    has verdict: dict;
    has created_at: str;
}
