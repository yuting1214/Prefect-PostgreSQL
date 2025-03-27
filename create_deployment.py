from prefect import flow
from prefect.runner.storage import GitRepository
# Source for the code to deploy (here, a GitHub repo)
SOURCE_REPO="https://github.com/yuting1214/Prefect-PostgreSQL.git"

if __name__ == "__main__":
    flow.from_source(
        source=GitRepository(
            url=SOURCE_REPO,
            branch="dynamic-process-work-pool",
            pull_interval=None
        ),
        entrypoint="demo_workflow.py:show_stars",
    ).deploy(
        name="interval-github-stars",
        parameters={
            "github_repos": [
                "facebook/react",
                "vuejs/vue",
                "angular/angular"
            ]
        },
        work_pool_name="Process",
        interval=60,
        build=False
    )