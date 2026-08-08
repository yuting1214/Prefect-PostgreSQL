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

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH" \
    PREFECT_WORK_POOL=Process

# Dependencies first, so edits to flows/ don't invalidate the install layer.
# --frozen: fail if uv.lock is out of date rather than silently resolving something else.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY . .
RUN chmod +x worker/entrypoint.sh

ENTRYPOINT ["/app/worker/entrypoint.sh"]
