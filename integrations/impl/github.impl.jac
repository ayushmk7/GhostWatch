# integrations/impl/github.impl.jac

import from hashlib { sha256 }
import from github { Github }
import from re { findall }
import from os.path { splitext }
import from typing { Any }
import hmac;

impl validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool {
    expected = "sha256=" + hmac.new(
        secret.encode(),
        payload,
        sha256
    ).hexdigest();
    try {
        return hmac.compare_digest(expected, signature);
    } except Exception { # jac:ignore[W2052]
        return False;
    }
}

impl fetch_pr_diff(pr_url: str) -> PRDiff {
    import from os { environ }
    g: Any = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-3] + "/" + parts[-2];
    repo: Any = g.get_repo(repo_name);
    pr: Any = repo.get_pull(pr_number);
    files: Any = list(pr.get_files());
    changed_files: list[str] = [f.filename for f in files];
    diff_parts: list[str] = [];
    for f in files {
        if f.patch {
            diff_parts.append(f"--- {f.filename}\n{f.patch}");
        }
    }
    unified_diff = "\n".join(diff_parts);
    changed_apis = findall(r"^\+.*(?:def|class|walker|node)\s+(\w+)", unified_diff, flags=8);
    return PRDiff(
        pr_number=pr_number,
        pr_url=pr_url,
        changed_files=changed_files,
        unified_diff=unified_diff,
        changed_apis=list(set(changed_apis))
    );
}

impl fetch_file_content(repo_name: str, file_path: str, ref: str) -> str {
    import from os { environ }
    g: Any = Github(environ.get("GITHUB_TOKEN", ""));
    repo: Any = g.get_repo(repo_name);
    try {
        file_obj: Any = repo.get_contents(file_path, ref=ref);
        content: str = file_obj.decoded_content.decode("utf-8");
        return content;
    } except Exception as e { # jac:ignore[W2052]
        print(f"fetch_file_content failed for {file_path}: {e}");
        return "";
    }
}

impl post_pr_comment(pr_url: str, body: str) -> None {
    import from os { environ }
    g: Any = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-3] + "/" + parts[-2];
    repo: Any = g.get_repo(repo_name);
    pr: Any = repo.get_pull(pr_number);
    pr.create_issue_comment(body);
}

impl get_repo_tree(repo_name: str, branch: str) -> list[dict] {
    import from os { environ }
    g: Any = Github(environ.get("GITHUB_TOKEN", ""));
    repo: Any = g.get_repo(repo_name);
    git_tree: Any = repo.get_git_tree(
        repo.get_branch(branch).commit.sha,
        recursive=True
    );
    result: list[dict] = [];
    for item in git_tree.tree {
        item_type: str = getattr(item, "type");
        if item_type == "blob" {
            result.append({"path": item.path, "type": item_type, "size": item.size});
        }
    }
    return result;
}
