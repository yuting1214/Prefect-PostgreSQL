# Prefect worker — the execution half of the work-pool template.
#
# The server schedules; this container is what actually runs your flows. It polls a
# process work pool and executes each flow run as a subprocess, so anything your
# flows import must be installed here — fork this repo and add it to requirements.txt.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# git is REQUIRED at runtime, not just build time: flow.from_source(...) clones the
# deployer's repository when a run starts.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV UV_SYSTEM_PYTHON=1 \
    PYTHONUNBUFFERED=1 \
    PREFECT_WORK_POOL=Process

COPY requirements.txt .
RUN uv pip install -r requirements.txt

COPY . .

RUN chmod +x /app/worker-entrypoint.sh
ENTRYPOINT ["/app/worker-entrypoint.sh"]
