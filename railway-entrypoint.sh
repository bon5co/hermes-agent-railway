#!/bin/sh
# Railway entrypoint for the official Hermes Agent image.
#
# Two jobs, both of which exist because Railway's contract differs from a plain
# `docker run`:
#
#   1. Honor the port Railway assigns. Railway injects PORT into the service; the
#      dashboard has to listen on exactly that port or the edge proxy 502s.
#   2. Never let the dashboard fail closed. Since the June 2026 hardening the
#      dashboard REFUSES to start on a non-loopback bind without a registered auth
#      provider, so an empty password is not "no auth", it is "no dashboard". If the
#      deployer clears the password field we generate one, persist it on the volume,
#      and print it to the deploy logs instead of crash-looping.
set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"

# 1. The dashboard follows Railway's assigned port.
HERMES_DASHBOARD_PORT="${PORT:-${HERMES_DASHBOARD_PORT:-9119}}"
export HERMES_DASHBOARD_PORT

export HERMES_DASHBOARD="${HERMES_DASHBOARD:-1}"
export HERMES_DASHBOARD_HOST="${HERMES_DASHBOARD_HOST:-0.0.0.0}"
export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-admin}"

# 2. Password: supplied wins; else reuse the persisted one; else generate.
pw_file="$HERMES_HOME/.railway-dashboard-password"
if [ -z "${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}" ]; then
    if [ -s "$pw_file" ]; then
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$(cat "$pw_file")"
    else
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)"
        mkdir -p "$HERMES_HOME"
        printf '%s' "$HERMES_DASHBOARD_BASIC_AUTH_PASSWORD" > "$pw_file"
        chmod 600 "$pw_file"
    fi
    echo "[railway] no HERMES_DASHBOARD_BASIC_AUTH_PASSWORD set; using generated password:" >&2
    echo "[railway]   user: $HERMES_DASHBOARD_BASIC_AUTH_USERNAME" >&2
    echo "[railway]   pass: $HERMES_DASHBOARD_BASIC_AUTH_PASSWORD" >&2
    echo "[railway] (persisted at $pw_file on the volume; set the variable to override)" >&2
fi
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD

echo "[railway] dashboard on ${HERMES_DASHBOARD_HOST}:${HERMES_DASHBOARD_PORT}, HERMES_HOME=${HERMES_HOME}" >&2

# /init scrubs the environment and repopulates it from /run/s6/container_environment
# via with-contenv, so exported vars here do reach the supervised dashboard service.
exec /init /opt/hermes/docker/main-wrapper.sh "$@"
