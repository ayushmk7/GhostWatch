cl import from frontend.components.AppShell { AppShell }

cl {
    def:pub page() -> JsxElement {
        return <AppShell mode="contributor"/>;
    }
}
