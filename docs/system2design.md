System 2 Backend Plan
Summary
Build GhostWatch System 2 as a real, webhook-driven Jac backend that extends the current repo’s shared graph and integration layer, then implements the full autonomous pipeline:

detect suspicious dependency changes on push
sandbox flagged packages with real evidence capture
generate and validate a manifest fix
open an auto-fix PR and alert maintainers
run post-merge gap analysis and persist contributor suggestions
Use the April 4 design docs plus the current repo shape as the source of truth. Keep the frontend mostly untouched in this phase; backend work must expose stable persisted state and shared contracts that the existing /security/:incident_id and /gaps pages can consume later.

Public Interfaces And Shared Contracts
Extend the shared graph model to support System 2, not just System 1.
Add persistent node types for:
DependencyNode
DocumentationNode
TestNode
GhostwatchIncidentNode
GapAnalysisNode
Add shared edge types for:
DependencyEdge
FindingEdge
Fill the System 2 object layer with:
SuspiciousDependency
BehavioralTrace
SandboxResult
any small fix-validation object needed to keep walker returns typed and deterministic
Keep ContributorSuggestion in the shared verdict/object layer so System 1 and System 2 still share one suggestion type.
Expand the GitHub integration surface so walkers never call PyGithub directly for:
webhook signature validation
commit file listing
parent commit lookup
manifest snapshot fetch at a specific ref
branch creation
file update on branch
PR creation and duplicate-PR lookup
Expand the Discord integration surface for:
incident alert
escalation reminder
gap suggestion digest
Extend graph-state output to include optional System 2 summaries:
latest incident summary
latest gap-analysis summary
Add one shared public webhook entrypoint that validates GitHub signatures and dispatches:
push events touching dependency manifests to DependencyDiffWalker
merged PR events to GapAnalysisWalker
Implementation Changes
1. Shared foundation first
Implement the shared graph builder before System 2 walkers rely on it.
The builder must create:
FileNode entries for code/config files
DependencyNode entries from package.json, jac.toml, requirements.txt, and pyproject.toml
ImportEdge links between source files
DependencyEdge links from dependencies to importing files
TestNode links using filename/module-path heuristics
DocumentationNode links using docs/ and adjacent markdown heuristics
Graph building should stay deterministic. Do not use by llm() for parsing manifests, imports, test linkage, or doc linkage.
Make the builder safe to rerun: either skip rebuild when the graph exists or replace/update by an explicit rebuild path, but never silently duplicate shared nodes.
2. DependencyDiffWalker
Trigger only when a push touches supported manifest files.
For each changed manifest, fetch both parent and current contents from GitHub, then parse them deterministically.
Normalize package names before comparison:
lowercase
collapse _ / . / -
allow a small alias map where import name differs from package name
Detect suspicious dependencies using explicit rule codes:
phantom_import: present in manifest delta, not used by any importing file in the graph
new_postinstall: install script introduced or materially changed
young_package: package publish age under 30 days when metadata is available
no_provenance: missing or unverifiable source/provenance signal
Compute risk_level deterministically:
critical for combined high-signal cases such as phantom import plus install script
high for two strong signals
medium for a single suspicious signal
Persist or update one GhostwatchIncidentNode per dedupe key:
repo
commit SHA
manifest path
dependency name
Spawn SandboxExecutorWalker only for flagged dependencies. Clean manifest changes should still be recorded as a no-op incident result or skipped consistently.
3. SandboxExecutorWalker
Run one isolated sandbox per flagged dependency.
Support ecosystem-specific install commands:
npm for package.json
pip for Python and Jac dependency manifests
Instrument the sandbox so evidence capture is structured, not inferred from prose:
outbound network attempts
file writes outside the workspace
spawned child processes
access to likely credential paths
self-delete indicators
Store raw evidence and a typed SandboxResult first.
Use by llm() only for the final behavioral interpretation step that converts raw evidence into BehavioralTrace.
Incident status transitions here:
detected -> sandboxed
sandboxed -> malicious
sandboxed -> needs_human_review
sandboxed -> cleared
Only malicious incidents continue to fix generation. Inconclusive incidents alert maintainers but do not mutate GitHub.
4. FixGenerationWalker
Prefer deterministic repair over open-ended rewriting.
Generate fixes from the manifest delta:
if the malicious dependency was newly added, remove it
if a known-good parent version existed, restore the parent version exactly
if a malicious install script was added, revert that script field to the parent state
Preserve unrelated manifest content and formatting as much as practical.
Use by llm() only for small scoped tasks such as:
explaining the fix
filling in missing rationale
recovering a valid manifest patch only when deterministic inversion is impossible
Validate the candidate fix in a second sandbox using the same evidence instrumentation.
Only advance when validation both installs successfully and removes the malicious behavior signal.
5. PR creator and escalation
After successful fix validation:
create branch ghostwatch/auto-fix-{dep-name}-{timestamp}
commit only affected manifest files
open a PR with a structured evidence-heavy body
The PR body must include:
dependency name and version
why it was flagged
sandbox evidence summary
concrete IOCs
what the fix changed
explicit maintainer merge guidance
Enforce idempotency:
do not create duplicate branches or PRs for the same incident
update the existing incident node instead
Send the Discord alert only after the incident has a stable outcome:
malicious without fix PR
malicious with opened fix PR
inconclusive / needs human review
Store next_escalation_at and alert_state on the incident node.
Implement the 2-hour re-ping as a real backend behavior, but make it recovery-safe:
schedule an in-process reminder for the demo path
also persist the timestamp so a later sweep can avoid lost-state problems after restart
6. GapAnalysisWalker
Trigger on merged PR events and traverse the persisted graph after merge.
Detect gaps deterministically before generating prose:
non-test implementation files with no connected TestNode
Jac modules with no connected DocumentationNode
empty or placeholder modules under core product areas, mapped to incomplete_feature
Rank candidates so the output stays high-signal.
Emit 3 to 5 ContributorSuggestion objects only.
Use by llm() for wording and difficulty assignment, not for deciding whether the gap exists.
Persist one GapAnalysisNode per run with:
merge commit SHA
suggestion list
created timestamp
Send a concise Discord digest after persistence.
7. Main application wiring
Wire the backend through the existing app startup path rather than treating the current frontend-only repo as disposable.
The running app must load:
shared graph declarations
shared integrations
System 1 shared readers already in the repo
all System 2 walkers
The webhook entrypoint should be the single public ingress for GitHub events.
Direct public walkers for manual demo/testing are still useful:
push-event trigger
post-merge analysis trigger
rebuild-graph trigger
Error handling must be status-first:
persist incident state before and after each external action
never lose track of an incident because GitHub, Discord, or E2B failed mid-run
Test Plan
jac check every shared and System 2 module as it is added.
Add real deterministic tests for:
manifest parsing for all supported file types
package-name normalization and alias handling
suspicious-rule classification
dedupe-key generation
fix inversion from parent/current manifest snapshots
gap candidate ranking
Add smoke-style Jac tests for:
webhook dispatch choosing the correct System 2 walker
incident-node persistence and status transitions
idempotent re-entry when the same commit/dependency is processed twice
graph-state summary including latest incident and latest gap-analysis data
Keep live GitHub, Discord, and E2B out of the automated suite.
Use one manual verification checklist for external integrations:
push touching manifest triggers incident
malicious dependency reaches sandbox
validated fix opens one PR
Discord alert fires once
merged PR triggers persisted gap suggestions
Assumptions And Defaults
April 4 design plus the current repo are authoritative; broader PRDs are intent-only where they conflict.
This phase is backend plus shared contracts, not frontend implementation.
Full live autonomy is in scope, but all mutating external actions must be guarded by persisted incident state and idempotency checks.
Deterministic parsing and evidence capture come first; by llm() is reserved for summarization, explanation, and tightly bounded generation tasks.
System 2 persistence should favor a few strong aggregate nodes over a large fan-out of tiny nodes, so the incident lifecycle stays simple to query and recover.