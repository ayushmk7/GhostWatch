# lib/sandbox_exec.jac — Local subprocess sandbox instrumentation (no live E2B in tests).

def run_dependency_install_sandbox(
    ecosystem: str,
    package_name: str,
    version_spec: str,
    workspace_root: str
) -> dict;
