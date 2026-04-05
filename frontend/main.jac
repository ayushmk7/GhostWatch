import requests;
import from typing { Any }

walker:pub GraphStateProxy {
    can fetch with Root entry {
        resp: Any = requests.post(
            "http://localhost:8080/walker/GraphStateWalker",
            json={"latest_pr": None, "latest_incident": None, "latest_gap": None}
        );
        body: Any = resp.json();
        inner: Any = body.get("reports", []);
        if len(inner) > 0 {
            report inner[0];
        }
    }
}

walker:pub OrchestratorProxy {
    has pr_url: str;

    can run with Root entry {
        resp: Any = requests.post(
            "http://localhost:8080/walker/OrchestratorWalker",
            json={"pr_url": self.pr_url}
        );
        body: Any = resp.json();
        inner: Any = body.get("reports", []);
        if len(inner) > 0 {
            report inner[0];
        }
    }
}

cl import from "@jac/runtime" { Router, Routes, Route, Navigate }
cl import from .theme { APP_STYLES }
cl import from .pages.index { page as IndexPage }
cl import from .pages.start { page as StartPage }
cl import from .components.AppShell { AppShell }

cl {
    def:pub app() -> JsxElement {
        return
            <Router>
                <div className="gw-root">
                    <style>
                        {APP_STYLES}
                    </style>
                    <Routes>
                        <Route path="/" element={<IndexPage/>}></Route>
                        <Route
                            path="/auth"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route path="/start" element={<StartPage/>}></Route>
                        <Route
                            path="/app/maintainer"
                            element={<AppShell mode="maintainer"/>}
                        ></Route>
                        <Route
                            path="/app/contributor"
                            element={<AppShell mode="contributor"/>}
                        ></Route>
                        <Route
                            path="/app"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route path="*" element={<Navigate to="/" />}></Route>
                    </Routes>
                </div>
            </Router>;
    }
}
