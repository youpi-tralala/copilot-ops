#!/usr/bin/env bash
# lint.sh — Valide un projet Ansible avec yamllint + ansible-lint sur code-vm
# Usage : bash lint.sh <chemin_du_projet_ansible>
set -euo pipefail

VM_USER="copilot"
VM_IP="192.168.56.10"
VM_KEY="${HOME}/.ssh/copilot@code-vm"
PROJECT_DIR="${1:?Usage: lint.sh <chemin_du_projet_ansible>}"

TIMESTAMP=$(date +%s)
REMOTE_DIR="/home/copilot/lint_${TIMESTAMP}"

vm_ssh() { ssh -i "$VM_KEY" -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" "$@"; }
vm_scp() { scp -i "$VM_KEY" -o StrictHostKeyChecking=no -r "$@"; }

cleanup() { vm_ssh "rm -rf ${REMOTE_DIR}" || true; }
trap cleanup EXIT

# ── Vérifier que les outils sont disponibles ──────────────────────────────────
vm_ssh "command -v ansible-lint yamllint >/dev/null 2>&1" || {
  echo "⚙️  Installation de ansible-lint et yamllint sur code-vm..."
  vm_ssh "pip3 install ansible-lint yamllint --quiet"
}

# ── Copier le projet ───────────────────────────────────────────────────────────
echo "📦  Copie vers code-vm:${REMOTE_DIR}..."
vm_ssh "mkdir -p ${REMOTE_DIR}"
vm_scp "${PROJECT_DIR}/." "${VM_USER}@${VM_IP}:${REMOTE_DIR}/"

ERRORS=0

# ── yamllint ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "📄  yamllint"
echo "══════════════════════════════════════════"
vm_ssh "find ${REMOTE_DIR} -name '*.yml' -o -name '*.yaml' | \
  xargs yamllint -d relaxed" && echo "✅  yamllint OK" || { echo "❌  yamllint : erreurs détectées"; ERRORS=$((ERRORS+1)); }

# ── ansible-lint ──────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "🔍  ansible-lint"
echo "══════════════════════════════════════════"
vm_ssh "cd ${REMOTE_DIR} && ansible-lint --profile=min" && echo "✅  ansible-lint OK" || { echo "❌  ansible-lint : erreurs détectées"; ERRORS=$((ERRORS+1)); }

# ── Rapport final ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
if [ "$ERRORS" -eq 0 ]; then
  echo "✅  Lint passé — push autorisé"
else
  echo "❌  ${ERRORS} outil(s) en erreur — corriger avant de pusher"
fi
echo "══════════════════════════════════════════"

exit $ERRORS
