"""Example flow — delete this once you've added your own.

Anything in flows/ can be registered by declaring it in flows/prefect.yaml.
The worker runs these inside its own container, so every import must be a
dependency in pyproject.toml (add with `uv add <package>`).
"""
import httpx
from prefect import flow, get_run_logger, task


@task(retries=2, retry_delay_seconds=5)
def fetch_stars(repo: str) -> int:
    """Retries are free — the task decorator handles transient API failures."""
    response = httpx.get(f"https://api.github.com/repos/{repo}", timeout=15)
    response.raise_for_status()
    return response.json()["stargazers_count"]


@flow(name="github-stars")
def github_stars(repos: list[str] = ["PrefectHQ/prefect"]) -> dict[str, int]:
    log = get_run_logger()
    results = {}
    for repo in repos:
        results[repo] = fetch_stars(repo)
        log.info(f"{repo}: {results[repo]} stars")
    return results


if __name__ == "__main__":
    github_stars()
