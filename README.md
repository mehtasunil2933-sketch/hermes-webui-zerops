# Hermes + Hermes WebUI on Zerops

Two runtime services share one Local Storage volume (`vol`, mounted at `/mnt/vol`):

| Service | What | Port |
| --- | --- | --- |
| `hermes` | Hermes Agent gateway (Telegram, cron, API server). Only writer. `maxContainers: 1`. | 8642 (private) |
| `webui` | [nesquena/hermes-webui](https://github.com/nesquena/hermes-webui) v0.52.113, chat executed on `hermes` via `http://hermes:8642` | 8787 (public subdomain, password) |

Versions are pinned together: `hermes-agent==0.19.0` + WebUI `v0.52.113`. Bump both at once.

## Deploy
Zerops dashboard -> Import a project -> paste `zerops-import.yaml`. Secrets (`API_SERVER_KEY`, `HERMES_WEBUI_PASSWORD`) are generated at import; read the WebUI password under the `webui` service -> Environment variables.

## Backups
- Hourly: `sqlite3 .backup` of `state.db` / `kanban.db` to `/mnt/vol/backup`.
- Daily 03:45: uploads DB copies + config/memory/skills tarball to Cloudflare R2 when these secrets exist on the `hermes` service: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` (optional `R2_RETENTION`, default `14d`). Without them the upload is skipped.
