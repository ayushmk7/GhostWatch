# walkers/ghostwatch/impl/sandbox.impl.jac

import from graph.nodes { GhostwatchIncidentNode }
import from lib.sandbox_exec { run_dependency_install_sandbox }
import from walkers.ghostwatch.fix_gen { FixGenerationWalker }
import from time { time }

impl SandboxExecutorWalker._interpret_behavior(raw_evidence: dict) -> dict {
    return {
        "summary": "Deterministic stub (configure LLM to replace)",
        "verdict": "needs_human_review",
        "iocs": []
    };
}

impl SandboxExecutorWalker.run with root() entry {
    handled = False;
    for target in [root() -->][?:GhostwatchIncidentNode] {
        if str(jid(target)) != self.incident_jid {
            continue;
        }
        handled = True;
        target.status = "sandboxed";
        target.updated_at = str(int(time()));
        eco = "pip";
        if target.manifest_path.endswith("package.json") {
            eco = "npm";
        }
        raw = run_dependency_install_sandbox(eco, target.dependency_name, target.dependency_version, "");
        target.sandbox_result = raw;
        try {
            bt = self._interpret_behavior(raw_evidence=raw);
        } except Exception {
            bt = {"summary": "LLM interpretation failed", "verdict": "needs_human_review", "iocs": []};
        }
        target.behavioral_trace = bt;
        v = str(bt.get("verdict", "needs_human_review")).lower();
        if v == "malicious" {
            target.status = "malicious";
        } elif v == "cleared" {
            target.status = "cleared";
        } else {
            target.status = "needs_human_review";
        }
        target.updated_at = str(int(time()));
        if target.status == "malicious" {
            _ = root() spawn FixGenerationWalker(incident_jid=self.incident_jid);
        }
        report {"status": target.status, "jid": self.incident_jid};
        break;
    }
    if not handled {
        report {"error": "incident not found", "jid": self.incident_jid};
    }
}
