#!/usr/bin/env bash
# check-paths.sh — Vérifie qu'un chemin est dans la whitelist access.instructions.md
# Usage : bash check-paths.sh <chemin_à_vérifier>
# Exit 0 = autorisé, Exit 1 = interdit
set -euo pipefail

TARGET="${1:?Usage: check-paths.sh <chemin_à_vérifier>}"

# Whitelist des chemins autorisés en écriture — alignée avec access.instructions.md
ALLOWED_PATHS=(
  "/home/yves/ops/my_git/copilot-ops"
  "/home/yves/ops/lab/copilot_rwx"
  "/mnt/c/Users/YvesBOCCUNI/OneDrive - ONEPOINT/Bureau/ops/my_git/copilot-ops"
  "/mnt/c/Users/YvesBOCCUNI/OneDrive - ONEPOINT/Bureau/ops/lab/copilot_rwx"
  "/home/copilot"          # répertoire éphémère sandbox sur code-vm
)

# Normaliser le chemin cible
TARGET_REAL=$(realpath -m "${TARGET}" 2>/dev/null || echo "${TARGET}")

for allowed in "${ALLOWED_PATHS[@]}"; do
  if [[ "${TARGET_REAL}" == "${allowed}"* ]]; then
    exit 0
  fi
done

echo "🚫  GUARDRAIL : chemin non autorisé"
echo "    Chemin demandé : ${TARGET_REAL}"
echo "    Chemins autorisés :"
for p in "${ALLOWED_PATHS[@]}"; do echo "      - ${p}"; done
echo ""
echo "    Mettre à jour access.instructions.md si ce chemin doit être ajouté."
exit 1
