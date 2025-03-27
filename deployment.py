from demo_workflow import show_stars

if __name__ == "__main__":
    show_stars.deploy(
        name="interval-github-stars",
        parameters={
            "github_repos": [
                "facebook/react",
                "vuejs/vue",
                "angular/angular"
            ]
        },
        work_pool_name="Test",
        interval=30,
        image="prefect-server-image",
        build=False
    )