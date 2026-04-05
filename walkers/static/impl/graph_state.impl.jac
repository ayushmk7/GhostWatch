# walkers/static/impl/graph_state.impl.jac

import from graph.nodes { FileNode, PRAnalysisNode }
import from typing { Any }

impl GraphStateWalker.get_state with root() entry {
    nodes_data: list[dict[str, Any]] = [];
    edges_data: list[dict[str, str]] = [];

    for fn in [root() -->][?:FileNode] {
        nodes_data.append({
            "id": jid(fn),
            "path": fn.path,
            "risk_score": fn.risk_score,
            "language": fn.language,
            "is_test": fn.is_test
        });
    }

    for fn in [root() -->][?:FileNode] {
        for neighbor in [fn -->][?:FileNode] {
            edges_data.append({
                "source": jid(fn),
                "target": jid(neighbor),
                "type": "ImportEdge"
            });
        }
    }

    pr_nodes = [root() -->][?:PRAnalysisNode];
    latest_analysis = None;
    if pr_nodes {
        last_pr = pr_nodes[-1];
        latest_analysis = {
            "id": jid(last_pr),
            "pr_url": last_pr.pr_url,
            "verdict": last_pr.verdict,
            "created_at": last_pr.created_at
        };
    }

    report {
        "nodes": nodes_data,
        "edges": edges_data,
        "node_count": len(nodes_data),
        "edge_count": len(edges_data),
        "latest_analysis": latest_analysis,
        "has_graph": len(nodes_data) > 0
    };
}
