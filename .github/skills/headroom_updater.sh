#!/usr/bin/env bash
# headroom_updater.sh — Met à jour history/, knowledge/ et plan.md puis commit+push
# Usage : bash headroom_updater.sh [--end-session]
# Cadence recommandée : toutes les 30 min via systemd timer
set -euo pipefail

REPO_ROOT="/home/yves/ops/my_git/copilot-ops"
GITHUB_DIR="${REPO_ROOT}/.github"
HISTORY_DIR="${GITHUB_DIR}/history"
KNOWLEDGE_DIR="${GITHUB_DIR}/knowledge"
LOG_FILE="${KNOWLEDGE_DIR}/headroom_updates.log"
PROXY_URL="${HEADROOM_PROXY_URL:-http://localhost:8787}"
END_SESSION="${1:-}"

TODAY="$(date -u +%Y-%m-%d)"
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HISTORY_FILE="${HISTORY_DIR}/${TODAY}.md"

log() { echo "[$(date -u +%H:%M:%SZ)] $*" | tee -a "${LOG_FILE}"; }

# ── 1. Stats Headroom ─────────────────────────────────────────────────────────
STATS_JSON=""
if command -v curl >/dev/null 2>&1; then
  STATS_JSON="$(curl -sS --max-time 3 "${PROXY_URL}/stats" 2>/dev/null || true)"
fi

if echo "${STATS_JSON}" | python3 -c "import sys,json; json.load(sys.stdin)" >/dev/null 2>&1; then
  EFFICACITE="$(echo "${STATS_JSON}" | jq -r '.efficiency_pct // "n/a"')"
  NB_REQUETES="$(echo "${STATS_JSON}" | jq -r '.requests // .total_requests // "0"')"
  TOKENS_SAVED="$(echo "${STATS_JSON}" | jq -r '.tokens.saved // .tokens_saved // "0"')"
  INBOUND="$(echo "${STATS_JSON}" | jq -r '.inbound_total // .proxy_inbound_total // "0"')"
  ETAT_HEADROOM="ok"
else
  EFFICACITE="n/a"
  NB_REQUETES="0"
  TOKENS_SAVED="0"
  INBOUND="0"
  ETAT_HEADROOM="proxy absent ou non démarré"
fi

# ── 2. Git context ────────────────────────────────────────────────────────────
cd "${REPO_ROOT}"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
GIT_CHANGES="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

# ── 3. Sync plan.md depuis session-state ─────────────────────────────────────
PLAN_SRC="$(ls -t /home/yves/.copilot/session-state/*/plan.md 2>/dev/null | head -1 || true)"
if [ -n "${PLAN_SRC}" ]; then
  PLAN_DST="${REPO_ROOT}/plan.md"
  if ! cmp -s "${PLAN_SRC}" "${PLAN_DST}" 2>/dev/null; then
    cp "${PLAN_SRC}" "${PLAN_DST}"
    log "plan.md synced from ${PLAN_SRC}"
  fi
fi

# ── 4. Créer ou mettre à jour le fichier history du jour ─────────────────────
if [ ! -f "${HISTORY_FILE}" ]; then
  cat > "${HISTORY_FILE}" <<FRONTMATTER
---
date: ${TODAY}
tags: [history, journal]
status: active
project: copilot-ops
type: journal
---

# Session ${TODAY}

---

<!-- HISTORY_AUTO_START -->
<!-- HISTORY_AUTO_END -->
FRONTMATTER
  log "Nouveau fichier history créé : ${HISTORY_FILE}"
fi

# Détecter si c'est une fin de session
SESSION_STATUS="en cours"
if [ "${END_SESSION}" = "--end-session" ]; then
  SESSION_STATUS="terminée"
fi

# Construire le bloc HISTORY_AUTO
AUTO_BLOCK="<!-- HISTORY_AUTO_START -->
## Méta

### Green Stats
- etat: ${ETAT_HEADROOM}
- efficacite_estimee_pct: ${EFFICACITE}
- total_requetes: ${NB_REQUETES}
- total_tokens_saved: ${TOKENS_SAVED}
- proxy_inbound_total: ${INBOUND}

### Notes de session
- session_status: ${SESSION_STATUS}
- branche_active: ${GIT_BRANCH}
- changements_git_en_cours: ${GIT_CHANGES}
- updated_at_utc: ${NOW_UTC}
- proxy_url: ${PROXY_URL}
- interval_seconds: 1800
<!-- HISTORY_AUTO_END -->"

# Remplacer le bloc dans le fichier history
TMP="$(mktemp)"
python3 - "${HISTORY_FILE}" "${TMP}" <<'PYEOF'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
content = open(src).read()
block = open('/dev/stdin').read()  # lu depuis stdin plus bas
open(dst, 'w').write(content)
PYEOF

python3 - "${HISTORY_FILE}" <<PYEOF
import sys, re
path = "${HISTORY_FILE}"
content = open(path).read()
new_block = """${AUTO_BLOCK}"""
content = re.sub(
    r'<!-- HISTORY_AUTO_START -->.*?<!-- HISTORY_AUTO_END -->',
    new_block,
    content,
    flags=re.DOTALL
)
open(path, 'w').write(content)
PYEOF

log "history/${TODAY}.md mis à jour (session: ${SESSION_STATUS})"

# ── 5. Commit + push ──────────────────────────────────────────────────────────
cd "${REPO_ROOT}"
git add \
  ".github/history/${TODAY}.md" \
  ".github/knowledge/headroom_updates.log" \
  "plan.md" 2>/dev/null || true

# Ajouter les fichiers knowledge/*.md modifiés
git add ".github/knowledge/" 2>/dev/null || true
git add ".github/yves/" 2>/dev/null || true
git add ".github/instructions/" 2>/dev/null || true

if git diff --staged --quiet; then
  log "Aucun changement à committer"
  exit 0
fi

MSG="chore: auto-update history+knowledge (${NOW_UTC})"
if [ "${END_SESSION}" = "--end-session" ]; then
  MSG="chore: end-of-session update (${NOW_UTC})"
fi

git commit -m "${MSG}" \
  --author="Copilot <223556219+Copilot@users.noreply.github.com>" \
  --no-verify 2>/dev/null || true

git push origin "${GIT_BRANCH}" 2>/dev/null || true

log "Commit+push OK : ${MSG}"
