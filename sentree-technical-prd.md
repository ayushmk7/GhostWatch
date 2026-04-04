# Sentree — Technical PRD
**Version 1.0 | JacHacks 2026**

---

## Architecture Overview

Sentree is a single Jac application — one `.jac` file serving backend logic, frontend visualization, and AI agent orchestration. Jac's codespace system (`sv` for server, `cl` for client) eliminates the need for a separate frontend project. All Python libraries (PyGithub, discord.py, e2b, backboard) are imported directly into Jac using its native Python interop.

```
sentree/
├── main.jac              # Entry point — jac start main.jac
├── jac.toml              # Project config, dependencies, model config
├── .env                  # GITHUB_TOKEN, ANTHROPIC_API_KEY, 
│                         # DISCORD_TOKEN, BACKBOARD_API_KEY, E2B_API_KEY
├── graph/
│   ├── nodes.jac         # FileNode, DependencyNode, FindingNode
│   ├── edges.jac         # ImportEdge, DependencyEdge, FindingEdge
│   └── builder.jac       # Repo → graph construction walker
├── walkers/
│   ├── static/
│   │   ├── security.jac          # Security Auditor Walker
│   │   ├── compatibility.jac     # Compatibility Checker Walker
│   │   └── blast_radius.jac      # Blast Radius Mapper Walker
│   ├── ghostwatch/
│   │   ├── dep_diff.jac          # Dependency Diff Walker
│   │   ├── sandbox.jac           # E2B Sandbox Executor Walker
│   │   ├── gap_analysis.jac      # Post-Merge Gap Analysis Walker
│   │   ├── fix_gen.jac           # Fix Generation Walker
│   │   └── pr_creator.jac        # Auto-Fix PR Creator Walker
│   └── orchestrator.jac          # flow/wait parallel dispatch
├── integrations/
│   ├── github.jac        # PyGithub wrapper — diff, PR, comment, push
│   ├── discord.jac       # discord.py wrapper — bot, embeds, buttons
│   └── backboard.jac     # Backboard memory client per walker
└── frontend/
    └── graph_viz.jac     # jac-client visualization component
```

---

## Jac Graph Data Model

### Nodes

```jac
node FileNode {
    has path: str
        sem="relative file path from repo root";
    has content: str
        sem="full source content of the file";
    has language: str
        sem="programming language: jac, python, js, json, toml";
    has risk_score: int = 0
        sem="0-10 security risk rating, higher means more dangerous";
    has last_modified: str
        sem="ISO timestamp of last git commit touching this file";
    has is_test: bool = False
        sem="true if this file is a test file";
    has is_documented: bool = False
        sem="true if a documentation node is connected to this node";
}

node DependencyNode {
    has name: str
        sem="package name as it appears in the manifest";
    has version: str
        sem="version string declared in manifest";
    has publish_date: str
        sem="ISO date the package version was published to registry";
    has has_postinstall: bool = False
        sem="true if package.json declares a postinstall lifecycle hook";
    has is_imported: bool = False
        sem="true if this package is actually imported in source code";
    has behavioral_trace: str = ""
        sem="E2B sandbox execution trace — network calls, file writes, process spawns";
    has is_malicious: bool = False
        sem="true if sandbox execution detected malicious behavior";
}

node FindingNode {
    has walker_type: str
        sem="which walker produced this: security, compatibility, blast_radius";
    has severity: str
        sem="critical, high, medium, low, info";
    has description: str
        sem="human-readable finding description";
    has evidence: str
        sem="specific code snippet or graph path that produced this finding";
    has line_number: int = 0
        sem="line number in source file, 0 if not applicable";
}

node DocumentationNode {
    has content: str
        sem="documentation text for the connected code node";
}

node TestNode {
    has test_path: str
        sem="path to the test file";
    has coverage_type: str
        sem="unit, integration, e2e";
}
```

### Edges

```jac
edge ImportEdge {
    has is_direct: bool = True
        sem="true if direct import, false if transitive";
    has import_type: str
        sem="static, dynamic, conditional";
}

edge DependencyEdge {
    has declared_in: str
        sem="which manifest file declared this dependency";
    has is_runtime: bool = True
        sem="true if runtime dependency, false if dev dependency";
}

edge FindingEdge {
    has confidence: float = 1.0
        sem="0.0-1.0 confidence score for this finding";
    has walker_id: str
        sem="unique ID of the walker instance that created this edge";
}

edge BlastEdge {
    has hops: int = 1
        sem="number of graph hops from the changed node to this node";
    has impact_type: str
        sem="direct, transitive, type-level, runtime";
}
```

---

## Walker Specifications

### System 1 — Static Analyzer Walkers

#### GraphBuilderWalker

```jac
walker GraphBuilderWalker {
    has repo_url: str;
    has branch: str = "main";
    has file_count: int = 0;
    has edge_count: int = 0;

    can build with `root entry {
        # PyGithub import
        import from github { Github }
        g = Github(env.GITHUB_TOKEN);
        repo = g.get_repo(self.repo_url);
        
        # Traverse repo file tree
        contents = repo.get_contents("", ref=self.branch);
        self._process_contents(contents, repo);
        
        report {
            "nodes_built": self.file_count,
            "edges_built": self.edge_count,
            "status": "complete"
        };
    }
    
    can _process_contents(contents: list, repo: any) -> None {
        for item in contents {
            if item.type == "dir" {
                self._process_contents(repo.get_contents(item.path), repo);
            } elif item.name.endswith((".jac", ".py", ".json", ".toml")) {
                node = FileNode(
                    path=item.path,
                    content=item.decoded_content.decode("utf-8"),
                    language=self._detect_language(item.name)
                );
                root ++> node;
                self.file_count += 1;
                self._build_import_edges(node);
            }
        }
    }
    
    can _build_import_edges(file_node: FileNode) -> None {
        # Python ast for .py files, custom parser for .jac
        import from ast { parse, walk, Import, ImportFrom }
        # Build ImportEdge connections between FileNodes
        ...
    }
    
    can _detect_language(filename: str) -> str by llm();
}
```

#### SecurityAuditorWalker

```jac
walker SecurityAuditorWalker {
    has findings: list[dict] = [];
    has pr_context: str = "";

    can analyze with FileNode entry {
        incl_info(here);
        incl_info(self);
        self.findings += self.audit_file(
            content=here.content,
            path=here.path,
            pr_context=self.pr_context
        );
        visit [-->];
    }

    can audit_file(
        content: str
            sem="full source code of the file being analyzed",
        path: str
            sem="file path for context on what kind of file this is",
        pr_context: str
            sem="the PR diff context showing what changed"
    ) -> list[SecurityFinding] by llm();

    can disengage with TestNode entry {
        disengage;
    }
}

obj SecurityFinding {
    has severity: str
        sem="critical, high, medium, low";
    has description: str
        sem="concise description of the security issue found";
    has line_number: int
        sem="line where the issue occurs, 0 if not line-specific";
    has evidence: str
        sem="exact code snippet demonstrating the issue";
    has recommendation: str
        sem="specific fix recommendation";
}
```

#### CompatibilityCheckerWalker

```jac
walker CompatibilityCheckerWalker {
    has findings: list[dict] = [];
    has changed_apis: list[str] = [];
    has pr_diff: str = "";

    can check_api_surface with FileNode entry {
        incl_info(here);
        # Check if this node uses any of the changed APIs
        if self._uses_changed_api(here.content) {
            self.findings += self.check_compatibility(
                file_content=here.content,
                changed_apis=self.changed_apis,
                file_path=here.path
            );
        }
        visit [-->];
    }

    can check_compatibility(
        file_content: str
            sem="source content of the file using the changed API",
        changed_apis: list[str]
            sem="list of API surfaces modified in the PR",
        file_path: str
            sem="path of the file for context"
    ) -> list[CompatibilityIssue] by llm();

    can _uses_changed_api(content: str) -> bool by llm();
}

obj CompatibilityIssue {
    has api_name: str
        sem="name of the API that has a compatibility issue";
    has issue_type: str
        sem="breaking_change, deprecation, interface_mismatch, type_change";
    has description: str
        sem="what the compatibility issue is";
    has affected_callers: list[str]
        sem="list of file paths that call this API and will be affected";
}
```

#### BlastRadiusMapperWalker

```jac
walker BlastRadiusMapperWalker {
    has changed_nodes: list[str] = [];
    has affected_nodes: list[str] = [];
    has max_hops: int = 5;
    has current_hop: int = 0;
    has risk_score: int = 0;

    can map with FileNode entry {
        if here.path in self.changed_nodes or self.current_hop > 0 {
            if here.path not in self.affected_nodes {
                self.affected_nodes.append(here.path);
                self.risk_score += self._score_node(here);
                
                # Create BlastEdge with hop count
                blast_edge = BlastEdge(
                    hops=self.current_hop,
                    impact_type=self._classify_impact(here)
                );
                here ++> [blast_edge] ++> FindingNode(
                    walker_type="blast_radius",
                    severity=self._severity_from_hops(self.current_hop),
                    description=f"Affected at hop {self.current_hop}"
                );
            }
            if self.current_hop < self.max_hops {
                self.current_hop += 1;
                visit [-->];
            }
        }
    }

    can _score_node(node: FileNode) -> int by llm();
    can _classify_impact(node: FileNode) -> str by llm();
    
    can _severity_from_hops(hops: int) -> str {
        if hops == 0 { return "critical"; }
        elif hops == 1 { return "high"; }
        elif hops == 2 { return "medium"; }
        else { return "low"; }
    }
}
```

#### OrchestratorWalker

```jac
walker OrchestratorWalker {
    has pr_url: str;
    has verdict: dict = {};

    can orchestrate with `root entry {
        import from github { Github }
        
        # Extract PR diff and affected files
        g = Github(env.GITHUB_TOKEN);
        pr = self._parse_pr(self.pr_url, g);
        affected_nodes = self._build_subgraph(pr);
        
        # Spawn all three walkers concurrently
        security_walker = SecurityAuditorWalker(pr_context=pr.diff);
        compat_walker = CompatibilityCheckerWalker(
            changed_apis=self._extract_apis(pr),
            pr_diff=pr.diff
        );
        blast_walker = BlastRadiusMapperWalker(
            changed_nodes=affected_nodes
        );
        
        # flow/wait — true parallelism
        security_future = flow security_walker spawn affected_nodes[0];
        compat_future = flow compat_walker spawn affected_nodes[0];
        blast_future = flow blast_walker spawn affected_nodes[0];
        
        security_result = wait security_future;
        compat_result = wait compat_future;
        blast_result = wait blast_future;
        
        self.verdict = self._merge_findings(
            security_result,
            compat_result,
            blast_result
        );
        
        report self.verdict;
    }
    
    can _merge_findings(
        security: list,
        compat: list,
        blast: dict
    ) -> VerdictObject by llm();
}

obj VerdictObject {
    has overall_risk: str
        sem="critical, high, medium, low, clean";
    has risk_score: int
        sem="0-100 numeric risk score";
    has security_findings: list[SecurityFinding];
    has compatibility_issues: list[CompatibilityIssue];
    has affected_node_count: int;
    has blast_radius_summary: str;
    has recommendation: str
        sem="one sentence recommendation for the maintainer";
}
```

---

### System 2 — Ghostwatch Walkers

#### DependencyDiffWalker

```jac
walker DependencyDiffWalker {
    has commit_sha: str;
    has flagged_deps: list[str] = [];

    can watch with `root entry {
        import from github { Github }
        g = Github(env.GITHUB_TOKEN);
        
        commit = g.get_repo("jaseci-labs/jaseci").get_commit(self.commit_sha);
        
        for file in commit.files {
            if file.filename in ["package.json", "jac.toml", "requirements.txt"] {
                self.flagged_deps += self.analyze_manifest_diff(
                    old_content=file.previous_content,
                    new_content=file.patch,
                    import_graph=self._get_import_nodes()
                );
            }
        }
        
        if self.flagged_deps {
            # Trigger sandbox executor
            sandbox_walker = SandboxExecutorWalker(
                deps_to_test=self.flagged_deps
            );
            sandbox_walker spawn root;
        }
        
        report { "flagged": self.flagged_deps };
    }

    can analyze_manifest_diff(
        old_content: str
            sem="the manifest content before this commit",
        new_content: str
            sem="the manifest content after this commit",
        import_graph: list[str]
            sem="list of all packages actually imported in the codebase"
    ) -> list[SuspiciousDependency] by llm();
    
    can _get_import_nodes() -> list[str] {
        return [node.path for node in [root-->][?:DependencyNode][?is_imported == True]];
    }
}

obj SuspiciousDependency {
    has name: str;
    has version: str;
    has reason: str
        sem="why this dependency is suspicious: phantom_import, new_postinstall, young_package, no_provenance";
    has risk_level: str
        sem="critical, high, medium";
}
```

#### SandboxExecutorWalker

```jac
walker SandboxExecutorWalker {
    has deps_to_test: list[SuspiciousDependency] = [];
    has malicious_findings: list[dict] = [];

    can execute with `root entry {
        import from e2b_code_interpreter { Sandbox }
        
        for dep in self.deps_to_test {
            with Sandbox() as sandbox {
                # Install only the flagged dependency in isolation
                result = sandbox.run_code(f"""
import subprocess
import json

proc = subprocess.Popen(
    ["npm", "install", "--ignore-scripts=false", 
     f"{dep.name}@{dep.version}"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)
stdout, stderr = proc.communicate(timeout=30)
print(json.dumps({
    "stdout": stdout.decode(),
    "stderr": stderr.decode(),
    "exit_code": proc.returncode
}))
""");
                
                behavioral_trace = self.analyze_behavior(
                    dep_name=dep.name,
                    execution_output=result.logs.stdout,
                    execution_errors=result.logs.stderr
                );
                
                if behavioral_trace.is_malicious {
                    self.malicious_findings.append({
                        "dep": dep,
                        "trace": behavioral_trace
                    });
                }
            }
            # Sandbox destroyed after each dep — no contamination
        }
        
        if self.malicious_findings {
            fix_walker = FixGenerationWalker(
                malicious_findings=self.malicious_findings
            );
            fix_walker spawn root;
        }
    }

    can analyze_behavior(
        dep_name: str
            sem="name of the dependency being analyzed",
        execution_output: str
            sem="stdout from the sandbox execution including any network calls or file writes",
        execution_errors: str
            sem="stderr from the sandbox execution"
    ) -> BehavioralTrace by llm();
}

obj BehavioralTrace {
    has is_malicious: bool;
    has network_connections: list[str]
        sem="list of outbound network connections attempted during install";
    has file_writes: list[str]
        sem="list of file system paths written to outside workspace";
    has process_spawns: list[str]
        sem="list of child processes spawned";
    has credential_access: list[str]
        sem="list of credential file paths accessed";
    has self_deletion: bool
        sem="true if the package deleted its own files after execution";
    has malware_family: str
        sem="identified malware family if known, empty string if unknown";
    has iocs: list[str]
        sem="indicators of compromise: domains, hashes, file paths";
    has evidence_summary: str
        sem="one paragraph summary of what the malicious code did";
}
```

#### FixGenerationWalker

```jac
walker FixGenerationWalker {
    has malicious_findings: list[dict] = [];
    has fix_branch: str = "";
    has fix_applied: bool = False;

    can fix with `root entry {
        import from github { Github }
        import from e2b_code_interpreter { Sandbox }
        
        g = Github(env.GITHUB_TOKEN);
        repo = g.get_repo("jaseci-labs/jaseci");
        
        # Generate corrected manifests
        fixed_manifests = self.generate_fix(
            malicious_findings=self.malicious_findings
        );
        
        # Validate fix in second sandbox
        fix_valid = self._validate_fix(fixed_manifests);
        
        if fix_valid {
            import from datetime { datetime }
            dep_name = self.malicious_findings[0]["dep"].name;
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S");
            self.fix_branch = f"ghostwatch/auto-fix-{dep_name}-{timestamp}";
            
            # Commit fix to branch
            main_sha = repo.get_branch("main").commit.sha;
            repo.create_git_ref(
                ref=f"refs/heads/{self.fix_branch}",
                sha=main_sha
            );
            
            for manifest_path, fixed_content in fixed_manifests.items() {
                current_file = repo.get_contents(manifest_path, ref="main");
                repo.update_file(
                    path=manifest_path,
                    message=f"ghostwatch: remove malicious dependency {dep_name}",
                    content=fixed_content,
                    sha=current_file.sha,
                    branch=self.fix_branch
                );
            }
            
            self.fix_applied = True;
        }
        
        report {
            "fix_applied": self.fix_applied,
            "branch": self.fix_branch,
            "findings": self.malicious_findings
        };
    }

    can generate_fix(
        malicious_findings: list[dict]
            sem="list of malicious dependency findings with package names and versions"
    ) -> dict[str, str] by llm();
    
    can _validate_fix(fixed_manifests: dict) -> bool {
        import from e2b_code_interpreter { Sandbox }
        with Sandbox() as sandbox {
            # Run npm install with fixed manifest and verify no malicious behavior
            result = sandbox.run_code(
                self._build_validation_script(fixed_manifests)
            );
            return "VALIDATION_PASSED" in result.logs.stdout;
        }
    }
    
    can _build_validation_script(manifests: dict) -> str by llm();
}
```

#### GapAnalysisWalker

```jac
walker GapAnalysisWalker {
    has gaps: list[dict] = [];

    can analyze with FileNode entry {
        incl_info(here);
        
        # Check for missing test node
        has_tests = len([here-->][?:TestNode]) > 0;
        has_docs = len([here-->][?:DocumentationNode]) > 0;
        
        if not has_tests and not here.is_test {
            self.gaps.append(self.generate_test_suggestion(
                file_path=here.path,
                file_content=here.content
            ));
        }
        
        if not has_docs and here.language == "jac" {
            self.gaps.append(self.generate_doc_suggestion(
                file_path=here.path,
                file_content=here.content
            ));
        }
        
        visit [-->];
    }

    can generate_test_suggestion(
        file_path: str
            sem="path of the file missing tests",
        file_content: str
            sem="source content to understand what needs testing"
    ) -> ContributorSuggestion by llm();

    can generate_doc_suggestion(
        file_path: str
            sem="path of the Jac file missing documentation",
        file_content: str
            sem="source content to understand what needs documenting"
    ) -> ContributorSuggestion by llm();
}

obj ContributorSuggestion {
    has title: str
        sem="concise issue title suitable for a GitHub issue";
    has description: str
        sem="two to three sentence description of what needs to be done";
    has difficulty: str
        sem="good-first-issue, intermediate, advanced";
    has file_path: str
        sem="which file this suggestion is about";
    has suggestion_type: str
        sem="missing_tests, missing_docs, incomplete_feature, missing_example";
}
```

---

## Backboard Memory Integration

Each walker has its own Backboard assistant with a dedicated memory thread per repository:

```jac
import from backboard { BackboardClient }

glob backboard_client: BackboardClient = BackboardClient(
    api_key=env.BACKBOARD_API_KEY
);

glob security_assistant_id: str = "sentree-security-jaseci-labs-jaseci";
glob compat_assistant_id: str = "sentree-compat-jaseci-labs-jaseci";
glob blast_assistant_id: str = "sentree-blast-jaseci-labs-jaseci";

can get_security_memory(context: str) -> str {
    return backboard_client.query(
        assistant_id=security_assistant_id,
        query=context
    );
}

can store_security_finding(finding: SecurityFinding, pr_url: str) -> None {
    backboard_client.store(
        assistant_id=security_assistant_id,
        content=f"PR: {pr_url} | Finding: {finding.description} | Severity: {finding.severity}"
    );
}
```

---

## Concurrency Model

```jac
# Parallel walker dispatch via flow/wait
# Each walker gets a dedicated thread — true parallelism, not async

can run_static_analysis(subgraph_root: FileNode, pr_diff: str) -> VerdictObject {
    # Spawn all three walkers simultaneously
    sec_future = flow SecurityAuditorWalker(pr_context=pr_diff) spawn subgraph_root;
    com_future = flow CompatibilityCheckerWalker(pr_diff=pr_diff) spawn subgraph_root;
    bla_future = flow BlastRadiusMapperWalker() spawn subgraph_root;
    
    # Collect results — each walker posts findings to Discord as it finishes
    # (incremental posting via Discord webhook, not waiting for all three)
    sec_result = wait sec_future;
    com_result = wait com_future;
    bla_result = wait bla_future;
    
    return merge_verdict(sec_result, com_result, bla_result);
}
```

---

## Discord Integration

```jac
import from discord { Client, Intents, Embed, Color, app_commands }

# Bot initialization — runs on jac start
with entry {
    intents = Intents.default();
    intents.message_content = True;
    bot = Client(intents=intents);
    bot.run(env.DISCORD_TOKEN);
}

# /trigger slash command
can handle_trigger(interaction: any, pr_url: str) -> None {
    await interaction.response.defer();
    
    # Fire orchestrator walker
    orchestrator = OrchestratorWalker(pr_url=pr_url);
    verdict = orchestrator spawn root;
    
    embed = build_verdict_embed(verdict);
    await interaction.followup.send(embed=embed);
}

can build_verdict_embed(verdict: VerdictObject) -> Embed by llm();
```

---

## jac.toml Configuration

```toml
[project]
name = "sentree"
version = "1.0.0"
entry = "main.jac"

[dependencies]
PyGithub = "^2.0.0"
"discord.py" = "^2.4.0"
e2b-code-interpreter = "^2.5.0"
backboard = "^1.0.0"

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

---

## Deployment

```bash
# Local development
jac start main.jac

# Production — auto-provisions Kubernetes + MongoDB + Redis + JWT + Swagger
jac start main.jac --scale
```

No Dockerfile. No manifests. No DevOps configuration. One command.

---

## Environment Variables

```
GITHUB_TOKEN=ghp_...          # GitHub personal access token (5000 req/hr)
ANTHROPIC_API_KEY=sk-ant-...  # Claude API for all by llm() calls
DISCORD_TOKEN=...             # Discord bot token
BACKBOARD_API_KEY=...         # Backboard memory API
E2B_API_KEY=...               # E2B sandbox API
```
