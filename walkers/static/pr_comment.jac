# walkers/static/pr_comment.jac — Posts GitHub PR review comment on Approve.
# Idempotent — checks if comment already posted.

walker:pub PRCommentWriterWalker {
    has pr_url: str;
    has verdict_id: str;

    can post_review with `root entry;

    def _format_verdict_comment(verdict: dict) -> str by llm;
}

sem PRCommentWriterWalker._format_verdict_comment = "Format the verdict dict as a clear, concise GitHub PR review comment in Markdown. Include overall risk, key security findings, compatibility issues, blast radius, and recommendation.";
