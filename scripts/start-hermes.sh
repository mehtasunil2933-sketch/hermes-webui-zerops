#!/usr/bin/env bash
# Gateway only. Refuses to start without a usable API_SERVER_KEY, because
# without it port 8642 never binds and Zerops shows a "healthy" dead service.
set -eu
export PATH="$HOME/.local/bin:$PATH"
: "${HERMES_HOME:=/mnt/vol/hermes}"; export HERMES_HOME
if [ "$(printf %s "${API_SERVER_KEY:-}" | wc -c)" -lt 16 ]; then
  echo "API_SERVER_KEY must be set and at least 16 characters" >&2; exit 1
fi
exec hermes gateway run
