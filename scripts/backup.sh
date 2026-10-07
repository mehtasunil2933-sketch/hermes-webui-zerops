#!/usr/bin/env bash
# backup.sh db       hourly consistent SQLite copy onto the volume (never cp a live WAL db)
# backup.sh offsite  daily: `hermes backup` zip -> Cloudflare R2 (same layout as the original hermes repo)
#                    r2:$R2_BUCKET/hermes/hermes-YYYY-MM-DD.zip + latest.zip, 30 day remote retention
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
H="${HERMES_HOME:-/mnt/vol/hermes}"; B=/mnt/vol/backup
mkdir -p "$B"

db_backup() {
  for f in state.db kanban.db; do
    if [ -f "$H/$f" ]; then sqlite3 "$H/$f" ".backup '$B/$f'"; fi
  done
}

case "${1:-db}" in
  db) db_backup ;;
  offsite)
    db_backup
    for v in RCLONE_CONFIG_R2_ENDPOINT RCLONE_CONFIG_R2_ACCESS_KEY_ID RCLONE_CONFIG_R2_SECRET_ACCESS_KEY R2_BUCKET; do
      val="${!v:-}"
      if [ -z "$val" ] || [[ "$val" == *REPLACE* ]]; then
        echo "backup: $v not set, skipping Cloudflare R2 upload"; exit 0
      fi
    done
    STAMP=$(date -u -I)
    hermes backup -o "$B/hermes-$STAMP.zip"
    rclone copyto "$B/hermes-$STAMP.zip" "r2:$R2_BUCKET/hermes/hermes-$STAMP.zip"
    rclone copyto "$B/hermes-$STAMP.zip" "r2:$R2_BUCKET/hermes/latest.zip"
    find "$B" -name 'hermes-*.zip' -mtime +3 -delete
    rclone delete "r2:$R2_BUCKET/hermes/" --min-age 30d --include 'hermes-*.zip'
    ;;
  *) echo "usage: backup.sh db|offsite" >&2; exit 2 ;;
esac
