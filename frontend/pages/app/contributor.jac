cl import from ...components.AppShell { AppShell }

cl {
    def:pub page() -> JsxElement {
        return <AppShell mode="contributor"/>;
    }
}
