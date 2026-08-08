<img src="assets/prefect.png" alt="Prefect" width="92" align="right" />

# Prefect + PostgreSQL on Railway

Self-hosted **[Prefect 3](https://github.com/PrefectHQ/prefect)** on Railway — the
Prefect server (API + UI) with a PostgreSQL database behind it, in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/z8tmK-?referralCode=jk_FgY&utm_medium=integration&utm_source=template&utm_campaign=generic)

The template deploys two services:

| Service | Image | Notes |
|---|---|---|
| Prefect server | `prefecthq/prefect:3.8-python3.12` | public domain, port `4200`, password-protected |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:18` | persistent volume |

**Pinned to the Prefect 3.8 line** — currently **3.8.2** (released 2026-08-07), not a
moving `3-latest`. A deploy today and a deploy next month give you the same Prefect
minor: the same API, the same UI and the same database schema. Patch releases still
arrive automatically; only minor jumps are gated. Check what a running server is on
with `GET /api/admin/version`.

## After you deploy

Point your local Prefect at the deployed server:

```bash
prefect config set PREFECT_API_URL="https://<your-service>.up.railway.app/api"
```

Open the same domain in a browser for the UI. To go back to a local server, or to
Prefect's hosted control plane:

```bash
prefect config set PREFECT_API_URL="http://127.0.0.1:4200/api"
prefect cloud login
```

> **Credentials.** The server is password-protected by default with a unique random
> password generated at deploy time. Find it in the Railway dashboard on the
> `prefect-server` service under **Variables** → `PREFECT_SERVER_API_AUTH_STRING`,
> in the form `admin:PASSWORD`. Clients and workers need the same value:
> `prefect config set PREFECT_API_AUTH_STRING="admin:YOUR-PASSWORD"`. See
> [Prefect's security settings](https://docs.prefect.io/v3/advanced/security-settings).

## Running flows

A Prefect server schedules work but does not execute it — that's a **worker's** job.
This repo contains one:

Fork this repo, then you only ever touch two things:

| | |
|---|---|
| **`flows/`** | your flow code, plus `prefect.yaml` declaring which flows to register and on what schedule |
| **`pyproject.toml`** | your dependencies — `uv add pandas`, commit `pyproject.toml` **and** `uv.lock` |

Everything else is the worker itself: `Dockerfile` builds the image and
`worker/entrypoint.sh` waits for the server, runs `prefect deploy --all` against
`flows/prefect.yaml`, and starts polling. Push a change and Railway rebuilds — your
deployments re-register on boot.

```bash
uv sync                     # local dev environment
uv run python flows/example_stars.py   # run a flow directly
uv add pandas               # add a dependency, then commit pyproject.toml + uv.lock
```

## Credits

Prefect is open source by
**[Prefect Technologies](https://github.com/PrefectHQ/prefect)** (Apache-2.0). This
is a **community** template, not an official Prefect product.
