# GhostWatch — project entry (`jac.toml` entry-point): API walkers + client `app`.

import from graph.builder { GraphBuilderWalker }
import from walkers.static.graph_state { GraphStateWalker }
import from walkers.static.pr_comment { PRCommentWriterWalker }
import from walkers.ghostwatch.dep_diff { DependencyDiffWalker }
import from walkers.ghostwatch.sandbox { SandboxExecutorWalker }
import from walkers.ghostwatch.fix_gen { FixGenerationWalker }
import from walkers.ghostwatch.pr_creator { GhostwatchPRCreatorWalker }
import from walkers.ghostwatch.gap_analysis { GapAnalysisWalker }
import from walkers.ghostwatch.system2_hooks {
    System2PushTriggerWalker,
    System2MergeTriggerWalker,
    System2EscalationTickWalker
}
import from walkers.ghostwatch.github_system2_webhook { GitHubSystem2WebhookWalker }

import from typing { Any }

with entry { }

cl {
    def:pub app(children: Any = None) -> JsxElement {
        return <>{children}</>;
    }
}
