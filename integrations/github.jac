# integrations/github.jac — PyGithub wrapper declarations.
# Walkers call these functions — never PyGithub directly.

obj PRDiff {
    has pr_number: int;
    has pr_url: str;
    has changed_files: list[str];
    has unified_diff: str;
    has changed_apis: list[str];
}

def validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool;

def fetch_pr_diff(pr_url: str) -> PRDiff;

def fetch_file_content(repo_name: str, file_path: str, ref: str) -> str;

def post_pr_comment(pr_url: str, body: str) -> None;

def get_repo_tree(repo_name: str, branch: str) -> list[dict];
