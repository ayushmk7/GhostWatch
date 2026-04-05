# tests/test_traversal.jac
# TDD: OrchestratorWalker must always return non-empty traversal_paths.blast_radius

import from walkers.static.orchestrator { OrchestratorWalker }
import from typing { Any }

test "traversal_paths_populated" {
    result: Any = root() spawn OrchestratorWalker(
        pr_url="https://github.com/Aarosunn/ghostwatch-test-target/pull/2"
    );
    verdict: Any = getattr(result, "verdict", {});
    paths: Any = verdict.get("traversal_paths", {});
    blast: Any = paths.get("blast_radius", []);
    assert len(blast) > 0, f"traversal_paths.blast_radius is empty: {verdict}";
}
