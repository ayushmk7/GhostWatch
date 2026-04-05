cl import from react { createContext, useContext, useState, useEffect }
cl import from "@jac/runtime" { jacSpawn }

cl glob _GRAPH_CTX_BOX: list = [];

def _graph_ctx() -> object {
    if len(_GRAPH_CTX_BOX) == 0 {
        _GRAPH_CTX_BOX.append(createContext(None));
    }
    return _GRAPH_CTX_BOX[0];
}

def:pub useGraphState() -> object {
    Ctx = _graph_ctx();
    return useContext(Ctx);
}

def:pub GraphStateProvider(children: any) -> JsxElement {
    Ctx = _graph_ctx();
    [report, setReport] = useState(None);
    [loading, setLoading] = useState(True);
    [error, setError] = useState(None);

    useEffect(lambda -> None {
        async def runFetch() -> None {
            try {
                result = await jacSpawn("GraphStateProxy", "", {});
                reps = (
                    result["reports"]
                    if result and ("reports" in result)
                    else []
                );
                setReport(reps[0] if reps else {});
                setError(None);
            } except Exception {
                setError("unavailable");
            }
            setLoading(False);
        }

        runFetch();
        setInterval(lambda -> None { runFetch(); }, 5000);
    }, []);

    ctxVal = {"report": report, "loading": loading, "error": error};
    return <Ctx.Provider value={ctxVal}>{children}</Ctx.Provider>;
}
