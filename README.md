# hermes-agent-railway

Railway-tuned build of [Nous Research's Hermes Agent](https://github.com/NousResearch/hermes-agent).
Same official image underneath (`nousresearch/hermes-agent`), wrapped so a Railway deploy needs
**no configuration**: the dashboard follows Railway's assigned `$PORT`, the platform env is baked
in, and the dashboard password is generated and persisted if none is supplied.

Published as `ghcr.io/bon5co/hermes-agent-railway:latest`.

## Why a wrapper exists

Railway's `templateGenerate` only preserves a variable default when the value is a Railway
*expression* (`${{secret(24)}}`, `${{RAILWAY_PUBLIC_DOMAIN}}`, …). A variable holding a literal —
`9119`, `/opt/data`, `0.0.0.0` — loses its default and publishes as **required with no value**, so
the deploy form asks the user to type settings the image already knows. Baking those into the image
removes them from the form entirely.

What the wrapper adds on top of the official image:

| Concern | Handling |
| --- | --- |
| Port | Dashboard listens on `$PORT` (Railway-assigned), falling back to `9119`. |
| Dashboard | `HERMES_DASHBOARD=1`, bound `0.0.0.0`, user `admin` — baked, not asked. |
| Password | Uses `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` if set; else generates one, persists it to `$HERMES_HOME/.railway-dashboard-password` on the volume, and prints it to the logs. |
| Memory | `HERMES_HOME=/opt/data` (upstream default) — mount the volume there. |

The password fallback matters because the dashboard **fails closed**: since the June 2026
hardening it refuses to start on a non-loopback bind without a registered auth provider, and
`HERMES_DASHBOARD_INSECURE` is accepted-and-ignored. An empty password would mean no dashboard at
all rather than an open one, so the wrapper always ensures a provider is registered.

## Run it directly

```sh
docker run -d --name hermes \
  -p 9119:9119 \
  -v hermes-data:/opt/data \
  -e HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=choose-something \
  ghcr.io/bon5co/hermes-agent-railway:latest
```

Then open <http://localhost:9119> and sign in as `admin`.

## Upstream

- [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- [nousresearch/hermes-agent](https://hub.docker.com/r/nousresearch/hermes-agent) — the base image
  this pins (`v2026.7.20`)

A weekly Actions run rebuilds the wrapper so it tracks upstream releases.
