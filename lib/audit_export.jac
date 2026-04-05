# lib/audit_export.jac — Export security findings to external audit log service.
# Uses the analytics client to ship verdicts to the team dashboard.

import requests;
import from os { environ }
import from typing { Any }

def export_audit_log(pr_url: str, verdict: dict, findings: list) -> bool;
def _build_audit_payload(pr_url: str, verdict: dict, findings: list) -> dict;
