#!/usr/bin/env bash
# WebUI only. Chat is executed by the separate "hermes" service (gateway mode).
set -eu
export PATH="$HOME/.local/bin:$PATH"
VOL="${VOL:-/mnt/vol}"

if [ "$(printf %s "${HERMES_WEBUI_PASSWORD:-}" | wc -c)" -lt 12 ]; then
  echo "HERMES_WEBUI_PASSWORD must be set and at least 12 characters" >&2; exit 1
fi
case "${HERMES_WEBUI_GATEWAY_API_KEY:-}" in
  ''|'${'*) echo "HERMES_WEBUI_GATEWAY_API_KEY is empty/unresolved: check that service 'hermes' has API_SERVER_KEY" >&2; exit 1;;
esac

export HERMES_HOME="${HERMES_HOME:-$VOL/hermes}"
export HERMES_WEBUI_HOST=0.0.0.0
export HERMES_WEBUI_PORT=8787
export HERMES_WEBUI_STATE_DIR="$HERMES_HOME/webui"
export HERMES_WEBUI_DEFAULT_WORKSPACE="$VOL/workspace"
mkdir -p "$HERMES_HOME" "$HERMES_WEBUI_DEFAULT_WORKSPACE"

# pip-installed agent has no checkout, so point WebUI at site-packages
HERMES_WEBUI_AGENT_DIR="$(python3 -c 'import os, run_agent; print(os.path.dirname(run_agent.__file__))')" \
  || { echo "hermes-agent is not importable by python3" >&2; exit 1; }
export HERMES_WEBUI_AGENT_DIR

cd /var/www/webui
exec python3 server.py
