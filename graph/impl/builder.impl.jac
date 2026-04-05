# graph/impl/builder.impl.jac

import from graph.nodes { FileNode }
import from graph.edges { ImportEdge }
import from integrations.github { get_repo_tree, fetch_file_content }
import from ast { parse, walk, Import as AstImport, ImportFrom }
import from typing { Any }

impl GraphBuilderWalker.build with root() entry {
    existing = [root() -->][?:FileNode];
    if len(existing) > 0 {
        report {
            "status": "already_built",
            "nodes_built": len(existing),
            "message": "Graph already exists. Re-call to force rebuild after clearing root."
        };
        return;
    }

    tree = get_repo_tree(self.repo_name, self.branch);
    path_to_node: dict[str, FileNode] = {};

    for item in tree {
        path: str = item["path"];
        dot_idx = path.rfind(".");
        ext = path[dot_idx:] if dot_idx >= 0 else "";
        if ext not in self.allowed_extensions {
            continue;
        }
        if self._should_skip(path) {
            continue;
        }
        content = fetch_file_content(self.repo_name, path, self.branch);
        if not content {
            continue;
        }
        lang = self._detect_language(path);
        is_test: bool = ("test" in path.lower()) or (path.startswith("tests/"));
        file_node = (root() ++> FileNode(
            path=path,
            content=content,
            language=lang,
            risk_score=0,
            is_test=is_test
        ))[0];
        path_to_node[path] = file_node;
        self.file_count += 1;
    }

    for (path, file_node) in path_to_node.items() {
        self._build_import_edges(file_node, path_to_node);
    }

    import from datetime { datetime }
    now: Any = datetime.now();
    report {
        "status": "complete",
        "nodes_built": self.file_count,
        "edges_built": self.edge_count,
        "repo": self.repo_name,
        "branch": self.branch,
        "built_at": str(now)
    };
}

impl GraphBuilderWalker._should_skip(path: str) -> bool {
    return any(skip in path for skip in self.skip_paths);
}

impl GraphBuilderWalker._detect_language(filename: str) -> str {
    dot_idx = filename.rfind(".");
    ext = filename[dot_idx:] if dot_idx >= 0 else "";
    lang_map: dict[str, str] = {".jac": "jac", ".py": "python", ".json": "json", ".toml": "toml"};
    return lang_map.get(ext, "unknown");
}

impl GraphBuilderWalker._build_import_edges(file_node: FileNode, path_to_node: dict[str, FileNode]) -> None {
    if file_node.language != "python" {
        return;
    }
    try {
        ast_tree: Any = parse(file_node.content);
        for ast_node in walk(ast_tree) {
            imported_paths: list[str] = [];
            if isinstance(ast_node, AstImport) {
                for alias in ast_node.names {
                    imported_paths.append(alias.name.replace(".", "/") + ".py");
                }
            } elif isinstance(ast_node, ImportFrom) {
                if ast_node.module {
                    imported_paths.append(ast_node.module.replace(".", "/") + ".py");
                }
            }
            for imp_path in imported_paths {
                if imp_path in path_to_node {
                    target_node: FileNode = path_to_node[imp_path];
                    file_node +>:ImportEdge(is_direct=True, import_type="static"):+> target_node;
                    self.edge_count += 1;
                }
            }
        }
    } except Exception as e { # jac:ignore[W2052]
        print(f"Import edge build failed for {file_node.path}: {e}");
    }
}
