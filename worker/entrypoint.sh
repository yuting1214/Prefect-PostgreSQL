#!/usr/bin/env bash
# Prefect worker entrypoint.
#
# Three ordered steps, each of which fails visibly rather than silently:
#   1. wait for the server  — on a cold start it is still running migrations, and a
#      worker that starts too early produces a container that looks healthy and does
#      nothing.
#   2. register deployments — runs `prefect deploy --all` against flows/prefect.yaml
#      so a deployer only ever edits that folder. NON-FATAL: a broken prefect.yaml
#      must not cost you the worker, because the pool still accepts work registered
#      by other means.
#   3. start the worker     — creates the pool if missing (--create-pool-if-not-found
#      defaults to true) and is a no-op when it already exists, so redeploys are safe.
set -euo pipefail

: "${PREFECT_API_URL:?PREFECT_API_URL is required (e.g. https://server.up.railway.app/api)}"
POOL="${PREFECT_WORK_POOL:-Process}"
WAIT_SECONDS="${PREFECT_API_WAIT_SECONDS:-300}"
DEPLOY_FILE="${PREFECT_DEPLOY_FILE:-flows/prefect.yaml}"
HEALTH_URL="${PREFECT_API_URL%/}/health"

# --- 1. wait for the server ---------------------------------------------------
echo "worker: waiting up to ${WAIT_SECONDS}s for ${HEALTH_URL}"
# python3, not curl — the uv base image ships python but not curl.
python3 - "$HEALTH_URL" "$WAIT_SECONDS" <<'PY'
import sys, time, urllib.request
url, deadline, last = sys.argv[1], time.time() + float(sys.argv[2]), None
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

# --- 2. register whatever the deployer declared -------------------------------
if [[ -f "$DEPLOY_FILE" ]]; then
  echo "worker: registering deployments from ${DEPLOY_FILE}"
  if prefect --no-prompt deploy --all --prefect-file "$DEPLOY_FILE" --pool "$POOL"; then
    echo "worker: deployments registered"
  else
    echo "==============================================================" >&2
    echo "worker: FAILED to register deployments from ${DEPLOY_FILE}."   >&2
    echo "worker: fix that file and redeploy. Starting the worker anyway" >&2
    echo "worker: so the '${POOL}' pool still accepts work."              >&2
    echo "==============================================================" >&2
  fi
else
  echo "worker: no ${DEPLOY_FILE} found — skipping registration"
fi

# --- 3. run ------------------------------------------------------------------
echo "worker: starting against pool '${POOL}'"
# --install-policy never: the default is 'prompt', which has no TTY in a container.
# A process worker needs no extra packages.
exec prefect worker start \
  --pool "$POOL" \
  --type process \
  --name "${PREFECT_WORKER_NAME:-railway-worker}" \
  --install-policy never
