#!/usr/bin/env bash
# Prefect worker entrypoint.
#
# Three ordered steps, each of which fails visibly rather than silently:
#   1. wait for the server  — on a cold start it is still running migrations, and a
#      worker that starts too early produces a container that looks healthy and does
#      nothing.
#   2. ensure the work pool — `prefect deploy` will not register against a pool that
#      does not exist, and the worker only creates one at start-up, i.e. too late.
#   3. register deployments — runs `prefect deploy --all` against flows/prefect.yaml
#      so a deployer only ever edits that folder. NON-FATAL: a broken prefect.yaml
#      must not cost you the worker, because the pool still accepts work registered
#      by other means.
#   4. start the worker     — a no-op if the pool already exists, so redeploys are safe.
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

# --- 2. ensure the pool exists ------------------------------------------------
# `prefect worker start` would create it, but that happens in step 3 — and step 2's
# `prefect deploy` refuses to register a deployment against a pool that does not
# exist yet. So create it here. Idempotent: a redeploy finds it and moves on.
if prefect work-pool inspect "$POOL" >/dev/null 2>&1; then
  echo "worker: work pool '${POOL}' already exists"
else
  echo "worker: creating work pool '${POOL}'"
  prefect --no-prompt work-pool create --type process "$POOL" >/dev/null 2>&1 \
    || prefect work-pool inspect "$POOL" >/dev/null 2>&1 \
    || echo "worker: WARNING could not create work pool '${POOL}'" >&2
fi

# --- 3. register whatever the deployer declared -------------------------------
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

# --- 4. run ------------------------------------------------------------------
echo "worker: starting against pool '${POOL}'"
# --install-policy never: the default is 'prompt', which has no TTY in a container.
# A process worker needs no extra packages.
exec prefect worker start \
  --pool "$POOL" \
  --type process \
  --name "${PREFECT_WORKER_NAME:-railway-worker}" \
  --install-policy never
