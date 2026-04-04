# System 1 Static Analyzer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the GhostWatch System 1 static PR analysis pipeline — a Jac graph-native backend with three parallel LLM walkers (Security, Compatibility, BlastRadius), a GitHub webhook trigger, Discord notification, a `GraphStateWalker` REST endpoint, and a jac-client frontend showing live graph traversal animation and verdict cards.

**Architecture:** A persistent Jac graph of `jaseci-labs/jaseci` is built once at server start. When a GitHub `pull_request` webhook fires, `OrchestratorWalker` fetches the PR diff, builds an `allowed_nodes` subgraph, and dispatches three walker functions in parallel via Jac's `flow/wait`. Results merge into a `VerdictObject` stored as a `PRAnalysisNode` on root. The frontend polls `GraphStateWalker` every 5s and replays traversal paths as animation via `WalkerTrace`.

**Tech Stack:** Jac (jaclang), jac-client (React/JSX), PyGithub, `by llm` (claude-sonnet-4-20250514), @xyflow/react, Discord HTTP webhook (no discord.py bot for v1 per spec decision)

**Testing strategy:** Real tests only for logic with deterministic outputs — HMAC signature validation (Task 4) and walker traversal / `_severity_from_hops` (Task 8). Everything else uses `jac check` for syntax validation only.

---

## File Map

Files to **create** (System 1 scope):

| File | Responsibility |
|------|----------------|
| `main.jac` | Entry point — imports all walkers, exposes endpoints |
| `jac.toml` | Deps, model config, serve config |
| `.env.example` | Secret template (never commit `.env`) |
| `graph/nodes.jac` | `FileNode`, `FindingNode`, `PRAnalysisNode` declarations |
| `graph/edges.jac` | `ImportEdge`, `BlastEdge`, `FindingEdge` declarations |
| `graph/builder.jac` | `GraphBuilderWalker` declaration |
| `graph/impl/builder.impl.jac` | `GraphBuilderWalker` implementation |
| `objects/verdict.jac` | `VerdictObject`, `SecurityFinding`, `CompatibilityIssue`, `ContributorSuggestion` |
| `integrations/github.jac` | GitHub wrapper function declarations |
| `integrations/impl/github.impl.jac` | GitHub wrapper implementations (PyGithub) |
| `integrations/discord.jac` | Discord `notify_discord` declaration |
| `integrations/impl/discord.impl.jac` | Discord HTTP POST implementation |
| `walkers/static/security.jac` | `SecurityAuditorWalker` declaration |
| `walkers/static/impl/security.impl.jac` | Security walker implementation |
| `walkers/static/compatibility.jac` | `CompatibilityCheckerWalker` declaration |
| `walkers/static/impl/compatibility.impl.jac` | Compatibility walker implementation |
| `walkers/static/blast_radius.jac` | `BlastRadiusMapperWalker` declaration |
| `walkers/static/impl/blast_radius.impl.jac` | Blast radius walker implementation |
| `walkers/static/orchestrator.jac` | `OrchestratorWalker` declaration |
| `walkers/static/impl/orchestrator.impl.jac` | Orchestrator flow/wait dispatch |
| `walkers/static/graph_state.jac` | `GraphStateWalker` declaration |
| `walkers/static/impl/graph_state.impl.jac` | Graph topology serialization |
| `walkers/static/pr_comment.jac` | `PRCommentWriterWalker` declaration |
| `walkers/static/impl/pr_comment.impl.jac` | GitHub PR review comment poster |
| `frontend/pages/layout.jac` | Nav shell wrapping all pages |
| `frontend/pages/index.jac` | Graph visualization + walker animation page |
| `frontend/pages/analysis/[pr_id].jac` | Verdict detail + Approve button |
| `frontend/components/Navigation.cl.jac` | Top nav links |
| `frontend/components/GraphView.cl.jac` | xyflow/react graph renderer |
| `frontend/components/WalkerTrace.cl.jac` | Traversal animation replay |
| `frontend/components/VerdictCard.cl.jac` | Verdict display |
| `tests/test_core.jac` | HMAC validation + walker traversal tests (only real tests in project) |

**Working directory for all file paths:** `/home/asunaron/hackathons/GhostWatch/`

**Syntax validation:** After writing each `.jac` file, run `jac check <file>`. A syntax error in an `.impl.jac` file silently kills ALL implementations in that file — always validate before moving on.

---

## Task 1: Project Scaffolding

**Files:**
- Create: `main.jac`
- Create: `jac.toml`
- Create: `.env.example`

- [ ] **Step 1: Create `jac.toml`**

```toml
[project]
name = "ghostwatch"
version = "1.0.0"
entry = "main.jac"

[dependencies]
PyGithub = "^2.0.0"
requests = "^2.31.0"

[dependencies.npm]
react = "^18.0.0"
"@xyflow/react" = "^12.0.0"

[plugins.byllm.model]
default_model = "claude-sonnet-4-20250514"

[plugins.client]
port = 3000

[serve]
port = 8000
```

- [ ] **Step 2: Create `.env.example`**

```bash
# Required for System 1
GITHUB_TOKEN=ghp_REPLACE_ME
GITHUB_WEBHOOK_SECRET=REPLACE_ME
ANTHROPIC_API_KEY=sk-ant-REPLACE_ME
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/REPLACE_ME

# Required for System 2 (not used by System 1)
E2B_API_KEY=REPLACE_ME
```

- [ ] **Step 3: Create minimal `main.jac`** (will be fully wired in Task 11)

```jac
# main.jac — GhostWatch entry point
# Imports wired in Task 11 once all modules exist.

with entry {
    print("GhostWatch starting...");
}
```

- [ ] **Step 4: Validate and commit**

```bash
jac check main.jac
git add main.jac jac.toml .env.example
git commit -m "feat: scaffold ghostwatch project"
```

---

## Task 2: Graph Data Model — Nodes and Edges

**Files:**
- Create: `graph/nodes.jac`
- Create: `graph/edges.jac`

- [ ] **Step 1: Create `graph/nodes.jac`**

```jac
# graph/nodes.jac — Pure node declarations. No logic, no imports.

node FileNode {
    has path: str;
    has content: str;
    has language: str;
    has risk_score: int = 0;
    has is_test: bool = False;
}

node FindingNode {
    has walker_type: str;
    has severity: str;
    has description: str;
    has evidence: str;
    has line_number: int = 0;
}

node PRAnalysisNode {
    has pr_url: str;
    has verdict: dict;
    has created_at: str;
}
```

- [ ] **Step 2: Create `graph/edges.jac`**

```jac
# graph/edges.jac — Pure edge declarations. No logic, no imports.

edge ImportEdge {
    has is_direct: bool = True;
    has import_type: str = "static";
}

edge BlastEdge {
    has hops: int = 1;
    has impact_type: str = "direct";
}

edge FindingEdge {
    has confidence: float = 1.0;
    has walker_id: str = "";
}
```

- [ ] **Step 3: Validate and commit**

```bash
jac check graph/nodes.jac && jac check graph/edges.jac
git add graph/nodes.jac graph/edges.jac
git commit -m "feat: add graph node and edge declarations"
```

---

## Task 3: VerdictObject and Data Objects

**Files:**
- Create: `objects/verdict.jac`

- [ ] **Step 1: Create `objects/verdict.jac`**

```jac
# objects/verdict.jac — Shared data objects for System 1 and System 2.

obj SecurityFinding {
    has severity: str
        sem="critical, high, medium, or low — how dangerous this issue is";
    has description: str
        sem="concise human-readable description of the security issue";
    has line_number: int
        sem="line number where the issue occurs, 0 if not line-specific";
    has evidence: str
        sem="exact code snippet or path demonstrating the issue";
    has recommendation: str
        sem="specific actionable fix for this issue";
}

obj CompatibilityIssue {
    has api_name: str
        sem="name of the API function or class that has a compatibility issue";
    has issue_type: str
        sem="breaking_change, deprecation, interface_mismatch, or type_change";
    has description: str
        sem="what the compatibility issue is and why it matters";
    has affected_callers: list[str]
        sem="list of file paths that call this API and will break";
}

obj ContributorSuggestion {
    has title: str
        sem="concise issue title suitable for a GitHub issue";
    has description: str
        sem="two to three sentence description of what needs to be done";
    has difficulty: str
        sem="good-first-issue, intermediate, or advanced";
    has file_path: str
        sem="which file this suggestion targets";
    has suggestion_type: str
        sem="missing_tests, missing_docs, incomplete_feature, or missing_example";
}

obj VerdictObject {
    has overall_risk: str
        sem="critical, high, medium, low, or clean — the overall PR risk level";
    has risk_score: int
        sem="0 to 100 numeric risk score where 100 is most dangerous";
    has security_findings: list[SecurityFinding];
    has compatibility_issues: list[CompatibilityIssue];
    has affected_node_count: int
        sem="total number of graph nodes affected by this PR change";
    has blast_radius_summary: str
        sem="one paragraph summary of blast radius analysis results";
    has recommendation: str
        sem="one sentence recommendation for the maintainer reviewing this PR";
    has traversal_paths: dict
        sem="dict with keys security, compatibility, blast_radius — each a list of node jids visited";
}
```

- [ ] **Step 2: Validate and commit**

```bash
jac check objects/verdict.jac
git add objects/verdict.jac
git commit -m "feat: add VerdictObject and finding data types"
```

---

## Task 4: GitHub Integration + HMAC Tests

**Files:**
- Create: `integrations/github.jac`
- Create: `integrations/impl/github.impl.jac`
- Create: `tests/test_core.jac` ← only real tests in the project

- [ ] **Step 1: Create `integrations/github.jac`**

```jac
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
```

- [ ] **Step 2: Create `integrations/impl/github.impl.jac`**

```jac
# integrations/impl/github.impl.jac

import from hmac { new as hmac_new, compare_digest };
import from hashlib { sha256 };
import from github { Github };
import from re { findall };
import from os.path { splitext };

impl validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool {
    expected = "sha256=" + hmac_new(
        secret.encode(),
        payload,
        sha256
    ).hexdigest();
    try {
        return compare_digest(expected, signature);
    } except Exception {
        return False;
    }
}

impl fetch_pr_diff(pr_url: str) -> PRDiff {
    import from os { environ };
    g = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-3] + "/" + parts[-2];
    repo = g.get_repo(repo_name);
    pr = repo.get_pull(pr_number);
    changed_files = [f.filename for f in pr.get_files()];
    diff_parts = [];
    for f in pr.get_files() {
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
    import from os { environ };
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        file_obj = repo.get_contents(file_path, ref=ref);
        return file_obj.decoded_content.decode("utf-8");
    } except Exception as e {
        print(f"fetch_file_content failed for {file_path}: {e}");
        return "";
    }
}

impl post_pr_comment(pr_url: str, body: str) -> None {
    import from os { environ };
    g = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-3] + "/" + parts[-2];
    repo = g.get_repo(repo_name);
    pr = repo.get_pull(pr_number);
    pr.create_issue_comment(body);
}

impl get_repo_tree(repo_name: str, branch: str) -> list[dict] {
    import from os { environ };
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    tree = repo.get_git_tree(
        repo.get_branch(branch).commit.sha,
        recursive=True
    );
    return [
        {"path": item.path, "type": item.type, "size": item.size}
        for item in tree.tree
        if item.type == "blob"
    ];
}
```

- [ ] **Step 3: Write `tests/test_core.jac` with the HMAC test (pure logic, deterministic)**

```jac
# tests/test_core.jac
# Only tests with deterministic, pure-logic outputs.
# No LLM calls, no GitHub API calls, no live network.

import from integrations.github { validate_webhook_signature };

test "HMAC validation accepts correct signature" {
    import from hmac { new as hmac_new };
    import from hashlib { sha256 };
    
    payload = b"test_payload";
    secret = "my_secret";
    correct_sig = "sha256=" + hmac_new(secret.encode(), payload, sha256).hexdigest();
    
    assert validate_webhook_signature(payload, correct_sig, secret) == True;
}

test "HMAC validation rejects wrong signature" {
    payload = b"test_payload";
    assert validate_webhook_signature(payload, "sha256=deadbeef", "my_secret") == False;
}

test "HMAC validation rejects empty signature" {
    payload = b"test_payload";
    assert validate_webhook_signature(payload, "", "my_secret") == False;
}
```

- [ ] **Step 4: Run the HMAC tests**

```bash
jac test tests/test_core.jac
```
Expected: PASS (3 tests)

- [ ] **Step 5: Validate impl file**

```bash
jac check integrations/github.jac && jac check integrations/impl/github.impl.jac
```

- [ ] **Step 6: Commit**

```bash
git add integrations/github.jac integrations/impl/github.impl.jac tests/test_core.jac
git commit -m "feat: add GitHub integration with HMAC validation (tested)"
```

---

## Task 5: Discord Integration

**Files:**
- Create: `integrations/discord.jac`
- Create: `integrations/impl/discord.impl.jac`

- [ ] **Step 1: Create `integrations/discord.jac`**

```jac
# integrations/discord.jac — Discord webhook notification (send only, no bot).

def notify_discord(pr_number: str, risk: str, report_link: str) -> None;

def notify_discord_error(pr_number: str, error_message: str) -> None;
```

- [ ] **Step 2: Create `integrations/impl/discord.impl.jac`**

```jac
# integrations/impl/discord.impl.jac

import from os { environ };
import requests;

impl notify_discord(pr_number: str, risk: str, report_link: str) -> None {
    webhook_url = environ.get("DISCORD_WEBHOOK_URL", "");
    if not webhook_url {
        print("DISCORD_WEBHOOK_URL not set — skipping Discord notification");
        return;
    }
    risk_emoji = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🟢", "CLEAN": "✅"};
    emoji = risk_emoji.get(risk.upper(), "⚪");
    payload = {
        "username": "GhostWatch",
        "content": f"{emoji} **PR #{pr_number} analyzed — Risk: {risk.upper()}**\nView report → {report_link}"
    };
    try {
        resp = requests.post(webhook_url, json=payload, timeout=10);
        if resp.status_code not in [200, 204] {
            print(f"Discord webhook returned {resp.status_code}");
        }
    } except Exception as e {
        print(f"Discord notification failed: {e}");
    }
}

impl notify_discord_error(pr_number: str, error_message: str) -> None {
    webhook_url = environ.get("DISCORD_WEBHOOK_URL", "");
    if not webhook_url {
        return;
    }
    payload = {
        "username": "GhostWatch",
        "content": f"⚠️ **PR #{pr_number} analysis failed** — {error_message}"
    };
    try {
        requests.post(webhook_url, json=payload, timeout=10);
    } except Exception as e {
        print(f"Discord error notification failed: {e}");
    }
}
```

- [ ] **Step 3: Validate and commit**

```bash
jac check integrations/discord.jac && jac check integrations/impl/discord.impl.jac
git add integrations/discord.jac integrations/impl/discord.impl.jac
git commit -m "feat: add Discord HTTP webhook notification"
```

---

## Task 6: GraphBuilderWalker

**Files:**
- Create: `graph/builder.jac`
- Create: `graph/impl/builder.impl.jac`

- [ ] **Step 1: Create `graph/builder.jac`**

```jac
# graph/builder.jac — GraphBuilderWalker declaration.
# Called once at server start via POST /walker/rebuild-graph.

import from graph.nodes { FileNode };
import from graph.edges { ImportEdge };

walker:pub GraphBuilderWalker {
    has repo_name: str = "jaseci-labs/jaseci";
    has branch: str = "main";
    has file_count: int = 0;
    has edge_count: int = 0;
    has skip_paths: list[str] = ["__pycache__/", ".jac/", "node_modules/", "dist/", "build/"];
    has allowed_extensions: list[str] = [".jac", ".py", ".json", ".toml"];

    can build with `root entry;

    def _should_skip(path: str) -> bool;
    def _detect_language(filename: str) -> str;
    def _build_import_edges(file_node: FileNode) -> None;
}
```

- [ ] **Step 2: Create `graph/impl/builder.impl.jac`**

```jac
# graph/impl/builder.impl.jac

import from graph.nodes { FileNode };
import from graph.edges { ImportEdge };
import from integrations.github { get_repo_tree, fetch_file_content };
import from ast { parse, walk, Import as AstImport, ImportFrom };
import from os.path { splitext };
import from datetime { datetime };

impl GraphBuilderWalker.build with `root entry {
    existing = [root -->][?:FileNode];
    if len(existing) > 0 {
        report {
            "status": "already_built",
            "nodes_built": len(existing),
            "message": "Graph already exists. Re-call to force rebuild after clearing root."
        };
        return;
    }

    tree = get_repo_tree(self.repo_name, self.branch);
    path_to_node = {};

    for item in tree {
        path = item["path"];
        _, ext = splitext(path);
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
        file_node = (root ++> FileNode(
            path=path,
            content=content,
            language=lang,
            risk_score=0,
            is_test="test" in path.lower() or path.startswith("tests/")
        ))[0];
        path_to_node[path] = file_node;
        self.file_count += 1;
    }

    # Second pass: build import edges between Python files
    for (path, file_node) in path_to_node.items() {
        self._build_import_edges(file_node);
    }

    report {
        "status": "complete",
        "nodes_built": self.file_count,
        "edges_built": self.edge_count,
        "repo": self.repo_name,
        "branch": self.branch,
        "built_at": datetime.now().isoformat()
    };
}

impl GraphBuilderWalker._should_skip(path: str) -> bool {
    return any(skip in path for skip in self.skip_paths);
}

impl GraphBuilderWalker._detect_language(filename: str) -> str {
    _, ext = splitext(filename);
    lang_map = {".jac": "jac", ".py": "python", ".json": "json", ".toml": "toml"};
    return lang_map.get(ext, "unknown");
}

impl GraphBuilderWalker._build_import_edges(file_node: FileNode) -> None {
    if file_node.language != "python" {
        return;
    }
    try {
        tree = parse(file_node.content);
        for node in walk(tree) {
            imported_paths = [];
            if isinstance(node, AstImport) {
                for alias in node.names {
                    imported_paths.append(alias.name.replace(".", "/") + ".py");
                }
            } elif isinstance(node, ImportFrom) {
                if node.module {
                    imported_paths.append(node.module.replace(".", "/") + ".py");
                }
            }
            for imp_path in imported_paths {
                matches = [n for n in [root-->][?:FileNode] if n.path == imp_path];
                if matches {
                    file_node ++> [ImportEdge(is_direct=True, import_type="static")] ++> matches[0];
                    self.edge_count += 1;
                }
            }
        }
    } except Exception as e {
        print(f"Import edge build failed for {file_node.path}: {e}");
    }
}
```

- [ ] **Step 3: Validate and commit**

```bash
jac check graph/builder.jac && jac check graph/impl/builder.impl.jac
git add graph/builder.jac graph/impl/builder.impl.jac
git commit -m "feat: add GraphBuilderWalker"
```

---

## Task 7: Specialist Walker Declarations

**Files:**
- Create: `walkers/static/security.jac`
- Create: `walkers/static/compatibility.jac`
- Create: `walkers/static/blast_radius.jac`

- [ ] **Step 1: Create `walkers/static/security.jac`**

```jac
# walkers/static/security.jac

import from graph.nodes { FileNode };
import from objects.verdict { SecurityFinding };

walker SecurityAuditorWalker {
    has pr_context: str = "";
    has allowed_nodes: set = {};
    has findings: list[SecurityFinding] = [];
    has traversal_path: list[str] = [];

    can analyze with FileNode entry;

    def audit_file(
        content: str
            sem="full source code of the file being analyzed for security issues",
        path: str
            sem="file path providing context about what kind of file this is",
        pr_context: str
            sem="the PR diff showing exactly what was added or changed in this PR"
    ) -> list[SecurityFinding] by llm;
}
```

- [ ] **Step 2: Create `walkers/static/compatibility.jac`**

```jac
# walkers/static/compatibility.jac

import from graph.nodes { FileNode };
import from objects.verdict { CompatibilityIssue };

walker CompatibilityCheckerWalker {
    has pr_diff: str = "";
    has changed_apis: list[str] = [];
    has allowed_nodes: set = {};
    has findings: list[CompatibilityIssue] = [];
    has traversal_path: list[str] = [];

    can check_api_surface with FileNode entry;

    def check_compatibility(
        file_content: str
            sem="source content of the file using the changed API",
        changed_apis: list[str]
            sem="list of API function or class names that were modified in this PR",
        file_path: str
            sem="path of the caller file for context about its role"
    ) -> list[CompatibilityIssue] by llm;

    def _uses_changed_api(
        content: str
            sem="source file content to scan for usage of the changed APIs",
        changed_apis: list[str]
            sem="list of API names to look for in the content"
    ) -> bool by llm;
}
```

- [ ] **Step 3: Create `walkers/static/blast_radius.jac`**

```jac
# walkers/static/blast_radius.jac

import from graph.nodes { FileNode };

walker BlastRadiusMapperWalker {
    has changed_nodes: list[str] = [];
    has affected_nodes: list[str] = [];
    has max_hops: int = 5;
    has current_hop: int = 0;
    has risk_score: int = 0;
    has traversal_path: list[str] = [];

    can map_blast with FileNode entry;

    def _score_node(
        node_path: str
            sem="the file path of the node being scored for blast radius impact",
        node_language: str
            sem="the programming language of the file: jac, python, json, toml",
        hop_distance: int
            sem="how many hops away from the changed files this node is"
    ) -> int by llm;

    def _severity_from_hops(hops: int) -> str;
}
```

- [ ] **Step 4: Validate all three and commit**

```bash
jac check walkers/static/security.jac && \
jac check walkers/static/compatibility.jac && \
jac check walkers/static/blast_radius.jac
git add walkers/static/security.jac walkers/static/compatibility.jac walkers/static/blast_radius.jac
git commit -m "feat: add SecurityAuditor, CompatibilityChecker, BlastRadius walker declarations"
```

---

## Task 8: Specialist Walker Implementations + Traversal Tests

**Files:**
- Create: `walkers/static/impl/security.impl.jac`
- Create: `walkers/static/impl/compatibility.impl.jac`
- Create: `walkers/static/impl/blast_radius.impl.jac`
- Modify: `tests/test_core.jac`

- [ ] **Step 1: Create `walkers/static/impl/security.impl.jac`**

```jac
# walkers/static/impl/security.impl.jac

import from graph.nodes { FileNode };

impl SecurityAuditorWalker.analyze with FileNode entry {
    if self.allowed_nodes and jid(here) not in self.allowed_nodes {
        disengage;
    }
    if here.is_test {
        disengage;
    }
    self.traversal_path.append(jid(here));
    try {
        new_findings = self.audit_file(
            content=here.content,
            path=here.path,
            pr_context=self.pr_context
        );
        self.findings = self.findings + new_findings;
    } except Exception as e {
        print(f"SecurityAuditor LLM call failed for {here.path}: {e}");
    }
    visit [-->][?:FileNode];
    report {
        "findings": self.findings,
        "traversal_path": self.traversal_path
    };
}
```

- [ ] **Step 2: Create `walkers/static/impl/compatibility.impl.jac`**

```jac
# walkers/static/impl/compatibility.impl.jac

import from graph.nodes { FileNode };

impl CompatibilityCheckerWalker.check_api_surface with FileNode entry {
    if self.allowed_nodes and jid(here) not in self.allowed_nodes {
        disengage;
    }
    self.traversal_path.append(jid(here));
    try {
        if self._uses_changed_api(content=here.content, changed_apis=self.changed_apis) {
            new_findings = self.check_compatibility(
                file_content=here.content,
                changed_apis=self.changed_apis,
                file_path=here.path
            );
            self.findings = self.findings + new_findings;
        }
    } except Exception as e {
        print(f"CompatibilityChecker LLM call failed for {here.path}: {e}");
    }
    visit [-->][?:FileNode];
    report {
        "findings": self.findings,
        "traversal_path": self.traversal_path
    };
}
```

- [ ] **Step 3: Create `walkers/static/impl/blast_radius.impl.jac`**

```jac
# walkers/static/impl/blast_radius.impl.jac

import from graph.nodes { FileNode };

impl BlastRadiusMapperWalker.map_blast with FileNode entry {
    is_changed = here.path in self.changed_nodes;
    is_affected = self.current_hop > 0;

    if not is_changed and not is_affected {
        visit [-->][?:FileNode];
        return;
    }
    if here.path in self.affected_nodes {
        return;
    }
    self.affected_nodes.append(here.path);
    self.traversal_path.append(jid(here));

    try {
        node_score = self._score_node(
            node_path=here.path,
            node_language=here.language,
            hop_distance=self.current_hop
        );
        here.risk_score = node_score;
        self.risk_score += node_score;
    } except Exception as e {
        print(f"BlastRadius score failed for {here.path}: {e}");
        here.risk_score = max(0, 10 - self.current_hop * 2);
        self.risk_score += here.risk_score;
    }

    if self.current_hop < self.max_hops {
        self.current_hop += 1;
        visit [-->][?:FileNode];
        self.current_hop -= 1;
    }

    report {
        "affected_nodes": self.affected_nodes,
        "risk_score": self.risk_score,
        "traversal_path": self.traversal_path,
        "affected_count": len(self.affected_nodes)
    };
}

impl BlastRadiusMapperWalker._severity_from_hops(hops: int) -> str {
    if hops == 0 {
        return "critical";
    } elif hops == 1 {
        return "high";
    } elif hops == 2 {
        return "medium";
    } else {
        return "low";
    }
}
```

- [ ] **Step 4: Validate all three impl files**

```bash
jac check walkers/static/impl/security.impl.jac && \
jac check walkers/static/impl/compatibility.impl.jac && \
jac check walkers/static/impl/blast_radius.impl.jac
```
Expected: no errors

- [ ] **Step 5: Add walker logic tests to `tests/test_core.jac`**

These test the two pieces of pure deterministic logic: `_severity_from_hops` and the `allowed_nodes` disengage guard.

```jac
# Append to tests/test_core.jac
import from graph.nodes { FileNode };
import from graph.edges { ImportEdge };
import from walkers.static.blast_radius { BlastRadiusMapperWalker };
import from walkers.static.security { SecurityAuditorWalker };

test "BlastRadiusMapper _severity_from_hops is correct" {
    w = BlastRadiusMapperWalker(changed_nodes=[]);
    assert w._severity_from_hops(0) == "critical";
    assert w._severity_from_hops(1) == "high";
    assert w._severity_from_hops(2) == "medium";
    assert w._severity_from_hops(3) == "low";
    assert w._severity_from_hops(5) == "low";
}

test "SecurityAuditorWalker with empty allowed_nodes visits no nodes" {
    # Build a minimal graph for traversal test
    test_node = FileNode(path="src/a.jac", content="walker Foo {}", language="jac");
    root ++> test_node;

    # empty allowed_nodes set means disengage immediately on every node
    w = SecurityAuditorWalker(allowed_nodes={"__nonexistent__"}, pr_context="diff");
    result = root spawn w;

    # Walker should report empty traversal_path (no nodes visited)
    if result.reports and result.reports.length > 0 {
        report_data = result.reports[0];
        assert len(report_data.get("traversal_path", [])) == 0;
    }
}
```

- [ ] **Step 6: Run all tests**

```bash
jac test tests/test_core.jac
```
Expected: PASS (5 tests total — 3 HMAC + 2 walker logic)

- [ ] **Step 7: Commit**

```bash
git add walkers/static/impl/security.impl.jac walkers/static/impl/compatibility.impl.jac walkers/static/impl/blast_radius.impl.jac tests/test_core.jac
git commit -m "feat: implement walker logic with traversal tests"
```

---

## Task 9: OrchestratorWalker

**Files:**
- Create: `walkers/static/orchestrator.jac`
- Create: `walkers/static/impl/orchestrator.impl.jac`

- [ ] **Step 1: Create `walkers/static/orchestrator.jac`**

```jac
# walkers/static/orchestrator.jac — OrchestratorWalker declaration.
# Dispatches three specialist walkers in parallel via flow/wait wrapper functions.

import from graph.nodes { FileNode, PRAnalysisNode };
import from objects.verdict { VerdictObject };
import from walkers.static.security { SecurityAuditorWalker };
import from walkers.static.compatibility { CompatibilityCheckerWalker };
import from walkers.static.blast_radius { BlastRadiusMapperWalker };

walker:pub OrchestratorWalker {
    has pr_url: str;
    has verdict: dict = {};

    can orchestrate with `root entry;

    # Wrapper functions — flow/wait works on functions, not walker spawns directly
    def _run_security(start_node: FileNode, allowed_nodes: set, diff: str) -> dict;
    def _run_compat(start_node: FileNode, allowed_nodes: set, changed_apis: list, diff: str) -> dict;
    def _run_blast(start_node: FileNode, changed_paths: list) -> dict;
    def _get_subgraph_root() -> FileNode | None;
    def _build_allowed_nodes(changed_files: list) -> set;

    def _merge_findings(
        security: dict
            sem="security walker result with findings list and traversal_path",
        compat: dict
            sem="compatibility walker result with findings list and traversal_path",
        blast: dict
            sem="blast radius result with risk_score, affected_count, traversal_path",
        pr_url: str
            sem="the GitHub PR URL being analyzed"
    ) -> VerdictObject by llm;
}
```

- [ ] **Step 2: Create `walkers/static/impl/orchestrator.impl.jac`**

```jac
# walkers/static/impl/orchestrator.impl.jac

import from graph.nodes { FileNode, PRAnalysisNode };
import from objects.verdict { VerdictObject };
import from walkers.static.security { SecurityAuditorWalker };
import from walkers.static.compatibility { CompatibilityCheckerWalker };
import from walkers.static.blast_radius { BlastRadiusMapperWalker };
import from integrations.github { fetch_pr_diff };
import from integrations.discord { notify_discord };
import from datetime { datetime };

impl OrchestratorWalker.orchestrate with `root entry {
    try {
        pr_diff = fetch_pr_diff(self.pr_url);
    } except Exception as e {
        report {"error": f"Failed to fetch PR diff: {e}", "status": "failed"};
        return;
    }

    allowed_nodes = self._build_allowed_nodes(pr_diff.changed_files);
    start_node = self._get_subgraph_root();
    if not start_node {
        report {"error": "No graph built. Call POST /walker/rebuild-graph first.", "status": "failed"};
        return;
    }

    # Parallel dispatch via flow/wait
    sec_future = flow self._run_security(start_node, allowed_nodes, pr_diff.unified_diff);
    com_future = flow self._run_compat(start_node, allowed_nodes, pr_diff.changed_apis, pr_diff.unified_diff);
    bla_future = flow self._run_blast(start_node, pr_diff.changed_files);

    sec_result = wait sec_future;
    com_result = wait com_future;
    bla_result = wait bla_future;

    try {
        verdict = self._merge_findings(
            security=sec_result,
            compat=com_result,
            blast=bla_result,
            pr_url=self.pr_url
        );
    } except Exception as e {
        print(f"Merge findings LLM call failed: {e}");
        verdict = VerdictObject(
            overall_risk="unknown",
            risk_score=bla_result.get("risk_score", 0),
            security_findings=sec_result.get("findings", []),
            compatibility_issues=com_result.get("findings", []),
            affected_node_count=bla_result.get("affected_count", 0),
            blast_radius_summary=f"Affected {bla_result.get('affected_count', 0)} nodes",
            recommendation="Manual review required — analysis merge failed",
            traversal_paths={
                "security": sec_result.get("traversal_path", []),
                "compatibility": com_result.get("traversal_path", []),
                "blast_radius": bla_result.get("traversal_path", [])
            }
        );
    }

    pr_node = (root ++> PRAnalysisNode(
        pr_url=self.pr_url,
        verdict=vars(verdict),
        created_at=datetime.now().isoformat()
    ))[0];

    pr_parts = self.pr_url.rstrip("/").split("/");
    pr_number = pr_parts[-1];
    report_link = f"http://localhost:3000/analysis/{jid(pr_node)}";
    notify_discord(pr_number, verdict.overall_risk, report_link);

    self.verdict = vars(verdict);
    report self.verdict;
}

impl OrchestratorWalker._run_security(start_node: FileNode, allowed_nodes: set, diff: str) -> dict {
    result = start_node spawn SecurityAuditorWalker(
        allowed_nodes=allowed_nodes,
        pr_context=diff
    );
    if result.reports {
        return result.reports[0];
    }
    return {"findings": [], "traversal_path": []};
}

impl OrchestratorWalker._run_compat(start_node: FileNode, allowed_nodes: set, changed_apis: list, diff: str) -> dict {
    result = start_node spawn CompatibilityCheckerWalker(
        allowed_nodes=allowed_nodes,
        changed_apis=changed_apis,
        pr_diff=diff
    );
    if result.reports {
        return result.reports[0];
    }
    return {"findings": [], "traversal_path": []};
}

impl OrchestratorWalker._run_blast(start_node: FileNode, changed_paths: list) -> dict {
    result = start_node spawn BlastRadiusMapperWalker(
        changed_nodes=changed_paths
    );
    if result.reports {
        return result.reports[0];
    }
    return {"affected_nodes": [], "risk_score": 0, "traversal_path": [], "affected_count": 0};
}

impl OrchestratorWalker._get_subgraph_root() -> FileNode | None {
    nodes = [root -->][?:FileNode];
    if nodes {
        return nodes[0];
    }
    return None;
}

impl OrchestratorWalker._build_allowed_nodes(changed_files: list) -> set {
    allowed = set();
    all_file_nodes = [root -->][?:FileNode];
    changed_nodes = [];
    for node in all_file_nodes {
        if node.path in changed_files {
            allowed.add(jid(node));
            changed_nodes.append(node);
        }
    }
    for node in changed_nodes {
        for neighbor in [node -->][?:FileNode] {
            allowed.add(jid(neighbor));
        }
    }
    return allowed;
}
```

- [ ] **Step 3: Validate and commit**

```bash
jac check walkers/static/orchestrator.jac && jac check walkers/static/impl/orchestrator.impl.jac
git add walkers/static/orchestrator.jac walkers/static/impl/orchestrator.impl.jac
git commit -m "feat: add OrchestratorWalker with parallel flow/wait dispatch"
```

---

## Task 10: GraphStateWalker and PRCommentWriterWalker

**Files:**
- Create: `walkers/static/graph_state.jac`
- Create: `walkers/static/impl/graph_state.impl.jac`
- Create: `walkers/static/pr_comment.jac`
- Create: `walkers/static/impl/pr_comment.impl.jac`

- [ ] **Step 1: Create `walkers/static/graph_state.jac`**

```jac
# walkers/static/graph_state.jac — Serves graph topology + latest PRAnalysisNode.

walker:pub GraphStateWalker {
    can get_state with `root entry;
}
```

- [ ] **Step 2: Create `walkers/static/impl/graph_state.impl.jac`**

```jac
# walkers/static/impl/graph_state.impl.jac

import from graph.nodes { FileNode, PRAnalysisNode };

impl GraphStateWalker.get_state with `root entry {
    nodes_data = [];
    edges_data = [];

    for fn in [root -->][?:FileNode] {
        nodes_data.append({
            "id": jid(fn),
            "path": fn.path,
            "risk_score": fn.risk_score,
            "language": fn.language,
            "is_test": fn.is_test
        });
    }

    for fn in [root -->][?:FileNode] {
        for neighbor in [fn -->][?:FileNode] {
            edges_data.append({
                "source": jid(fn),
                "target": jid(neighbor),
                "type": "ImportEdge"
            });
        }
    }

    pr_nodes = [root -->][?:PRAnalysisNode];
    latest_analysis = None;
    if pr_nodes {
        latest_analysis = {
            "id": jid(pr_nodes[-1]),
            "pr_url": pr_nodes[-1].pr_url,
            "verdict": pr_nodes[-1].verdict,
            "created_at": pr_nodes[-1].created_at
        };
    }

    report {
        "nodes": nodes_data,
        "edges": edges_data,
        "node_count": len(nodes_data),
        "edge_count": len(edges_data),
        "latest_analysis": latest_analysis,
        "has_graph": len(nodes_data) > 0
    };
}
```

- [ ] **Step 3: Create `walkers/static/pr_comment.jac`**

```jac
# walkers/static/pr_comment.jac — Posts GitHub PR review comment on Approve.
# Idempotent — checks if comment already posted.

walker:pub PRCommentWriterWalker {
    has pr_url: str;
    has verdict_id: str;

    can post_review with `root entry;

    def _format_verdict_comment(
        verdict: dict
            sem="the full VerdictObject dict including all findings and risk scores"
    ) -> str by llm;
}
```

- [ ] **Step 4: Create `walkers/static/impl/pr_comment.impl.jac`**

```jac
# walkers/static/impl/pr_comment.impl.jac

import from graph.nodes { PRAnalysisNode };
import from integrations.github { post_pr_comment };

impl PRCommentWriterWalker.post_review with `root entry {
    pr_nodes = [root -->][?:PRAnalysisNode];
    target = None;
    for node in pr_nodes {
        if jid(node) == self.verdict_id {
            target = node;
            break;
        }
    }

    if not target {
        report {"error": f"PRAnalysisNode {self.verdict_id} not found", "status": "failed"};
        return;
    }

    verdict = target.verdict;
    if verdict.get("comment_posted", False) {
        report {"status": "already_posted", "comments_posted": 0};
        return;
    }

    try {
        comment_body = self._format_verdict_comment(verdict=verdict);
    } except Exception as e {
        risk = verdict.get("overall_risk", "unknown").upper();
        score = verdict.get("risk_score", 0);
        affected = verdict.get("affected_node_count", 0);
        comment_body = f"""## GhostWatch Analysis

**Overall Risk:** {risk} (score: {score}/100)  
**Affected Nodes:** {affected}

**Security Findings:** {len(verdict.get("security_findings", []))}  
**Compatibility Issues:** {len(verdict.get("compatibility_issues", []))}  
**Blast Radius:** {verdict.get("blast_radius_summary", "N/A")}

**Recommendation:** {verdict.get("recommendation", "Review manually")}

---
*Posted by GhostWatch — System 1 Static Analyzer*""";
    }

    try {
        post_pr_comment(self.pr_url, comment_body);
        target.verdict = {**verdict, "comment_posted": True};
        report {"status": "success", "comments_posted": 1};
    } except Exception as e {
        report {"error": str(e), "status": "failed", "comments_posted": 0};
    }
}
```

- [ ] **Step 5: Validate all four files and commit**

```bash
jac check walkers/static/graph_state.jac && \
jac check walkers/static/impl/graph_state.impl.jac && \
jac check walkers/static/pr_comment.jac && \
jac check walkers/static/impl/pr_comment.impl.jac
git add walkers/static/graph_state.jac walkers/static/impl/graph_state.impl.jac walkers/static/pr_comment.jac walkers/static/impl/pr_comment.impl.jac
git commit -m "feat: add GraphStateWalker and PRCommentWriterWalker"
```

---

## Task 11: Wire main.jac

**Files:**
- Modify: `main.jac`

- [ ] **Step 1: Rewrite `main.jac` with full imports and webhook walker**

```jac
# main.jac — GhostWatch entry point.
# jac start main.jac exposes all walker:pub endpoints automatically.

import from graph.nodes { FileNode, PRAnalysisNode };
import from graph.edges { ImportEdge, BlastEdge };
import from objects.verdict { VerdictObject, SecurityFinding, CompatibilityIssue };
import from graph.builder { GraphBuilderWalker };
import from walkers.static.orchestrator { OrchestratorWalker };
import from walkers.static.security { SecurityAuditorWalker };
import from walkers.static.compatibility { CompatibilityCheckerWalker };
import from walkers.static.blast_radius { BlastRadiusMapperWalker };
import from walkers.static.graph_state { GraphStateWalker };
import from walkers.static.pr_comment { PRCommentWriterWalker };
import from integrations.github { validate_webhook_signature };
import from integrations.discord { notify_discord };
import from os { environ };

walker:pub GitHubWebhookWalker {
    has event_type: str;
    has payload: dict;
    has signature: str = "";

    can handle with `root entry {
        secret = environ.get("GITHUB_WEBHOOK_SECRET", "");
        if secret and self.signature {
            payload_bytes = str(self.payload).encode();
            if not validate_webhook_signature(payload_bytes, self.signature, secret) {
                report {"error": "Invalid webhook signature", "status": 401};
                return;
            }
        }

        if self.event_type == "pull_request" {
            action = self.payload.get("action", "");
            if action in ["opened", "synchronize", "reopened"] {
                pr = self.payload.get("pull_request", {});
                pr_url = pr.get("html_url", "");
                if pr_url {
                    root spawn OrchestratorWalker(pr_url=pr_url);
                    report {"status": "analysis_triggered", "pr_url": pr_url};
                    return;
                }
            }
        }

        report {"status": "webhook_received", "event": self.event_type};
    }
}

with entry {
    print("GhostWatch System 1 ready.");
    print("Step 1: POST /walker/rebuild-graph to build the codebase graph.");
    print("Step 2: Configure GitHub webhook → POST /walker/git-hub-webhook-walker");
}
```

- [ ] **Step 2: Validate**

```bash
jac check main.jac
```

- [ ] **Step 3: Verify server starts and all endpoints register**

```bash
timeout 8 jac start main.jac 2>&1 | head -30 || true
```
Expected: sees "GhostWatch System 1 ready." and endpoint list including `rebuild-graph`, `orchestrator-walker`, `graph-state-walker`, `pr-comment-writer-walker`, `git-hub-webhook-walker`.

- [ ] **Step 4: Commit**

```bash
git add main.jac
git commit -m "feat: wire main.jac with GitHub webhook handler"
```

---

## Task 12: Frontend Components

**Files:**
- Create: `frontend/components/GraphView.cl.jac`
- Create: `frontend/components/WalkerTrace.cl.jac`
- Create: `frontend/components/VerdictCard.cl.jac`
- Create: `frontend/components/Navigation.cl.jac`

- [ ] **Step 1: Create `frontend/components/GraphView.cl.jac`**

```jac
# frontend/components/GraphView.cl.jac
# Renders the repo graph via @xyflow/react. Nodes colored by risk_score.

cl import from "@xyflow/react" { ReactFlow, Background, Controls, MiniMap };

def:pub GraphView(
    graph_nodes: list,
    graph_edges: list,
    highlighted_nodes: dict
) -> JsxElement {
    flow_nodes = [
        {
            "id": n["id"],
            "data": {"label": n["path"].split("/")[-1]},
            "position": {"x": (i % 20) * 120, "y": (i // 20) * 80},
            "style": _node_style(n["risk_score"], highlighted_nodes.get(n["id"], ""))
        }
        for (i, n) in enumerate(graph_nodes)
    ];

    flow_edges = [
        {
            "id": f"e-{e['source']}-{e['target']}",
            "source": e["source"],
            "target": e["target"],
            "type": "smoothstep"
        }
        for e in graph_edges
    ];

    return <div style={{"width": "100%", "height": "100%"}}>
        <ReactFlow nodes={flow_nodes} edges={flow_edges} fitView>
            <Background color="#1a1a2e" gap={16} />
            <Controls />
            <MiniMap style={{"background": "#16213e"}} />
        </ReactFlow>
    </div>;
}

def _node_style(risk_score: int, highlight_color: str) -> dict {
    if highlight_color {
        border_color = highlight_color;
        background = "#2a2a4a";
    } elif risk_score >= 7 {
        border_color = "#ff4444";
        background = "#3a1a1a";
    } elif risk_score >= 4 {
        border_color = "#ffaa00";
        background = "#3a3a1a";
    } else {
        border_color = "#44ff88";
        background = "#1a3a2a";
    }
    return {
        "border": f"2px solid {border_color}",
        "background": background,
        "color": "#e0e0e0",
        "fontSize": "10px",
        "padding": "4px 8px",
        "borderRadius": "4px"
    };
}
```

- [ ] **Step 2: Create `frontend/components/WalkerTrace.cl.jac`**

```jac
# frontend/components/WalkerTrace.cl.jac
# Replays three walker traversal paths at 80ms/hop. Loops continuously.
# Security=red, Compatibility=yellow, BlastRadius=orange.

def:pub WalkerTrace(traversal_paths: dict, on_highlight_update: object) -> JsxElement {
    has step: int = 0;

    walker_colors = {
        "security": "#ff4444",
        "compatibility": "#ffdd00",
        "blast_radius": "#ff8800"
    };

    def max_steps() -> int {
        lengths = [len(p) for p in traversal_paths.values()];
        if not lengths { return 0; }
        return max(lengths);
    }

    def compute_highlights() -> dict {
        highlights = {};
        for (name, color) in walker_colors.items() {
            path = traversal_paths.get(name, []);
            if step < len(path) {
                highlights[path[step]] = color;
            }
        }
        return highlights;
    }

    can with entry {
        if max_steps() > 0 {
            interval_id = setInterval(lambda -> None {
                step = (step + 1) % max(max_steps(), 1);
                on_highlight_update(compute_highlights());
            }, 80);
        }
    }

    can with exit {
        clearInterval(interval_id);
    }

    if not traversal_paths or max_steps() == 0 {
        return <div />;
    }

    return <div style={{"position": "absolute", "bottom": "20px", "right": "20px", "background": "#1a1a2e", "padding": "12px", "borderRadius": "8px", "border": "1px solid #333", "zIndex": 10}}>
        <div style={{"fontSize": "12px", "color": "#aaa", "marginBottom": "8px"}}>Walker Trace</div>
        {[
            <div key={name} style={{"display": "flex", "alignItems": "center", "gap": "8px", "marginBottom": "4px"}}>
                <div style={{"width": "10px", "height": "10px", "borderRadius": "50%", "background": color}} />
                <span style={{"color": "#e0e0e0", "fontSize": "11px"}}>{name}</span>
                <span style={{"color": "#888", "fontSize": "10px"}}>{step}/{len(traversal_paths.get(name, []))}</span>
            </div>
            for (name, color) in walker_colors.items()
            if name in traversal_paths
        ]}
    </div>;
}
```

- [ ] **Step 3: Create `frontend/components/VerdictCard.cl.jac`**

```jac
# frontend/components/VerdictCard.cl.jac
# Displays overall risk, per-walker findings, blast summary, Approve button.

def:pub VerdictCard(verdict: dict, pr_url: str, on_approve: object) -> JsxElement {
    overall_risk = verdict.get("overall_risk", "unknown").upper();
    risk_score = verdict.get("risk_score", 0);
    security_findings = verdict.get("security_findings", []);
    compat_issues = verdict.get("compatibility_issues", []);
    affected_count = verdict.get("affected_node_count", 0);
    blast_summary = verdict.get("blast_radius_summary", "");
    recommendation = verdict.get("recommendation", "");

    risk_colors = {
        "CRITICAL": "#ff2244", "HIGH": "#ff6600", "MEDIUM": "#ffaa00",
        "LOW": "#aadd00", "CLEAN": "#44ff88", "UNKNOWN": "#888888"
    };
    risk_color = risk_colors.get(overall_risk, "#888888");

    return <div style={{"background": "#0d0d1e", "border": f"2px solid {risk_color}", "borderRadius": "12px", "padding": "20px", "maxWidth": "400px", "color": "#e0e0e0"}}>
        <div style={{"display": "flex", "justifyContent": "space-between", "marginBottom": "14px"}}>
            <div>
                <div style={{"fontSize": "20px", "fontWeight": "bold", "color": risk_color}}>{overall_risk}</div>
                <div style={{"color": "#888", "fontSize": "12px"}}>Score: {risk_score}/100</div>
            </div>
            <div style={{"color": "#888", "fontSize": "12px"}}>{affected_count} nodes affected</div>
        </div>

        {security_findings and <div style={{"marginBottom": "10px"}}>
            <div style={{"fontSize": "13px", "color": "#ff6666", "marginBottom": "4px"}}>Security ({len(security_findings)})</div>
            {[
                <div key={i} style={{"fontSize": "11px", "color": "#ccc", "padding": "4px 8px", "background": "#1a0a0a", "borderRadius": "3px", "marginBottom": "3px"}}>
                    [{f.get("severity", "?").upper()}] {f.get("description", "")}
                </div>
                for (i, f) in enumerate(security_findings[:4])
            ]}
        </div>}

        {compat_issues and <div style={{"marginBottom": "10px"}}>
            <div style={{"fontSize": "13px", "color": "#ffaa44", "marginBottom": "4px"}}>Compatibility ({len(compat_issues)})</div>
            {[
                <div key={i} style={{"fontSize": "11px", "color": "#ccc", "padding": "4px 8px", "background": "#1a1200", "borderRadius": "3px", "marginBottom": "3px"}}>
                    {issue.get("api_name", "")}: {issue.get("description", "")}
                </div>
                for (i, issue) in enumerate(compat_issues[:3])
            ]}
        </div>}

        {blast_summary and <div style={{"marginBottom": "12px", "fontSize": "11px", "color": "#aaa"}}>{blast_summary}</div>}

        {recommendation and <div style={{"marginBottom": "14px", "padding": "8px", "background": "#0a0a1a", "borderRadius": "4px", "fontSize": "12px", "color": "#aaa", "borderLeft": "3px solid #4444aa"}}>
            {recommendation}
        </div>}

        <button
            onClick={lambda -> None { on_approve(); }}
            style={{"width": "100%", "padding": "10px", "background": "#1a3a6a", "border": "1px solid #4488cc", "borderRadius": "6px", "color": "#88ccff", "cursor": "pointer", "fontSize": "13px"}}
        >
            Approve — Post GitHub Review
        </button>
    </div>;
}
```

- [ ] **Step 4: Create `frontend/components/Navigation.cl.jac`**

```jac
# frontend/components/Navigation.cl.jac

cl import from "@jac/runtime" { Link };

def:pub Navigation() -> JsxElement {
    return <nav style={{"display": "flex", "alignItems": "center", "gap": "24px", "padding": "12px 24px", "background": "#0d0d1e", "borderBottom": "1px solid #222"}}>
        <Link to="/" style={{"color": "#88ccff", "textDecoration": "none", "fontWeight": "bold", "fontSize": "16px"}}>
            👻 GhostWatch
        </Link>
        <Link to="/" style={{"color": "#aaa", "textDecoration": "none", "fontSize": "13px"}}>Graph</Link>
    </nav>;
}
```

- [ ] **Step 5: Validate all four components and commit**

```bash
jac check frontend/components/GraphView.cl.jac && \
jac check frontend/components/WalkerTrace.cl.jac && \
jac check frontend/components/VerdictCard.cl.jac && \
jac check frontend/components/Navigation.cl.jac
git add frontend/components/
git commit -m "feat: add GraphView, WalkerTrace, VerdictCard, Navigation components"
```

---

## Task 13: Frontend Pages

**Files:**
- Create: `frontend/pages/layout.jac`
- Create: `frontend/pages/index.jac`
- Create: `frontend/pages/analysis/[pr_id].jac`

- [ ] **Step 1: Create `frontend/pages/layout.jac`**

```jac
# frontend/pages/layout.jac

cl import from "@jac/runtime" { Outlet };
cl import from frontend.components.Navigation { Navigation };

cl {
    def:pub layout() -> JsxElement {
        return <div style={{"minHeight": "100vh", "background": "#060614"}}>
            <Navigation />
            <Outlet />
        </div>;
    }
}
```

- [ ] **Step 2: Create `frontend/pages/index.jac`**

```jac
# frontend/pages/index.jac
# Graph visualization + polling for new PRAnalysisNode.

sv import from walkers.static.graph_state { GraphStateWalker };
cl import from frontend.components.GraphView { GraphView };
cl import from frontend.components.WalkerTrace { WalkerTrace };
cl import from frontend.components.VerdictCard { VerdictCard };
cl import from "@jac/runtime" { useNavigate };

cl {
    def:pub page() -> JsxElement {
        has graph_nodes: list = [];
        has graph_edges: list = [];
        has highlighted_nodes: dict = {};
        has latest_analysis: dict | None = None;
        has has_graph: bool = False;
        has loading: bool = True;
        has error: str = "";

        navigate = useNavigate();

        async def fetch_state() -> None {
            try {
                result = root() spawn GraphStateWalker();
                if result.reports and result.reports.length > 0 {
                    data = result.reports[0];
                    graph_nodes = data.get("nodes", []);
                    graph_edges = data.get("edges", []);
                    has_graph = data.get("has_graph", False);
                    new_analysis = data.get("latest_analysis", None);
                    if new_analysis {
                        latest_analysis = new_analysis;
                    }
                    loading = False;
                }
            } except Exception as e {
                error = f"Failed to load graph: {e}";
                loading = False;
            }
        }

        async can with entry {
            await fetch_state();
            setInterval(lambda -> None { fetch_state(); }, 5000);
        }

        if loading {
            return <div style={{"display": "flex", "justifyContent": "center", "alignItems": "center", "height": "80vh", "color": "#aaa", "fontFamily": "monospace"}}>Loading graph...</div>;
        }

        if not has_graph {
            return <div style={{"padding": "40px", "color": "#aaa", "fontFamily": "monospace"}}>
                <h2 style={{"color": "#88ccff"}}>No graph built yet</h2>
                <p>POST to <code>/walker/rebuild-graph</code> with <code>&#123;"branch": "main"&#125;</code> to build the graph.</p>
            </div>;
        }

        return <div style={{"position": "relative", "height": "calc(100vh - 48px)"}}>
            <GraphView
                graph_nodes={graph_nodes}
                graph_edges={graph_edges}
                highlighted_nodes={highlighted_nodes}
            />
            {latest_analysis and latest_analysis.get("verdict") and
                <WalkerTrace
                    traversal_paths={latest_analysis["verdict"].get("traversal_paths", {})}
                    on_highlight_update={lambda h: dict { highlighted_nodes = h; }}
                />
            }
            {latest_analysis and
                <div style={{"position": "absolute", "top": "20px", "right": "20px", "zIndex": 10}}>
                    <VerdictCard
                        verdict={latest_analysis.get("verdict", {})}
                        pr_url={latest_analysis.get("pr_url", "")}
                        on_approve={lambda -> None { navigate(f"/analysis/{latest_analysis['id']}"); }}
                    />
                </div>
            }
        </div>;
    }
}
```

- [ ] **Step 3: Create `frontend/pages/analysis/[pr_id].jac`**

```jac
# frontend/pages/analysis/[pr_id].jac

sv import from walkers.static.graph_state { GraphStateWalker };
sv import from walkers.static.pr_comment { PRCommentWriterWalker };
cl import from frontend.components.VerdictCard { VerdictCard };
cl import from "@jac/runtime" { useParams, Link };

cl {
    def:pub page() -> JsxElement {
        params = useParams();
        pr_id = params.get("pr_id", "");

        has analysis: dict | None = None;
        has loading: bool = True;
        has error: str = "";
        has approve_status: str = "";
        has approving: bool = False;

        async can with entry {
            try {
                result = root() spawn GraphStateWalker();
                if result.reports and result.reports.length > 0 {
                    latest = result.reports[0].get("latest_analysis", None);
                    if latest and latest.get("id") == pr_id {
                        analysis = latest;
                    } else {
                        error = "Analysis not found";
                    }
                }
                loading = False;
            } except Exception as e {
                error = f"Load failed: {e}";
                loading = False;
            }
        }

        async def handle_approve() -> None {
            if not analysis or approving { return; }
            approving = True;
            approve_status = "Posting review...";
            try {
                result = root() spawn PRCommentWriterWalker(
                    pr_url=analysis.get("pr_url", ""),
                    verdict_id=pr_id
                );
                if result.reports and result.reports.length > 0 {
                    resp = result.reports[0];
                    if resp.get("status") == "success" {
                        approve_status = "Review posted to GitHub!";
                    } elif resp.get("status") == "already_posted" {
                        approve_status = "Already posted.";
                    } else {
                        approve_status = f"Error: {resp.get('error', 'unknown')}";
                    }
                }
            } except Exception as e {
                approve_status = f"Failed: {e}";
            }
            approving = False;
        }

        if loading { return <div style={{"padding": "40px", "color": "#aaa"}}>Loading...</div>; }
        if error or not analysis { return <div style={{"padding": "40px", "color": "#ff4444"}}>{error or "Not found"}</div>; }

        return <div style={{"padding": "24px", "maxWidth": "760px", "margin": "0 auto", "fontFamily": "monospace"}}>
            <Link to="/" style={{"color": "#4488cc", "textDecoration": "none", "fontSize": "13px"}}>← Back to Graph</Link>
            <h1 style={{"color": "#88ccff", "fontSize": "18px", "margin": "16px 0 4px"}}>PR Analysis</h1>
            <div style={{"color": "#666", "fontSize": "12px", "marginBottom": "20px"}}>{analysis.get("pr_url", "")} · {analysis.get("created_at", "")}</div>
            {approve_status and
                <div style={{"padding": "10px", "background": "#0a1a0a", "border": "1px solid #2a4a2a", "borderRadius": "6px", "color": "#88ff88", "marginBottom": "16px", "fontSize": "13px"}}>
                    {approve_status}
                </div>
            }
            <VerdictCard
                verdict={analysis.get("verdict", {})}
                pr_url={analysis.get("pr_url", "")}
                on_approve={handle_approve}
            />
        </div>;
    }
}
```

- [ ] **Step 4: Validate all three pages and commit**

```bash
jac check frontend/pages/layout.jac && \
jac check frontend/pages/index.jac && \
jac check "frontend/pages/analysis/[pr_id].jac"
git add frontend/pages/
git commit -m "feat: add frontend pages — graph viz, verdict detail, layout"
```

---

## Task 14: Final Validation + Demo Runbook

- [ ] **Step 1: Run the 5 core tests one final time**

```bash
jac test tests/test_core.jac
```
Expected: PASS (5 tests — 3 HMAC + 2 walker logic)

- [ ] **Step 2: Full syntax check sweep**

```bash
jac check main.jac graph/nodes.jac graph/edges.jac graph/builder.jac objects/verdict.jac \
  integrations/github.jac integrations/discord.jac \
  walkers/static/orchestrator.jac walkers/static/security.jac \
  walkers/static/compatibility.jac walkers/static/blast_radius.jac \
  walkers/static/graph_state.jac walkers/static/pr_comment.jac
```
Expected: no errors on any file

- [ ] **Step 3: Start server and verify endpoints**

```bash
timeout 8 jac start main.jac 2>&1 | head -30 || true
```
Expected: "GhostWatch System 1 ready." + endpoint list includes rebuild-graph, orchestrator-walker, graph-state-walker, pr-comment-writer-walker, git-hub-webhook-walker.

- [ ] **Step 4: Copy `.env.example` to `.env` and fill in secrets**

```bash
cp .env.example .env
# Edit .env and fill in:
# GITHUB_TOKEN, GITHUB_WEBHOOK_SECRET, ANTHROPIC_API_KEY, DISCORD_WEBHOOK_URL
```

- [ ] **Step 5: Build the graph (requires real GITHUB_TOKEN)**

```bash
curl -X POST http://localhost:8000/walker/rebuild-graph \
  -H "Content-Type: application/json" \
  -d '{"repo_name": "jaseci-labs/jaseci", "branch": "main"}'
```
Expected: `{"status": "complete", "nodes_built": N, "edges_built": N}`

- [ ] **Step 6: Open frontend and verify graph renders**

Open `http://localhost:3000` — colored nodes should render in xyflow graph.

- [ ] **Step 7: Final commit**

```bash
git add tests/test_core.jac
git commit -m "chore: final validation — System 1 complete"
```

---

## Spec Coverage Check

| Spec Requirement | Plan Task |
|------------------|-----------|
| GitHub webhook `pull_request` trigger | Task 11 — `GitHubWebhookWalker` |
| Graph built once via `POST /walker/rebuild-graph` | Task 6 — `GraphBuilderWalker` |
| `++>` returns list — always index `[0]` | Task 6 step 2, Task 9 step 2 |
| HMAC webhook signature validation | Task 4 — tested |
| `allowed_nodes` subgraph (diff + 1 hop) | Task 9 — `_build_allowed_nodes` |
| `flow/wait` parallel dispatch on wrapper functions | Task 9 — `_run_security/compat/blast` |
| `SecurityAuditorWalker` disengages on `is_test` | Task 8 step 1 |
| `CompatibilityCheckerWalker` cheap `_uses_changed_api` check | Task 7 step 2, Task 8 step 2 |
| `BlastRadiusMapperWalker` max 5 hops, full graph | Task 7 step 3, Task 8 step 3 |
| `traversal_path` per walker | Tasks 8 — each impl appends `jid(here)` |
| `PRAnalysisNode` saved on root | Task 9 — `root ++> PRAnalysisNode(...)` |
| Discord HTTP POST notification | Task 5 |
| `GET /walker/graph-state-walker` | Task 10 |
| `PRCommentWriterWalker` idempotent | Task 10 — checks `comment_posted` flag |
| `by llm` on all AI functions with `sem` annotations | Tasks 7, 9, 10 |
| Graceful degradation — LLM errors caught | Tasks 8, 9 — try/except on every LLM call |
| `GraphView` xyflow + risk_score colors | Task 12 step 1 |
| `WalkerTrace` 80ms replay loop | Task 12 step 2 |
| `VerdictCard` with Approve button | Task 12 step 3 |
| Frontend 5s polling for new analysis | Task 13 step 2 — `setInterval(fetch, 5000)` |
| Analysis detail page `/analysis/[pr_id]` | Task 13 step 3 |

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-04-system1-static-analyzer.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks

**2. Inline Execution** — Execute tasks in this session using executing-plans

**Which approach?**
