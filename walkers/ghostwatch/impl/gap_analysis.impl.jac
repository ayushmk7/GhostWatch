# walkers/ghostwatch/impl/gap_analysis.impl.jac

import from graph.nodes { FileNode, TestNode, DocumentationNode, GapAnalysisNode }
import from lib.manifest { rank_gap_candidates }
import from integrations.discord { notify_discord_gap_digest }
import from time { time }

impl GapAnalysisWalker._word_suggestion(path: str, gap_kind: str) -> dict {
    return {
        "title": f"Improve {path}",
        "description": f"Address gap ({gap_kind}) for {path}",
        "difficulty": "intermediate",
        "file_path": path,
        "suggestion_type": gap_kind
    };
}

impl GapAnalysisWalker.run with root() entry {
    paths = [];
    test_paths = set();
    doc_paths = set();
    for fn in [root() -->][?:FileNode] {
        paths.append(fn.path);
    }
    for tn in [root() -->][?:TestNode] {
        test_paths.add(tn.path);
    }
    for dn in [root() -->][?:DocumentationNode] {
        doc_paths.add(dn.path);
    }
    core_prefixes = ["graph/", "walkers/", "lib/", "integrations/", "frontend/"];
    ranked = rank_gap_candidates(paths, test_paths, doc_paths, core_prefixes);
    suggestions = [];
    max_n = 5;
    n = 0;
    for item in ranked {
        if n >= max_n {
            break;
        }
        p = str(item.get("path", ""));
        if not p {
            continue;
        }
        gap_kind = "missing_tests";
        if p.endswith(".jac") {
            gap_kind = "missing_docs";
        }
        if "placeholder" in str(p).lower() or "todo" in str(p).lower() {
            gap_kind = "incomplete_feature";
        }
        try {
            sug = self._word_suggestion(path=p, gap_kind=gap_kind);
        } except Exception {
            sug = {
                "title": f"Improve {p}",
                "description": f"Address gap ({gap_kind}) for {p}",
                "difficulty": "intermediate",
                "file_path": p,
                "suggestion_type": gap_kind
            };
        }
        suggestions.append(sug);
        n += 1;
    }
    if len(suggestions) < 3 {
        for item in ranked {
            if len(suggestions) >= 3 {
                break;
            }
            p = str(item.get("path", ""));
            if not p {
                continue;
            }
            dup_path = False;
            for s in suggestions {
                if str(s.get("file_path", "")) == p {
                    dup_path = True;
                    break;
                }
            }
            if dup_path {
                continue;
            }
            suggestions.append(
                {
                    "title": f"Cover {p}",
                    "description": "Add tests or documentation as appropriate.",
                    "difficulty": "good-first-issue",
                    "file_path": p,
                    "suggestion_type": "missing_tests"
                }
            );
        }
    }
    ts = str(int(time()));
    _ = (root() ++> GapAnalysisNode(merge_commit_sha=self.merge_commit_sha, suggestions=suggestions, created_at=ts))[0];
    notify_discord_gap_digest({"merge_commit_sha": self.merge_commit_sha, "suggestions": suggestions});
    report {"suggestions": len(suggestions)};
}
