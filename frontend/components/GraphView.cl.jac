import "@xyflow/react/dist/style.css";
cl import from "@xyflow/react" { ReactFlow, Background, Controls }

def riskColor(score: Any) -> str {
    s: Any = score if score else 0;
    s_int: int = int(s);
    if s_int >= 14 {
        return "rgba(239,68,68,0.85)";
    }
    if s_int >= 7 {
        return "rgba(251,191,36,0.85)";
    }
    return "rgba(125,211,255,0.6)";
}

def:pub GraphView(
    nodes_data: list[dict],
    edges_data: list[dict],
    animatingPath: list,
    analysisLoading: bool
) -> JsxElement {

    # Build path-index lookup for O(1) animation delay calc
    path_index: dict = {};
    for (i, jid_val) in enumerate(animatingPath) {
        path_index[jid_val] = i;
    }
    path_len: int = len(animatingPath);

    # Build ReactFlow node objects
    xf_nodes: list = [];
    for (idx, n) in enumerate(nodes_data) {
        node_style: Any = {
            "background": riskColor(n["risk_score"]),
            "border": "1px solid rgba(220,239,255,0.3)",
            "borderRadius": "6px",
            "padding": "8px 10px",
            "color": "rgba(220,239,255,0.9)",
            "fontSize": "11px",
            "minWidth": "80px",
            "textAlign": "center",
            "cursor": "default"
        };

        if analysisLoading {
            node_style["animationName"] = "gw-node-pulse";
            node_style["animationDuration"] = "1.5s";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        } elif path_len > 0 and n["id"] in path_index {
            node_style["animationName"] = "gw-node-scan";
            node_style["animationDuration"] = f"{path_len * 600}ms";
            delay_ms: Any = path_index[n["id"]] * 600;
            node_style["animationDelay"] = f"{delay_ms}ms";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        }

        node_path: Any = n["path"];
        label: Any = node_path.split("/")[-1]; # jac:ignore[E1032]
        xf_nodes.append({
            "id": n["id"],
            "position": {"x": (idx % 6) * 200, "y": (idx // 6) * 120},
            "data": {"label": label},
            "style": node_style
        });
    }

    # Build ReactFlow edge objects
    xf_edges: Any = [
        {
            "id": f"{e['source']}-{e['target']}",
            "source": e["source"],
            "target": e["target"],
            "animated": True,
            "style": {"stroke": "rgba(125,211,255,0.4)", "strokeWidth": 1.5}
        }
        for e in edges_data
    ];

    return
        <div className="gw-graph-canvas">
            <ReactFlow
                nodes={xf_nodes}
                edges={xf_edges}
                fitView={True}
                nodesDraggable={False}
                nodesConnectable={False}
                elementsSelectable={False}
                proOptions={{"hideAttribution": True}}
            >
                <Background color="rgba(125,211,255,0.08)" gap={24}/>
                <Controls showInteractive={False}/>
            </ReactFlow>
        </div>;
}
