#!/usr/bin/env bash
set -euo pipefail

# headroom_updater.sh
# Récupère /stats depuis le proxy Headroom, écrit un résumé human-readable et le JSON détaillé
# dans .github/history/YYYY-MM-DD.headroom.{txt,json}, et logge dans knowledge/headroom_updates.log
# Interval configurable via HEADROOM_UPDATE_INTERVAL (secondes). Défaut : 300 (5min).

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HISTORY_DIR="$ROOT_DIR/.github/history"
KNOWLEDGE_DIR="$ROOT_DIR/.github/knowledge"
INSTR_DIR="$ROOT_DIR/.github/instructions"
INTERVAL="${HEADROOM_UPDATE_INTERVAL:-300}"
PROXY_URL="http://localhost:8787"

mkdir -p "$HISTORY_DIR" "$KNOWLEDGE_DIR"

log(){ echo "$(date -u +%FT%TZ) $*"; }

while true; do
  TS=$(date -u +%FT%TZ)
  DATE=$(date +%F)
  JSON_FILE="$HISTORY_DIR/${DATE}.headroom.json"
  TXT_FILE="$HISTORY_DIR/${DATE}.headroom.txt"
  LOG_FILE="$KNOWLEDGE_DIR/headroom_updates.log"
  STATUS=0

  if ! command -v headroom >/dev/null 2>&1; then
    log "headroom not installed" >> "$LOG_FILE"
    sleep "$INTERVAL"
    continue
  fi
  if ! command -v jq >/dev/null 2>&1; then
    log "jq not installed; aborting update" >> "$LOG_FILE"
    sleep "$INTERVAL"
    continue
  fi

  # Fetch stats (silent failure yields empty JSON)
  STATS=$(curl -sS "$PROXY_URL/stats" || echo '{}')

  # Save pretty JSON
  echo "$STATS" | jq '.' > "$JSON_FILE" 2>/dev/null || echo '{}' > "$JSON_FILE"

  # Extract key fields (use defaults when absent)
  TOKENS_SAVED=$(echo "$STATS" | jq -r '.tokens.saved // 0' 2>/dev/null || echo 0)
  REQ_TOTAL=$(echo "$STATS" | jq -r '.requests.total // 0' 2>/dev/null || echo 0)
  PROXY_INBOUND=$(echo "$STATS" | jq -r '.proxy_inbound.total // 0' 2>/dev/null || echo 0)

  # Create a human-readable summary
  SUMMARY="Headroom — tokens_saved: ${TOKENS_SAVED}, requests_total: ${REQ_TOTAL}, proxy_inbound_total: ${PROXY_INBOUND} (updated: ${TS})"
  echo "$SUMMARY" > "$TXT_FILE"

  # Append to knowledge log
  echo "${TS} | ${SUMMARY}" >> "$LOG_FILE"

  # Update a generated status file under instructions for traceability
  echo "# Generated updates\n# last_update: ${TS}\n${SUMMARY}" > "$INSTR_DIR/_generated_updates.md"

  log "updated headroom stats: ${SUMMARY}" >> "$LOG_FILE"

  sleep "$INTERVAL"
done
