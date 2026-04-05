# walkers/static/impl/orchestrator.impl.jac
import from graph.nodes { FileNode, PRAnalysisNode }
import from objects.verdict { VerdictObject }
import from walkers.static.security { SecurityAuditorWalker }
import from walkers.static.compatibility { CompatibilityCheckerWalker }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }
import from integrations.github { fetch_pr_diff }
import from integrations.discord { notify_discord }
import from typing { Any }

impl OrchestratorWalker.orchestrate with Root entry {
    try {
        pr_diff = fetch_pr_diff(self.pr_url);
    } except Exception as e { # jac:ignore[W2052]
        report {"error": f"Failed to fetch PR diff: {e}", "status": "failed"};
        return;
    }

    allowed_nodes = self._build_allowed_nodes(pr_diff.changed_files);
    start_node = self._get_subgraph_root();
    if not start_node {
        report {
            "error": "No graph built. Call POST /walker/rebuild-graph first.",
            "status": "failed"
        };
        return;
    }

    sec_result: Any = self._run_security(
        start_node, allowed_nodes, pr_diff.unified_diff
    );
    com_result: Any = self._run_compat(
        start_node, allowed_nodes, pr_diff.changed_apis, pr_diff.unified_diff
    );
    bla_result: Any = self._run_blast(start_node, pr_diff.changed_files);

    verdict: Any = None;
    try {
        verdict = self._merge_findings(
            security=sec_result,
            compat=com_result,
            blast=bla_result,
            pr_url=self.pr_url
        );
        # Always override traversal_paths — LLM does not reliably populate this field
        verdict.traversal_paths = {
            "security": sec_result.get("traversal_path", []),
            "compatibility": com_result.get("traversal_path", []),
            "blast_radius": bla_result.get("traversal_path", [])
        };
    } except Exception as e { # jac:ignore[W2052]
        print(f"Merge findings LLM call failed: {e}");
        verdict = VerdictObject(
            overall_risk="unknown",
            risk_score=bla_result.get("risk_score", 0),
            security_findings=sec_result.get("findings", []),
            compatibility_issues=com_result.get("findings", []),
            affected_node_count=bla_result.get("affected_count", 0),
            blast_radius_summary=f"Affected {bla_result.get('affected_count', 0)} nodes",
            recommendation="Manual review required — analysis merge failed",
            traversal_paths={
                "security": sec_result.get("traversal_path", []),
                "compatibility": com_result.get("traversal_path", []),
                "blast_radius": bla_result.get("traversal_path", [])
            }
        );
    }

    import from datetime { datetime }
    now: Any = datetime.now();
    pr_node = (
        root() ++> PRAnalysisNode(
            pr_url=self.pr_url, verdict=dict(vars(verdict)), created_at=str(now)
        )
    )[0];

    pr_parts = self.pr_url.rstrip("/").split("/");
    pr_number = pr_parts[-1];
    report_link = f"http://localhost:3000/analysis/{jid(pr_node)}";
    notify_discord(pr_number, verdict.overall_risk, report_link);

    self.verdict = dict(vars(verdict));
    report self.verdict;
}

impl OrchestratorWalker._run_security(
    start_node: FileNode, allowed_nodes: set[str], diff: str
) -> dict[str, Any] {
    result: Any = start_node spawn SecurityAuditorWalker(
        allowed_nodes=allowed_nodes, pr_context=diff
    );
    return {
        "findings": getattr(result, "findings", []),
        "traversal_path": getattr(result, "traversal_path", [])
    };
}

impl OrchestratorWalker._run_compat(
    start_node: FileNode, allowed_nodes: set[str], changed_apis: list[str], diff: str
) -> dict[str, Any] {
    result: Any = start_node spawn CompatibilityCheckerWalker(
        allowed_nodes=allowed_nodes, changed_apis=changed_apis, pr_diff=diff
    );
    return {
        "findings": getattr(result, "findings", []),
        "traversal_path": getattr(result, "traversal_path", [])
    };
}

impl OrchestratorWalker._run_blast(start_node: FileNode, changed_paths: list[str]) -> dict[str, Any] {
    result: Any = start_node spawn BlastRadiusMapperWalker(changed_nodes=changed_paths);
    affected: Any = getattr(result, "affected_nodes", []);
    return {
        "affected_nodes": affected,
        "risk_score": getattr(result, "risk_score", 0),
        "traversal_path": getattr(result, "traversal_path", []),
        "affected_count": len(affected)
    };
}

impl OrchestratorWalker._get_subgraph_root() -> FileNode | None {
    nodes = [root()-->][?:FileNode];
    if nodes {
        return nodes[0];
    }
    return None;
}

impl OrchestratorWalker._build_allowed_nodes(changed_files: list[str]) -> set[str] {
    import from graph.edges { ImportEdge }
    allowed = set();
    all_file_nodes = [root()-->][?:FileNode];
    changed_node_ids: set = set();
    for node in all_file_nodes {
        if node.path in changed_files {
            allowed.add(jid(node));
            changed_node_ids.add(jid(node));
        }
    }
    # Extend allowed set to include direct neighbors via Python-level edge access
    for node in all_file_nodes {
        if jid(node) in changed_node_ids {
            node_any: Any = node;
            for edge in node_any.__jac__.edges {
                target_anchor: Any = edge.target;
                if target_anchor is not None {
                    target_node: Any = target_anchor.archetype;
                    if isinstance(target_node, FileNode) {
                        allowed.add(jid(target_node));
                    }
                }
            }
        }
    }
    return allowed;
}
