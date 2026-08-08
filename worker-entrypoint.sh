#!/usr/bin/env bash
# Prefect worker entrypoint.
#
# Ordering problem this solves: on a cold start the server is still running Alembic
# migrations while this container boots. Starting the worker against an API that
# isn't serving yet produces a container that looks healthy and does nothing. So we
# block on the server's health endpoint first, with a clear log line either way.
#
# The work pool itself needs no special handling — `prefect worker start` creates it
# when missing (--create-pool-if-not-found defaults to true) and is a no-op when it
# already exists, so redeploys are safe.
set -euo pipefail

: "${PREFECT_API_URL:?PREFECT_API_URL is required (e.g. https://server.up.railway.app/api)}"
POOL="${PREFECT_WORK_POOL:-Process}"
WAIT_SECONDS="${PREFECT_API_WAIT_SECONDS:-300}"
HEALTH_URL="${PREFECT_API_URL%/}/health"

echo "worker: waiting up to ${WAIT_SECONDS}s for ${HEALTH_URL}"
# python, not curl — the uv base image ships python but not curl.
python3 - "$HEALTH_URL" "$WAIT_SECONDS" <<'PY'
import sys, time, urllib.request
url, deadline = sys.argv[1], time.time() + float(sys.argv[2])
while True:
    try:
        with urllib.request.urlopen(url, timeout=5) as r:
            if r.status == 200:
                print("worker: server is healthy", flush=True)
                sys.exit(0)
    except Exception as exc:
        last = exc
    if time.time() >= deadline:
        print(f"worker: server never became healthy: {last}", file=sys.stderr)
        sys.exit(1)
    time.sleep(3)
PY

echo "worker: starting against pool '${POOL}'"
# --install-policy never: the default is 'prompt', which has no TTY in a container.
# A process worker needs no extra packages, so nothing to install.
exec prefect worker start \
  --pool "$POOL" \
  --type process \
  --name "${PREFECT_WORKER_NAME:-railway-worker}" \
  --install-policy never
