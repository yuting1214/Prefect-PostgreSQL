from demo_workflow import show_stars

if __name__ == "__main__":
    show_stars.serve(
        name="interval-github-stars",
        parameters={
            "github_repos": [
                "facebook/react",
                "vuejs/vue",
                "angular/angular"
            ]
        },
        interval=30
    )