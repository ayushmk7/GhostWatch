# walkers/static/orchestrator.jac — OrchestratorWalker declaration.
# Dispatches three specialist walkers in parallel via flow/wait wrapper functions.

import from graph.nodes { FileNode, PRAnalysisNode }
import from objects.verdict { VerdictObject }
import from walkers.static.security { SecurityAuditorWalker }
import from walkers.static.compatibility { CompatibilityCheckerWalker }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }
import from typing { Any }

walker:pub OrchestratorWalker {
    has pr_url: str;
    has verdict: dict = {};

    can orchestrate with `root entry;

    def _run_security(start_node: FileNode, allowed_nodes: set, diff: str) -> dict;
    def _run_compat(start_node: FileNode, allowed_nodes: set, changed_apis: list, diff: str) -> dict;
    def _run_blast(start_node: FileNode, changed_paths: list) -> dict;
    def _get_subgraph_root() -> FileNode | None;
    def _build_allowed_nodes(changed_files: list) -> set;

    def _merge_findings(security: Any, compat: Any, blast: Any, pr_url: str) -> VerdictObject by llm;
}

sem OrchestratorWalker._merge_findings = "Synthesize security findings, compatibility issues, and blast radius data into a single VerdictObject representing the overall risk of this PR.";
