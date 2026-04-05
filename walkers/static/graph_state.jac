# walkers/static/graph_state.jac
# GraphStateWalker: returns full graph topology + latest PRAnalysisNode for frontend.
# Called by the frontend on load and every 5s poll.
# Implementation: walkers/static/impl/graph_state.impl.jac

import from graph.nodes { FileNode, PRAnalysisNode, GhostwatchIncidentNode, GapAnalysisNode }

walker:pub GraphStateWalker {
    has nodes_data: list = [];
    has edges_data: list = [];
    has has_graph: bool = False;
    has latest_pr: dict | None = None;
    has latest_incident: dict | None = None;
    has latest_gap: dict | None = None;
    has reports: list = [];

    can fetch with root() entry;
    can collect_file with FileNode entry;
    can collect_pr with PRAnalysisNode entry;
    can collect_incident with GhostwatchIncidentNode entry;
    can collect_gap with GapAnalysisNode entry;
    can finish with root() exit;
}
