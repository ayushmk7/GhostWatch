# integrations/github.jac — Walkers call these; never PyGithub directly.

def validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool;

def fetch_pr_diff(pr_url: str) -> dict;

def fetch_file_content(repo_name: str, file_path: str, ref: str) -> str;

def post_pr_comment(pr_url: str, body: str) -> None;

def get_repo_tree(repo_name: str, branch: str) -> list[dict];

def list_commit_files(repo_name: str, commit_sha: str) -> list[str];

def get_parent_commit_sha(repo_name: str, commit_sha: str) -> str;

def create_branch_from_sha(repo_name: str, new_branch: str, sha: str) -> None;

def update_file_on_branch(
    repo_name: str,
    file_path: str,
    branch: str,
    new_content: str,
    commit_message: str
) -> None;

def open_pull_request(
    repo_name: str,
    title: str,
    body: str,
    head_branch: str,
    base_branch: str
) -> str;

def find_open_pr_for_branch(repo_name: str, head_branch: str) -> str;

def get_default_branch(repo_name: str) -> str;

def get_branch_head_sha(repo_name: str, branch: str) -> str;
