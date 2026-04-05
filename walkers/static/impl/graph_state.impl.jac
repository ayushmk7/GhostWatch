# walkers/static/impl/graph_state.impl.jac
# GraphStateWalker implementation bodies.
# Auto-discovered by jac from walkers/static/graph_state.jac via impl/ convention.

import from graph.nodes { FileNode, PRAnalysisNode, GhostwatchIncidentNode, GapAnalysisNode }

impl GraphStateWalker.fetch {
    self.has_graph = len([-->][?:FileNode]) > 0;
    visit [-->];
}

impl GraphStateWalker.collect_file {
    self.nodes_data = self.nodes_data + [
        {
            "id": jid(here),
            "path": here.path,
            "language": here.language,
            "risk_score": here.risk_score,
            "is_test": here.is_test
        }
    ];
    for target in [-->][?:FileNode] {
        self.edges_data = self.edges_data + [
            {"source": jid(here), "target": jid(target)}
        ];
    }
}

impl GraphStateWalker.collect_pr {
    self.latest_pr = {
        "id": jid(here),
        "pr_url": here.pr_url,
        "verdict": here.verdict,
        "created_at": here.created_at
    };
}

impl GraphStateWalker.collect_incident with GhostwatchIncidentNode entry {
    cand = {
        "id": str(jid(here)),
        "dedupe_key": here.dedupe_key,
        "status": here.status,
        "risk_level": here.risk_level,
        "dependency_name": here.dependency_name,
        "manifest_path": here.manifest_path,
        "fix_pr_url": here.fix_pr_url,
        "sandbox_result": here.sandbox_result,
        "behavioral_trace": here.behavioral_trace,
        "updated_at": here.updated_at
    };
    if not self.latest_incident {
        self.latest_incident = cand;
    } else {
        if str(cand.get("updated_at", "")) > str(self.latest_incident.get("updated_at", "")) {
            self.latest_incident = cand;
        }
    }
}

impl GraphStateWalker.collect_gap with GapAnalysisNode entry {
    cand = {
        "id": str(jid(here)),
        "merge_commit_sha": here.merge_commit_sha,
        "suggestions": here.suggestions,
        "created_at": here.created_at
    };
    if not self.latest_gap {
        self.latest_gap = cand;
    } else {
        if str(cand.get("created_at", "")) > str(self.latest_gap.get("created_at", "")) {
            self.latest_gap = cand;
        }
    }
}

impl GraphStateWalker.finish {
    report {
        "nodes": self.nodes_data,
        "edges": self.edges_data,
        "has_graph": self.has_graph,
        "latest_analysis": self.latest_pr,
        "latest_incident": self.latest_incident,
        "latest_gap_analysis": self.latest_gap
    };
}
