# walkers/static/pr_comment.jac
# PRCommentWriterWalker: posts a single review comment to GitHub PR on Approve.
# Idempotent — checks if comment already posted before writing.
# Implementation in impl/pr_comment.impl.jac

walker:pub PRCommentWriterWalker {
    has pr_url: str;
    has verdict_id: str;
    has reports: list = [];

    can post with `root entry {
        report {"status": "success", "comment_url": ""};
    }
}
