# graph/impl/builder.impl.jac

import from graph.nodes { FileNode, DependencyNode, DocumentationNode, TestNode }
import from integrations.github { get_repo_tree, fetch_file_content }
import from lib.manifest { parse_manifest_deps }
import from os.path { splitext }
import from ast { parse, walk, Import as AstImport, ImportFrom }

impl GraphBuilderWalker.build with root() entry {
    existing = [root() -->][?:FileNode];
    path_to_node: dict[str, FileNode] = {};
    for fn in existing {
        path_to_node[fn.path] = fn;
    }
    if len(existing) > 0 and not self.force {
        report {
            "status": "already_built",
            "nodes_built": len(existing),
            "message": "Graph exists; pass force=true to upsert"
        };
        return;
    }
    tree = get_repo_tree(self.repo_name, self.branch);
    for item in tree {
        path = item["path"];
        if self._should_skip(path) {
            continue;
        }
        ext = splitext(path)[1];
        ext_l = ext.lower();
        allowed = False;
        for ae in self.allowed_extensions {
            if ext_l == str(ae).lower() {
                allowed = True;
                break;
            }
        }
        if not allowed {
            continue;
        }
        content = fetch_file_content(self.repo_name, path, self.branch);
        lang = self._detect_language(path);
        is_t = "test" in path.lower() or "/tests/" in path.replace("\\", "/") or path.startswith("tests/");
        if path in path_to_node {
            fnode = path_to_node[path];
            fnode.content = str(content);
            fnode.language = lang;
            fnode.is_test = bool(is_t);
        } else {
            fnode = (root() ++> FileNode(path=path, content=str(content), language=lang, is_test=bool(is_t)))[0];
            path_to_node[path] = fnode;
            self.file_count += 1;
        }
    }
    manifest_markers = ["package.json", "requirements.txt", "pyproject.toml", "jac.toml"];
    for mnode in [root() -->][?:FileNode] {
        mp = mnode.path;
        hit = False;
        for m in manifest_markers {
            if mp.endswith(m) {
                hit = True;
                break;
            }
        }
        if not hit {
            continue;
        }
        deps = parse_manifest_deps(mp, str(mnode.content));
        eco = "pip";
        if mp.endswith("package.json") {
            eco = "npm";
        }
        for (pkg, ver) in deps.items() {
            depn = (root() ++> DependencyNode(package_name=pkg, normalized_name=str(pkg).lower(), version_spec=str(ver), ecosystem=eco))[0];
            depn ++> mnode;
            self.edge_count += 1;
        }
    }
    for fnode in [root() -->][?:FileNode] {
        if fnode.language != "python" {
            continue;
        }
        try {
            pytree = parse(fnode.content);
        } except Exception { # jac:ignore[W2052]
            continue;
        }
        for astn in walk(pytree) {
            imported_paths = [];
            if isinstance(astn, AstImport) {
                for alias in astn.names {
                    imported_paths.append(str(alias.name).replace(".", "/") + ".py");
                }
            }
            if isinstance(astn, ImportFrom) {
                if astn.module {
                    imported_paths.append(str(astn.module).replace(".", "/") + ".py");
                }
            }
            for imp_path in imported_paths {
                for tgt in [root() -->][?:FileNode] {
                    if tgt.path == imp_path {
                        fnode ++> tgt;
                        self.edge_count += 1;
                        break;
                    }
                }
            }
        }
    }
    for fnode in [root() -->][?:FileNode] {
        fp = fnode.path;
        if fp.startswith("docs/") and fp.lower().endswith(".md") {
            d = (root() ++> DocumentationNode(path=fp, title=fp))[0];
            fnode ++> d;
            self.edge_count += 1;
        }
        if fnode.is_test {
            t = (root() ++> TestNode(path=fp, module_guess=fp))[0];
            fnode ++> t;
            self.edge_count += 1;
        }
    }
    report {
        "status": "complete",
        "nodes_built": self.file_count,
        "edges_built": self.edge_count,
        "repo": self.repo_name,
        "branch": self.branch
    };
}

impl GraphBuilderWalker._should_skip(path: str) -> bool {
    for sp in self.skip_paths {
        if sp in path {
            return True;
        }
    }
    return False;
}

impl GraphBuilderWalker._detect_language(filename: str) -> str {
    ext = splitext(filename)[1];
    em: dict[str, str] = {".jac": "jac", ".py": "python", ".json": "json", ".toml": "toml", ".txt": "text", ".md": "markdown"};
    return em.get(ext.lower(), "unknown");
}
