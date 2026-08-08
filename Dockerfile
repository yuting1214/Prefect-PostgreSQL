# Prefect worker — the execution half of the work-pool template.
#
# The server schedules; this container runs your flows. Each flow run executes as a
# subprocess here, so every package your flows import must be a dependency in
# pyproject.toml. Add one with `uv add <package>`, commit pyproject.toml and uv.lock,
# and push — Railway rebuilds this image.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# git and certs are needed at RUNTIME, not just build time: Prefect's git_clone pull
# step fetches code when a deployment is sourced from a repository.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Worker knobs live HERE, not on the template's deploy form. A deployer should not
# have to invent a pool name or a startup timeout to click Deploy; they are
# overridable as service variables if anyone ever needs to.
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH" \
    PREFECT_WORK_POOL=Process \
    PREFECT_WORKER_NAME=railway-worker \
    PREFECT_API_WAIT_SECONDS=300 \
    PREFECT_DEPLOY_FILE=flows/prefect.yaml

# Dependencies first, so edits to flows/ don't invalidate the install layer.
# --frozen: fail if uv.lock is out of date rather than silently resolving something else.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY . .
RUN chmod +x worker/entrypoint.sh

ENTRYPOINT ["/app/worker/entrypoint.sh"]
