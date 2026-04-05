# integrations/impl/discord.impl.jac

import from os { environ }
import from typing { Any }
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
        resp: Any = requests.post(webhook_url, json=payload, timeout=10);
        if resp.status_code not in [200, 204] {
            print(f"Discord webhook returned {resp.status_code}");
        }
    } except Exception as e { # jac:ignore[W2052]
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
    } except Exception as e { # jac:ignore[W2052]
        print(f"Discord error notification failed: {e}");
    }
}
