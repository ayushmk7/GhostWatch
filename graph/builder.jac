# graph/builder.jac — GraphBuilderWalker declaration.
# Called once at server start via POST /walker/rebuild-graph.

import from graph.nodes { FileNode }
import from graph.edges { ImportEdge }


walker:pub GraphBuilderWalker {
    has repo_name: str = "jaseci-labs/jaseci";
    has branch: str = "main";
    has file_count: int = 0;
    has edge_count: int = 0;
    has skip_paths: list[str] = ["__pycache__/", ".jac/", "node_modules/", "dist/", "build/"];
    has allowed_extensions: list[str] = [".jac", ".py", ".json", ".toml"];

    can build with Root entry;

    def _should_skip(path: str) -> bool;
    def _detect_language(filename: str) -> str;
    def _build_import_edges(file_node: FileNode, path_to_node: dict) -> None;
}
