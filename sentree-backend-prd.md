# Sentree — Backend PRD
**Version 1.0 | JacHacks 2026**

---

## Backend Philosophy

Sentree has no traditional backend. There is no REST API layer, no separate database service, no microservices to orchestrate, and no infrastructure to manage. The entire backend is a running Jac graph with walkers as the compute layer. `jac start main.jac` is the backend. Persistence is automatic via Jac's root node. Scaling is `jac start main.jac --scale`.

Every function that touches AI is a `by llm()` call. Every function that traverses data is a walker. Every piece of data that needs to survive across invocations is a node or edge connected to root.

---

## Graph Persistence Model

Jac's root node is the single persistent anchor. Everything connected to root survives across server restarts, context windows, and deployments. Nothing else persists automatically.

```
root
├──> RepoGraphNode (the full codebase graph)
│       ├──> FileNode (each file in jaseci-labs/jaseci)
│       │       ├──> [ImportEdge] ──> FileNode (import relationships)
│       │       ├──> [FindingEdge] ──> FindingNode (walker findings)
│       │       ├──> TestNode (connected test files)
│       │       └──> DocumentationNode (connected docs)
│       └──> DependencyNode (manifest dependencies)
│               └──> [DependencyEdge] ──> FileNode (which files use this dep)
├──> PRAnalysisNode (one per analyzed PR — persists for audit trail)
│       ├──> VerdictNode (merged verdict object)
│       └──> [FindingEdge] ──> FindingNode (per-walker findings)
└──> GhostwatchIncidentNode (one per Ghostwatch detection)
        ├──> BehavioralTraceNode (E2B sandbox evidence)
        └──> FixPRNode (reference to the auto-fix PR)
```

No MongoDB schema to define. No ORM to configure. The graph is the database.

---

## Walker Endpoint Mapping

When `jac start main.jac` runs, every walker marked `def:pub` becomes an HTTP endpoint automatically. Sentree exposes the following:

```
POST /walker/trigger-pr-analysis
  Body: { "pr_url": "https://github.com/jaseci-labs/jaseci/pull/123" }
  Returns: VerdictObject
  Spawns: OrchestratorWalker → [SecurityAuditorWalker, CompatibilityCheckerWalker, BlastRadiusMapperWalker]

POST /walker/approve-review
  Body: { "verdict_id": "uuid", "pr_url": "string" }
  Returns: { "comments_posted": int, "status": "success" }
  Spawns: PRCommentWriterWalker

POST /walker/ghostwatch-push-event
  Body: { "commit_sha": "string", "repo": "string" }
  Returns: { "flagged_deps": list, "status": "string" }
  Spawns: DependencyDiffWalker → [SandboxExecutorWalker → FixGenerationWalker → AutoFixPRCreatorWalker]

POST /walker/post-merge-analysis
  Body: { "merge_commit_sha": "string" }
  Returns: { "gaps_found": int, "suggestions": list }
  Spawns: GapAnalysisWalker

GET /walker/graph-state
  Returns: { "nodes": list, "edges": list, "last_updated": string }
  Used by: jac-client frontend for live visualization

POST /walker/rebuild-graph
  Body: { "branch": "main" }
  Returns: { "nodes_built": int, "edges_built": int }
  Spawns: GraphBuilderWalker
```

All endpoints are auto-documented at `/docs` by `jac start`.

---

## GitHub Webhook Handler

Sentree listens for two GitHub webhook events. The webhook receiver is a Jac walker exposed as a public endpoint:

```jac
walker GitHubWebhookWalker {
    has event_type: str;
    has payload: dict;

    can handle with `root entry {
        if self.event_type == "push" {
            self._handle_push();
        } elif self.event_type == "pull_request" {
            if self.payload["action"] == "closed" 
            and self.payload["pull_request"]["merged"] {
                self._handle_merge();
            }
        }
    }

    can _handle_push() -> None {
        commit_sha = self.payload["after"];
        changed_files = [f["filename"] for f in self.payload["commits"][0]["added"] 
                        + self.payload["commits"][0]["modified"]];
        
        dep_files = ["package.json", "jac.toml", "requirements.txt", "pyproject.toml"];
        touched_deps = [f for f in changed_files if f in dep_files];
        
        if touched_deps {
            DependencyDiffWalker(commit_sha=commit_sha) spawn root;
        }
    }

    can _handle_merge() -> None {
        merge_sha = self.payload["pull_request"]["merge_commit_sha"];
        GapAnalysisWalker() spawn root;
    }
}
```

**GitHub webhook events to register:**
- `push` — fires Ghostwatch dependency monitoring
- `pull_request` (closed + merged) — fires post-merge gap analysis

**Webhook secret validation:**
```jac
can validate_github_signature(payload: bytes, signature: str) -> bool {
    import from hmac { new as hmac_new, compare_digest }
    import from hashlib { sha256 }
    expected = "sha256=" + hmac_new(
        env.GITHUB_WEBHOOK_SECRET.encode(),
        payload,
        sha256
    ).hexdigest();
    return compare_digest(expected, signature);
}
```

---

## Discord Bot Backend

The Discord bot runs as a persistent process launched within the Jac server's `with entry` block. All Discord interactions call back into Jac walkers:

```jac
import from discord { Client, Intents, app_commands, Interaction, ButtonStyle }
import from discord.ui { View, Button }

glob bot: Client = None;

with entry {
    intents = Intents.default();
    intents.message_content = True;
    global bot = Client(intents=intents);
    
    @bot.event
    async def on_ready() {
        await bot.tree.sync();
        print(f"Sentree online as {bot.user}");
    }
    
    bot.run(env.DISCORD_TOKEN);
}

# /trigger slash command
@bot.tree.command(name="trigger", description="Analyze a PR against the Jac graph")
@app_commands.describe(pr_url="GitHub PR URL to analyze")
async def trigger_cmd(interaction: Interaction, pr_url: str) {
    # Check role-based auth
    if not _has_permission(interaction.user, "contributor") {
        await interaction.response.send_message("Insufficient permissions.", ephemeral=True);
        return;
    }
    
    await interaction.response.defer();
    
    # Fire orchestrator — returns VerdictObject
    orchestrator = OrchestratorWalker(pr_url=pr_url);
    verdict = orchestrator spawn root;
    
    # Build Discord embed + action buttons
    embed = _build_verdict_embed(verdict);
    view = _build_action_view(verdict.verdict_id, pr_url);
    
    await interaction.followup.send(embed=embed, view=view);
}

# Approve button handler
can handle_approve_button(interaction: Interaction, verdict_id: str, pr_url: str) -> None {
    if not _has_permission(interaction.user, "admin") {
        await interaction.response.send_message("Only admins can approve reviews.", ephemeral=True);
        return;
    }
    
    # Post GitHub PR comments
    pr_writer = PRCommentWriterWalker(verdict_id=verdict_id, pr_url=pr_url);
    result = pr_writer spawn root;
    
    await interaction.response.send_message(
        f"✅ Review posted — {result['comments_posted']} inline comments added to PR.",
        ephemeral=True
    );
}

can _has_permission(user: any, level: str) -> bool {
    role_map = {
        "admin": env.DISCORD_ADMIN_ROLE_ID,
        "contributor": env.DISCORD_CONTRIBUTOR_ROLE_ID
    };
    required_role_id = role_map.get(level, "");
    return any(str(role.id) == required_role_id for role in user.roles);
}
```

---

## Backboard Memory Backend

Each walker type maintains a dedicated Backboard assistant. Memory is stored and queried at walker initialization time:

```jac
import from backboard { BackboardClient }

glob bb: BackboardClient = BackboardClient(api_key=env.BACKBOARD_API_KEY);

# Called at the start of each SecurityAuditorWalker invocation
can load_security_memory(repo: str, file_path: str) -> str {
    thread = bb.get_or_create_thread(
        assistant_id=f"sentree-security-{repo.replace('/', '-')}",
        thread_id=f"security-{file_path.replace('/', '-')}"
    );
    return bb.recall(
        thread_id=thread.id,
        query=f"Previous security findings for {file_path}"
    );
}

# Called after each walker completes
can store_walker_finding(
    walker_type: str,
    repo: str,
    pr_url: str,
    finding: dict
) -> None {
    bb.store(
        assistant_id=f"sentree-{walker_type}-{repo.replace('/', '-')}",
        content=f"PR: {pr_url} | {finding}"
    );
}
```

---

## E2B Sandbox Backend

The sandbox executor is wrapped to ensure clean resource management. Each sandbox is independent and destroyed after use:

```jac
import from e2b_code_interpreter { Sandbox }
import from contextlib { asynccontextmanager }

can execute_in_sandbox(install_command: str, timeout: int = 30) -> SandboxResult {
    with Sandbox() as sandbox {
        # Configure network monitoring
        sandbox.run_code("""
import subprocess, json, socket, os
original_connect = socket.socket.connect
network_calls = []

def monitored_connect(self, address):
    network_calls.append(str(address))
    return original_connect(self, address)

socket.socket.connect = monitored_connect
""");
        
        result = sandbox.run_code(install_command, timeout=timeout);
        network_log = sandbox.run_code("print(json.dumps(network_calls))");
        
        return SandboxResult(
            stdout=result.logs.stdout,
            stderr=result.logs.stderr,
            exit_code=result.exit_code,
            network_connections=json.loads(network_log.text or "[]")
        );
    }
    # Sandbox automatically destroyed on context exit
}

obj SandboxResult {
    has stdout: str;
    has stderr: str;
    has exit_code: int;
    has network_connections: list[str];
}
```

---

## GitHub PR Creation Backend

```jac
import from github { Github, GithubException }

can create_ghostwatch_pr(
    fix_branch: str,
    malicious_dep: str,
    behavioral_trace: BehavioralTrace,
    offending_commit: str
) -> str {
    g = Github(env.GITHUB_TOKEN);
    repo = g.get_repo("jaseci-labs/jaseci");
    
    pr_body = _build_pr_body(malicious_dep, behavioral_trace, offending_commit);
    
    try {
        pr = repo.create_pull(
            title=f"🚨 GHOSTWATCH: Remove malicious dependency {malicious_dep}",
            body=pr_body,
            head=fix_branch,
            base="main",
            draft=False
        );
        
        # Add labels
        repo.get_label("security").apply_to_issue(pr);
        repo.get_label("ghostwatch").apply_to_issue(pr);
        
        return pr.html_url;
    } except GithubException as e {
        report { "error": f"PR creation failed: {e}" };
        return "";
    }
}

can _build_pr_body(
    malicious_dep: str,
    trace: BehavioralTrace,
    commit: str
) -> str by llm();
```

---

## Escalation Notifier Backend

```jac
can send_ghostwatch_alert(
    repo: str,
    malicious_dep: str,
    trace: BehavioralTrace,
    pr_url: str,
    committer_github: str
) -> None {
    import from discord { Webhook, Embed, Color }
    
    # Look up Discord user ID from GitHub username
    committer_discord_id = _resolve_discord_id(committer_github);
    owner_discord_id = env.REPO_OWNER_DISCORD_ID;
    
    embed = Embed(
        title="🚨 GHOSTWATCH ALERT — Malicious Dependency Detected",
        color=Color.red()
    );
    embed.add_field(name="Repository", value=repo, inline=True);
    embed.add_field(name="Malicious Package", value=malicious_dep, inline=True);
    embed.add_field(
        name="Behavioral Evidence",
        value=trace.evidence_summary,
        inline=False
    );
    embed.add_field(
        name="Network Connections",
        value="\n".join(trace.network_connections) or "None",
        inline=False
    );
    embed.add_field(name="Fix PR", value=pr_url, inline=False);
    
    # Send to maintainer channel with mentions
    channel = bot.get_channel(int(env.DISCORD_SECURITY_CHANNEL_ID));
    await channel.send(
        content=f"<@{owner_discord_id}> <@{committer_discord_id}> — Immediate action required",
        embed=embed
    );
    
    # Schedule re-ping after 2 hours if no merge
    _schedule_escalation(pr_url, 7200);
}

can _schedule_escalation(pr_url: str, delay_seconds: int) -> None {
    import from asyncio { sleep, create_task }
    
    async def escalate() {
        await sleep(delay_seconds);
        g = Github(env.GITHUB_TOKEN);
        pr = _get_pr_from_url(pr_url, g);
        if pr.state == "open" {
            channel = bot.get_channel(int(env.DISCORD_SECURITY_CHANNEL_ID));
            await channel.send(
                f"⚠️ **ESCALATION** — Ghostwatch fix PR still unmerged after 2 hours: {pr_url}"
            );
        }
    }
    
    create_task(escalate());
}

can _resolve_discord_id(github_username: str) -> str by llm();
```

---

## Live Graph Visualization Backend

The visualization is served by `jac-client` — a React frontend in the same `.jac` file. The backend provides one graph state endpoint polled by the frontend:

```jac
walker GraphStateWalker {

    can def:pub get_state with `root entry {
        nodes_data: list = [];
        edges_data: list = [];
        
        for node in [root-->][?:FileNode] {
            nodes_data.append({
                "id": node.id,
                "path": node.path,
                "risk_score": node.risk_score,
                "language": node.language,
                "is_test": node.is_test
            });
        }
        
        for edge in [root-->>] {
            edges_data.append({
                "source": edge.source.id,
                "target": edge.target.id,
                "type": edge.__class__.__name__
            });
        }
        
        report {
            "nodes": nodes_data,
            "edges": edges_data,
            "node_count": len(nodes_data),
            "edge_count": len(edges_data),
            "last_updated": _get_last_update_time()
        };
    }
}

# jac-client frontend in same file
cl {
    import from react { useState, useEffect } 
    import from "@xyflow/react" { ReactFlow, Background, Controls }
    
    cl def:pub app() -> JsxElement {
        has graph_data: dict = {};
        has active_walkers: list = [];
        
        async can with entry {
            graph_data = await GraphStateWalker();
        }
        
        return <div style={{ width: "100vw", height: "100vh" }}>
            <ReactFlow
                nodes={graph_data.nodes}
                edges={graph_data.edges}
                fitView
            >
                <Background />
                <Controls />
            </ReactFlow>
        </div>;
    }
}
```

---

## Error Handling Strategy

```jac
# Walker-level error handling — findings degrade gracefully
can safe_llm_call(fn: callable, fallback: any) -> any {
    try {
        return fn();
    } except Exception as e {
        print(f"LLM call failed: {e}");
        return fallback;
    }
}

# Sandbox failures — surface as findings, never crash the pipeline
can safe_sandbox_execute(dep: SuspiciousDependency) -> SandboxResult {
    try {
        return execute_in_sandbox(f"npm install {dep.name}@{dep.version}");
    } except Exception as e {
        return SandboxResult(
            stdout="",
            stderr=str(e),
            exit_code=1,
            network_connections=[]
        );
    }
}

# GitHub API rate limiting — exponential backoff
can github_with_retry(fn: callable, max_retries: int = 3) -> any {
    import from time { sleep }
    for attempt in range(max_retries) {
        try {
            return fn();
        } except Exception as e {
            if "rate limit" in str(e).lower() {
                sleep(2 ** attempt);
            } else {
                raise e;
            }
        }
    }
}
```

---

## Environment Configuration

```
# Required
GITHUB_TOKEN=ghp_...
ANTHROPIC_API_KEY=sk-ant-...
DISCORD_TOKEN=...
BACKBOARD_API_KEY=...
E2B_API_KEY=...

# Discord role/channel IDs
DISCORD_ADMIN_ROLE_ID=...
DISCORD_CONTRIBUTOR_ROLE_ID=...
DISCORD_SECURITY_CHANNEL_ID=...
REPO_OWNER_DISCORD_ID=...

# GitHub
GITHUB_WEBHOOK_SECRET=...
TARGET_REPO=jaseci-labs/jaseci

# Optional
JAC_PROFILE=production
```

---

## Deployment Commands

```bash
# Development
jac start main.jac

# Production — one command, full Kubernetes stack
jac start main.jac --scale

# Auto-provisioned by --scale:
# ✓ Kubernetes deployment
# ✓ MongoDB for graph persistence
# ✓ Redis for session/cache
# ✓ JWT authentication
# ✓ Swagger API docs at /docs
# ✓ Auto-scaling on load
# ✓ Health check endpoints
```
