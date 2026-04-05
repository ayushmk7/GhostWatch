# lib/repo_demo_env.jac — Demo repo URL for UI (fixed product scope: jaseci monorepo only).

def:pub ghostwatch_demo_repo_url() -> str {
    return "https://github.com/jaseci-labs/jaseci";
}

def:pub ghostwatch_demo_repo_slug(url: str) -> str {
    t = url.strip();
    t = t.replace("https://github.com/", "");
    t = t.replace("http://github.com/", "");
    t = t.replace("github.com/", "");
    t = t.strip().strip("/");
    return t if t else "jaseci-labs/jaseci";
}
