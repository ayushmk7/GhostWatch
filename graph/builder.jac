# graph/builder.jac — Deterministic shared graph builder (System 1 + System 2).

import from graph.nodes { FileNode }

walker:pub GraphBuilderWalker {
    has repo_name: str = "jaseci-labs/jaseci";
    has branch: str = "main";
    has force: bool = False;
    has file_count: int = 0;
    has edge_count: int = 0;
    has skip_paths: list = ["__pycache__/", ".jac/", "node_modules/", "dist/", "build/"];
    has allowed_extensions: list = [".jac", ".py", ".json", ".toml", ".txt", ".md"];

    can build with root() entry;

    def _should_skip(path: str) -> bool;
    def _detect_language(filename: str) -> str;
}
