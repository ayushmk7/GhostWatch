# integrations/discord.jac — Discord webhook notification (send only, no bot).

def notify_discord(pr_number: str, risk: str, report_link: str) -> None;

def notify_discord_error(pr_number: str, error_message: str) -> None;
