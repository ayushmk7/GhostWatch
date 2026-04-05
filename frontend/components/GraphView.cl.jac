import "@xyflow/react/dist/style.css";
cl import from "@xyflow/react" { ReactFlow, Background }

def riskColor(score: Any) -> str {
    s: Any = score if score else 0;
    s_int: int = int(s);
    if s_int >= 14 {
        return "rgba(239,68,68,0.18)";
    }
    if s_int >= 7 {
        return "rgba(251,191,36,0.15)";
    }
    return "rgba(125,211,255,0.18)";
}

def riskBorder(score: Any) -> str {
    s: Any = score if score else 0;
    s_int: int = int(s);
    if s_int >= 14 {
        return "1.5px solid rgba(239,68,68,0.7)";
    }
    if s_int >= 7 {
        return "2px solid rgba(251,191,36,0.55)";
    }
    return "1.5px solid rgba(125,211,255,0.4)";
}

def:pub GraphView(
    nodes_data: list[dict],
    edges_data: list[dict],
    animatingPath: list,
    analysisLoading: bool,
    scanResult: bool
) -> JsxElement {

    has hoveredNode: Any | None = None;

    # Build path-index lookup for O(1) animation delay calc
    path_index: dict = {};
    i: int = 0;
    for jid_val in animatingPath {
        path_index[jid_val] = i;
        i += 1;
    }
    path_len: int = len(animatingPath);

    total: Any = len(nodes_data);
    PI2: Any = 6.28318530718;
    cx_r: int = 400;
    cy_r: int = 280;
    inner_cap: int = 7;
    inner_count: Any = total if total <= inner_cap else inner_cap;
    outer_count: Any = total - inner_count;

    # Build ReactFlow node objects
    xf_nodes: list = [];
    idx: int = 0;
    for n in nodes_data {
        node_style: Any = {
            "background": riskColor(n["risk_score"]),
            "border": riskBorder(n["risk_score"]),
            "borderRadius": "50%",
            "width": "68px",
            "height": "68px",
            "display": "flex",
            "alignItems": "center",
            "justifyContent": "center",
            "color": "rgba(220,239,255,0.88)",
            "fontSize": "9px",
            "fontWeight": "500",
            "letterSpacing": "0.03em",
            "textAlign": "center",
            "cursor": "default",
            "backdropFilter": "blur(6px)",
            "WebkitBackdropFilter": "blur(6px)"
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
        } elif scanResult and path_len == 0 {
            node_style["animationName"] = "gw-node-pulse";
            node_style["animationDuration"] = "2s";
            delay_ms2: Any = idx * 120;
            node_style["animationDelay"] = f"{delay_ms2}ms";
            node_style["animationIterationCount"] = "3";
            node_style["animationTimingFunction"] = "ease-in-out";
            node_style["animationFillMode"] = "forwards";
        }

        node_path: Any = n["path"];
        label: Any = node_path.split("/")[-1]; # jac:ignore[E1032]

        # Radial / mindmap layout
        in_inner: bool = idx < inner_count;
        ring_idx: Any = idx if in_inner else idx - inner_count;
        ring_total: Any = inner_count if in_inner else outer_count;
        radius: Any = 160 if in_inner else 300;
        angle: Any = (ring_idx * PI2) / ring_total if ring_total > 1 else 0;
        x_pos: Any = cx_r + radius * Math.cos(angle); # jac:ignore[E1032]
        y_pos: Any = cy_r + radius * Math.sin(angle); # jac:ignore[E1032]

        xf_nodes.append({
            "id": n["id"],
            "position": {"x": x_pos, "y": y_pos},
            "data": {
                "label": label,
                "path": node_path,
                "risk_score": n["risk_score"],
                "language": n["language"]
            },
            "style": node_style
        });
        idx += 1;
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

    # Resolve hovered node's full data for tooltip
    hovered_data: Any | None = None;
    if hoveredNode {
        hov_id: Any = hoveredNode["id"]; # jac:ignore[E1001]
        for nd in nodes_data {
            if nd["id"] == hov_id {
                hovered_data = nd;
                break;
            }
        }
    }

    risk_label: str = "Low";
    tooltip_risk_class: str = "gw-node-tooltip-value";
    tooltip_lang: str = "—";
    tooltip_score: str = "0";
    tooltip_path: str = "";
    if hovered_data {
        rs: Any = int(hovered_data["risk_score"] or 0);
        if rs >= 14 {
            risk_label = "High";
            tooltip_risk_class = "gw-node-tooltip-value gw-node-tooltip-value--high";
        } elif rs >= 7 {
            risk_label = "Medium";
            tooltip_risk_class = "gw-node-tooltip-value gw-node-tooltip-value--med";
        }
        tooltip_lang = hovered_data["language"] or "—";
        tooltip_score = str(hovered_data["risk_score"] or 0);
        tooltip_path = hovered_data["path"];
    }

    return
        <div className="gw-graph-canvas" style={{"position": "relative"}}>
            <ReactFlow
                nodes={xf_nodes}
                edges={xf_edges}
                fitView={True}
                nodesDraggable={False}
                nodesConnectable={False}
                elementsSelectable={False}
                proOptions={{"hideAttribution": True}}
                onNodeMouseEnter={lambda event: Any, `node: Any {
                    hoveredNode = `node; # jac:ignore[E1001]
                }}
                onNodeMouseLeave={lambda event: Any, `node: Any {
                    hoveredNode = None; # jac:ignore[E1001]
                }}
            >
                <Background color="rgba(125,211,255,0.06)" gap={28} size={1}/>
            </ReactFlow>
            {hovered_data and
                <div className="gw-node-tooltip">
                    <div className="gw-node-tooltip-path">
                        {tooltip_path}
                    </div>
                    <div className="gw-node-tooltip-row">
                        <span className="gw-node-tooltip-label">
                            Risk
                        </span>
                        <span className={tooltip_risk_class}>
                            {risk_label + " (" + tooltip_score + ")"}
                        </span>
                    </div>
                    <div className="gw-node-tooltip-row">
                        <span className="gw-node-tooltip-label">
                            Lang
                        </span>
                        <span className="gw-node-tooltip-value">
                            {tooltip_lang}
                        </span>
                    </div>
                </div>}
        </div>;
}
