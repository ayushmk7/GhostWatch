cl import from "@jac/runtime" { Outlet }
cl import from ..theme { APP_STYLES }

cl {
    def:pub layout() -> JsxElement {
        return
            <div className="gw-root">
                <style>
                    {APP_STYLES}
                </style>
                <Outlet/>
            </div>;
    }
}
