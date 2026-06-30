#!/usr/bin/env bash
# end-session.sh — Hook de fin de session Copilot
# À appeler manuellement ou depuis bootstrap via trap EXIT
# Usage : bash .github/scripts/end-session.sh
set -euo pipefail

REPO_ROOT="/home/yves/ops/my_git/copilot-ops"
UPDATER="${REPO_ROOT}/.github/scripts/headroom_updater.sh"

echo "=== FIN DE SESSION Copilot ==="

# Valider le frontmatter des fichiers .md modifiés
CHANGED_MD=$(git -C "${REPO_ROOT}" diff --name-only HEAD 2>/dev/null | grep '\.md$' || true)
if [ -n "${CHANGED_MD}" ]; then
  echo "Validation frontmatter des fichiers modifiés..."
  while IFS= read -r f; do
    bash "${REPO_ROOT}/.github/scripts/validate-frontmatter.sh" "${REPO_ROOT}/${f}" 2>/dev/null || \
      echo "⚠  frontmatter invalide : ${f}"
  done <<< "${CHANGED_MD}"
fi

# Mise à jour finale (flag --end-session)
bash "${UPDATER}" --end-session

echo "=== Session terminée et enregistrée ==="
