#!/usr/bin/env bash
set -euo pipefail

# headroom_updater.sh
# Met à jour .github/history/YYYY-MM-DD.md (fichier consolidé unique)
# avec le template HISTORY_AUTO standardisé.
# Journal horodaté: .github/knowledge/headroom_updates.log

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HISTORY_DIR="$REPO_DIR/.github/history"
KNOWLEDGE_DIR="$REPO_DIR/.github/knowledge"
INTERVAL="${HEADROOM_UPDATE_INTERVAL:-1800}"
PROXY_URL="${HEADROOM_PROXY_URL:-http://localhost:8787}"
LOG_FILE="$KNOWLEDGE_DIR/headroom_updates.log"
RUN_ONCE="${HEADROOM_UPDATER_ONCE:-0}"
SESSION_DECISIONS="${SESSION_DECISIONS:-non renseigné}"
SESSION_ISSUES="${SESSION_ISSUES:-non renseigné}"
SESSION_PROGRESS="${SESSION_PROGRESS:-non renseigné}"
SESSION_SOURCES="${SESSION_SOURCES:-.github/instructions/sources.instructions.md}"
SUBJECT1_TITLE="${SUBJECT1_TITLE:-Sujets abordé 1}"
SUBJECT2_TITLE="${SUBJECT2_TITLE:-Sujets abordé 2}"

mkdir -p "$HISTORY_DIR" "$KNOWLEDGE_DIR"

log() { echo "$(date -u +%FT%TZ) $*" >> "$LOG_FILE"; }

fetch_stats_json() {
  if command -v rtk >/dev/null 2>&1; then
    rtk curl -sS "${PROXY_URL}/stats"
  else
    curl -sS "${PROXY_URL}/stats"
  fi
}

render_managed_block() {
  local ts="$1"
  local req_total="$2"
  local tokens_saved="$3"
  local proxy_inbound="$4"
  local efficiency_pct="$5"
  local use_cases="$6"
  local total_sessions="$7"
  local total_tokens="$8"

  cat <<EOF
<!-- HISTORY_AUTO_START -->
## Méta

### Green Stats 
- outil utilisés: headroom, rtk
- efficacite_estimee_pct: ${efficiency_pct}
- total_number_of_sessions: ${total_sessions}
- total_requetes: ${req_total}
- total_tokens: ${total_tokens}
- total_tokens_saved: ${tokens_saved}
- cas_usage_observes: ${use_cases}
- proxy_inbound_total: ${proxy_inbound}

## ${SUBJECT1_TITLE}

### Sources consultées (interne / externe)
- ${SESSION_SOURCES}

### Actions réalisées
- ${SESSION_PROGRESS}
- décisions: ${SESSION_DECISIONS}

### Problèmes / Blocages
- ${SESSION_ISSUES}

### Prochaines actions recommandées
- Continuer la mise à jour périodique du fichier history consolidé.

## ${SUBJECT2_TITLE}

### Sources consultées (interne / externe)
- non renseigné

### Actions réalisées
- non renseigné

### Problèmes / Blocages
- non renseigné

### Prochaines actions recommandées
- non renseigné
<!-- HISTORY_AUTO_END -->
EOF
}

ensure_base_file() {
  local date="$1"
  local md_file="$2"
  if [ ! -f "$md_file" ]; then
    cat > "$md_file" <<EOF
# Session ${date}

---
EOF
  fi
}

replace_managed_block() {
  local md_file="$1"
  local block="$2"

  if grep -q '<!-- HISTORY_AUTO_START -->' "$md_file"; then
    awk '
      BEGIN { skip=0 }
      /<!-- HISTORY_AUTO_START -->/ { skip=1; next }
      /<!-- HISTORY_AUTO_END -->/   { skip=0; next }
      skip==0 { print }
    ' "$md_file" > "${md_file}.tmp"
    mv "${md_file}.tmp" "$md_file"
  fi

  awk -v block="$block" '
    BEGIN { inserted=0 }
    {
      print
      if (!inserted && $0 ~ /^---$/) {
        print ""
        print block
        print ""
        inserted=1
      }
    }
    END {
      if (!inserted) {
        print ""
        print "---"
        print ""
        print block
      }
    }
  ' "$md_file" > "${md_file}.tmp"
  mv "${md_file}.tmp" "$md_file"
}

while true; do
  TS="$(date -u +%FT%TZ)"
  DATE="$(date +%F)"
  MD_FILE="$HISTORY_DIR/${DATE}.md"
  HEADROOM_STATE="ok"

  case "$PROXY_URL" in
    http://localhost:*|http://127.0.0.1:*) ;;
    *)
      if [ "${HEADROOM_ALLOW_REMOTE:-0}" != "1" ]; then
        log "proxy_url non-localhost refusé (${PROXY_URL})"
        exit 1
      fi
      ;;
  esac

  if ! command -v jq >/dev/null 2>&1; then
    log "jq absent - impossible de parser les stats"
    exit 1
  fi

  if ! command -v headroom >/dev/null 2>&1; then
    HEADROOM_STATE="absent"
    PARSED_STATS='{}'
  else
    if RAW_STATS="$(fetch_stats_json 2>/dev/null)"; then
      if PARSED_STATS="$(printf '%s' "$RAW_STATS" | jq '.' 2>/dev/null)"; then
        HEADROOM_STATE="ok"
      else
        HEADROOM_STATE="stats_invalid_json"
        PARSED_STATS='{}'
      fi
    else
      HEADROOM_STATE="proxy_unreachable"
      PARSED_STATS='{}'
    fi
  fi

  TOKENS_SAVED="$(printf '%s' "$PARSED_STATS" | jq -r '.tokens.saved // 0')"
  REQ_TOTAL="$(printf '%s' "$PARSED_STATS" | jq -r '.requests.total // 0')"
  PROXY_INBOUND="$(printf '%s' "$PARSED_STATS" | jq -r '.proxy_inbound.total // 0')"
  EFFICIENCY_PCT="$(printf '%s' "$PARSED_STATS" | jq -r '.tokens.savings_percent // .summary.cost.savings_pct // 0')"
  USE_CASES="$(printf '%s' "$PARSED_STATS" | jq -r '((.proxy_inbound.by_path // {}) | keys) as $k | if ($k|length) > 0 then ($k|join(", ")) else "non observe" end')"
  TOTAL_SESSIONS="$(find "$HISTORY_DIR" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
  TOTAL_TOKENS="$(printf '%s' "$PARSED_STATS" | jq -r '.tokens.input // 0')"

  ensure_base_file "$DATE" "$MD_FILE"
  BLOCK="$(render_managed_block "$TS" "$REQ_TOTAL" "$TOKENS_SAVED" "$PROXY_INBOUND" "$EFFICIENCY_PCT" "$USE_CASES" "$TOTAL_SESSIONS" "$TOTAL_TOKENS")"
  replace_managed_block "$MD_FILE" "$BLOCK"

  log "update ok date=${DATE} headroom=${HEADROOM_STATE} total_sessions=${TOTAL_SESSIONS} requests_total=${REQ_TOTAL} tokens_saved=${TOKENS_SAVED} proxy_inbound_total=${PROXY_INBOUND}"

  if [ "$RUN_ONCE" = "1" ]; then
    exit 0
  fi

  sleep "$INTERVAL"
done
