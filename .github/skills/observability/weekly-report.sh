#!/usr/bin/env bash
# weekly-report.sh — Synthèse des métriques des 7 derniers fichiers history/
# Usage : bash skills/observability/weekly-report.sh [chemin_history/]
set -euo pipefail

HISTORY_DIR="${1:-$(cd "$(dirname "$0")/../.." && pwd)/history}"
[ -d "$HISTORY_DIR" ] || HISTORY_DIR="$(cd "$(dirname "$0")/../.." && pwd)/history"

if [ ! -d "$HISTORY_DIR" ]; then
  echo "❌  Répertoire history/ introuvable : ${HISTORY_DIR}"
  exit 1
fi

echo ""
echo "══════════════════════════════════════════"
echo "📊  Rapport hebdomadaire — harness Copilot"
echo "══════════════════════════════════════════"

TOTAL_TASKS=0; TOTAL_SUCCESS=0; TOTAL_FAIL=0
FILES_FOUND=0

while IFS= read -r file; do
  FILES_FOUND=$((FILES_FOUND+1))
  DATE=$(basename "$file" .md)

  # Extraire les métriques YAML si présentes
  if grep -q "^metrics:" "$file" 2>/dev/null; then
    tasks=$(grep "taches_realisees:" "$file" | awk '{print $2}' | head -1)
    succes=$(grep "succes:" "$file" | awk '{print $2}' | head -1)
    echecs=$(grep "echecs:" "$file" | awk '{print $2}' | head -1)
    sandbox=$(grep "sandbox_utilise:" "$file" | awk '{print $2}' | head -1)
    lint=$(grep "lint_utilise:" "$file" | awk '{print $2}' | head -1)

    tasks=${tasks:-0}; succes=${succes:-0}; echecs=${echecs:-0}
    TOTAL_TASKS=$((TOTAL_TASKS + tasks))
    TOTAL_SUCCESS=$((TOTAL_SUCCESS + succes))
    TOTAL_FAIL=$((TOTAL_FAIL + echecs))

    printf "  %-12s  tâches:%-3s  ✅:%-3s  ❌:%-3s  sandbox:%-5s  lint:%s\n" \
      "$DATE" "$tasks" "$succes" "$echecs" "$sandbox" "$lint"
  else
    printf "  %-12s  (pas de métriques structurées)\n" "$DATE"
  fi
done < <(find "$HISTORY_DIR" -name "*.md" | sort -r | head -7)

echo "──────────────────────────────────────────"
if [ "$FILES_FOUND" -gt 0 ] && [ "$TOTAL_TASKS" -gt 0 ]; then
  RATE=$((TOTAL_SUCCESS * 100 / TOTAL_TASKS))
  echo "  Total 7j : ${TOTAL_TASKS} tâches — ${TOTAL_SUCCESS} succès — ${TOTAL_FAIL} échecs — taux : ${RATE}%"
else
  echo "  Aucune métrique structurée trouvée."
  echo "  Ajouter une section 'metrics:' en fin de fichier history/ pour activer le suivi."
fi
echo "══════════════════════════════════════════"
