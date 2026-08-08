<img src="Prefect.png" alt="Prefect" width="92" align="right" />

# Prefect + PostgreSQL on Railway

Self-hosted **[Prefect 3](https://github.com/PrefectHQ/prefect)** on Railway — the
Prefect server (API + UI) with a PostgreSQL database behind it, in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/z8tmK-?referralCode=jk_FgY&utm_medium=integration&utm_source=template&utm_campaign=generic)

The template deploys two services:

| Service | Image | Notes |
|---|---|---|
| Prefect server | `prefecthq/prefect:3-latest` | public domain, port `4200` |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl` | persistent volume |

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

> **Secure it.** The Prefect server is deployed without authentication, so anyone
> with the URL can read and control it. Set `PREFECT_SERVER_API_AUTH_STRING` on the
> server service (and the matching `PREFECT_API_AUTH_STRING` on any client) if the
> domain is reachable from the internet. See
> [Prefect's security settings](https://docs.prefect.io/v3/advanced/security-settings).

## Running flows

A Prefect server schedules work but does not execute it — that's a **worker's** job.
This repo contains one:

| File | What it is |
|---|---|
| `Dockerfile` | worker image — `prefect worker start -p Process` |
| `requirements.txt` | worker dependencies — **fork and add your flow's libraries here** |
| `demo_workflow.py` | example flow: counts stars on GitHub repos |
| `create_deployment.py` | registers that flow against the `Process` work pool, every 60s |

Create the work pool once, then run a worker against it:

```bash
prefect work-pool create --type process Process
prefect worker start -p Process
python create_deployment.py
```

Deploy the worker on Railway from this repo (or your fork of it) and it will keep
polling the pool for scheduled runs.

## Credits

Prefect is open source by
**[Prefect Technologies](https://github.com/PrefectHQ/prefect)** (Apache-2.0). This
is a **community** template, not an official Prefect product.
