cl import from "@jac/runtime" { Navigate }

cl {
    def:pub page() -> JsxElement {
        return <Navigate to="/" />;
    }
}
