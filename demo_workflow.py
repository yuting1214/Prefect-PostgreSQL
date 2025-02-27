import httpx
from prefect import flow, task

@task
def fetch_stats(github_repo: str):
    """Task 1: Fetch the statistics for a GitHub repo"""
    return httpx.get(f"https://api.github.com/repos/{github_repo}").json()

@task
def get_stars(repo_stats: dict):
    """Task 2: Get the number of stars from GitHub repo statistics"""
    return repo_stats['stargazers_count']

@flow(log_prints=True)
def show_stars(github_repos: list[str]):
    """Flow: Show the number of stars that GitHub repos have"""
    for repo in github_repos:
        repo_stats = fetch_stats(repo)
        stars = get_stars(repo_stats)
        print(f"{repo}: {stars} stars")
    return "Completed successfully!"