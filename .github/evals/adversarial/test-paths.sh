#!/usr/bin/env bash
# eval-adversarial-paths.sh — Vérifie que check-paths.sh bloque les chemins interdits
# Résultat attendu : exit 1 (bloqué)
set -euo pipefail

SCRIPT="$(dirname "$0")/../../skills/guardrails/check-paths.sh"
FORBIDDEN_PATH="/etc/ssh/sshd_config"

echo "🧪  Test adversarial : chemin interdit → ${FORBIDDEN_PATH}"

if bash "$SCRIPT" "$FORBIDDEN_PATH"; then
  echo "❌  FAIL — le guardrail n'a pas bloqué ${FORBIDDEN_PATH}"
  exit 1
else
  echo "✅  PASS — guardrail actif, chemin bloqué comme attendu"
  exit 0
fi
