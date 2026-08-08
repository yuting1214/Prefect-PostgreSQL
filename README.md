<img src="assets/prefect.png" alt="Prefect" width="92" align="right" />

# Prefect + PostgreSQL on Railway

Self-hosted **[Prefect 3](https://github.com/PrefectHQ/prefect)** on Railway — the
Prefect server (API + UI) with a PostgreSQL database behind it, in one click.

Two templates, same stack, different halves of the job.

| | **Prefect Server** | **Prefect + Worker** |
|---|---|---|
| | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/z8tmK-?referralCode=jk_FgY&utm_medium=integration&utm_source=template&utm_campaign=generic) | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/prefect-worker?referralCode=jk_FgY&utm_medium=integration&utm_source=template&utm_campaign=generic) |
| Services | server + Postgres | server + Postgres + **worker** |
| Work pool | you create one | **created on boot** |
| Runs your flows | ✗ you supply a worker | ✓ out of the box |
| Scheduled runs fire | while your machine is awake | **always** |
| Your flows live in | wherever you like | `flows/` in your fork of this repo |
| Prefect installed locally | required | optional |

**Prefect Server** is the control plane on its own — the API, the UI and a database.
Use it when you already have somewhere to run a worker, or you only want the
dashboard.

**Prefect + Worker** adds the execution half. A Prefect server schedules work but
does not perform it: without a worker, a flow scheduled for 3am simply goes `Late`.
This template ships a worker that is already running, already authenticated and
already attached to a pool.

Both pin Prefect to the **3.8** line (`prefecthq/prefect:3.8-python3.12`, currently
3.8.2) and PostgreSQL to **18**, so a deploy today and a deploy next month give you
the same Prefect minor while patch releases still arrive automatically.

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

**Deployed via the button? Eject the worker first.** A deployed template attaches
directly to *this* repository, which you cannot push to. In Railway: **worker**
service → **Settings** → **Source** → **Upstream Repo** → **Eject** → pick your
GitHub org → **Eject service**.

You then get your own copy, and everything after that is a file edit on github.com —
open `flows/example_stars.py`, click the pencil, replace it with your flow, commit.
Railway rebuilds and re-registers on boot. Railway also opens a pull request in your
copy whenever this template improves.

(Starting from scratch instead of the button? Just fork this repo.)

Then you only ever touch two things:

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
