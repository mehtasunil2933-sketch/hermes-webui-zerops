# Hermes + Hermes WebUI on Zerops

Two runtime services share one Local Storage volume (`vol`, mounted at `/mnt/vol`):

| Service | What | Port |
| --- | --- | --- |
| `hermes` | Hermes Agent gateway (Telegram, cron, API server). Only writer. `maxContainers: 1`. | 8642 (private) |
| `webui` | [nesquena/hermes-webui](https://github.com/nesquena/hermes-webui) v0.52.113, chat executed on `hermes` via `http://hermes:8642` | 8787 (public subdomain, password) |

Versions are pinned together: `hermes-agent==0.19.0` + WebUI `v0.52.113`. Bump both at once.

## Deploy
Zerops dashboard -> Import a project -> paste `zerops-import.yaml`. Secrets (`API_SERVER_KEY`, `HERMES_WEBUI_PASSWORD`) are generated at import; read the WebUI password under the `webui` service -> Environment variables.

## Backups (same pattern as the original `hermes` repo)
- Hourly: `sqlite3 .backup` of `state.db` / `kanban.db` to `/mnt/vol/backup`.
- Daily 03:45: `hermes backup` zip -> `r2:$R2_BUCKET/hermes/hermes-YYYY-MM-DD.zip` and `latest.zip` (30 day remote retention, 3 day local). rclone remote `r2` is configured purely by `RCLONE_CONFIG_R2_*` env vars; set endpoint and keys in the `hermes` service secrets. Skipped while they still say `REPLACE`.
- Restore: `cd /tmp && rclone copy r2:$R2_BUCKET/hermes/latest.zip . && hermes import /tmp/latest.zip`
