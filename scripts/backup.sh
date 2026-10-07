#!/usr/bin/env bash
# backup.sh db       hourly consistent SQLite copy onto the volume (never cp a live WAL db)
# backup.sh offsite  daily: db copy + config/memory/skills archive -> Cloudflare R2 (skipped if R2_* unset)
set -euo pipefail
H="${HERMES_HOME:-/mnt/vol/hermes}"; B=/mnt/vol/backup
mkdir -p "$B"

db_backup() {
  for f in state.db kanban.db; do
    [ -f "$H/$f" ] && sqlite3 "$H/$f" ".backup '$B/$f'"
  done
  return 0
}

case "${1:-db}" in
  db) db_backup ;;
  offsite)
    db_backup
    tar czf "$B/hermes-files.tar.gz" -C "$H" \
      --exclude='./state.db*' --exclude='./kanban.db*' --exclude='./logs' --exclude='./cache' \
      --exclude='./sandboxes' --exclude='./image_cache' --exclude='./audio_cache' \
      --exclude='*_cache.json' --exclude='*.lock' --exclude='*.pid' .
    for v in R2_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET; do
      if [ -z "${!v:-}" ]; then echo "backup: $v not set, skipping Cloudflare R2 upload"; exit 0; fi
    done
    export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
           RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" \
           RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" \
           RCLONE_CONFIG_R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com" \
           RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true
    dest="R2:${R2_BUCKET}/hermes/$(date -u +%F)"
    rclone copy "$B" "$dest" --include 'state.db' --include 'kanban.db' --include 'hermes-files.tar.gz'
    rclone delete "R2:${R2_BUCKET}/hermes" --min-age "${R2_RETENTION:-14d}"
    rclone rmdirs "R2:${R2_BUCKET}/hermes" --leave-root || true
    ;;
  *) echo "usage: backup.sh db|offsite" >&2; exit 2 ;;
esac
