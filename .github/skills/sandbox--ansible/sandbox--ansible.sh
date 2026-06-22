#!/usr/bin/env bash
# sandbox.sh — Teste un playbook Ansible dans un container Docker éphémère sur code-vm
# Connexion : docker exec (pas SSH — plus simple, plus fiable)
# Usage : bash sandbox.sh <chemin_du_projet_ansible> [nom_du_playbook.yml]
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
VM_USER="copilot"
VM_IP="192.168.56.10"
VM_KEY="${HOME}/.ssh/copilot@code-vm"
PLAYBOOK_DIR="${1:?Usage: sandbox.sh <chemin_du_projet_ansible> [playbook.yml]}"
PLAYBOOK_FILE="${2:-site.yml}"

TIMESTAMP=$(date +%s)
CONTAINER_NAME="sandbox-${TIMESTAMP}"
REMOTE_DIR="/home/copilot/sandbox_${TIMESTAMP}"

# ── Helpers ───────────────────────────────────────────────────────────────────
vm_ssh() { ssh -i "$VM_KEY" -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" "$@"; }
vm_scp() { scp -i "$VM_KEY" -o StrictHostKeyChecking=no -r "$@"; }

cleanup() {
  echo ""
  echo "🧹  Nettoyage du sandbox..."
  vm_ssh "docker rm -f ${CONTAINER_NAME} 2>/dev/null; rm -rf ${REMOTE_DIR}" || true
}
trap cleanup EXIT

# ── 1. Copier le projet sur la VM ─────────────────────────────────────────────
echo "📦  Copie vers code-vm:${REMOTE_DIR}..."
vm_ssh "mkdir -p ${REMOTE_DIR}"
vm_scp "${PLAYBOOK_DIR}/." "${VM_USER}@${VM_IP}:${REMOTE_DIR}/"

# ── 2. Lancer le container avec le projet monté ───────────────────────────────
echo "🐳  Démarrage du container ${CONTAINER_NAME}..."
vm_ssh "docker run -d \
  --name ${CONTAINER_NAME} \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v ${REMOTE_DIR}:/ansible \
  debian:bookworm \
  sleep infinity"

# ── 3. Installer Ansible dans le container ────────────────────────────────────
echo "📥  Installation d'Ansible (apt)..."
vm_ssh "docker exec ${CONTAINER_NAME} bash -c '
  apt-get update -qq 2>&1 | tail -1 &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible python3 sudo 2>&1 | tail -3
'"

# ── 4. Préparer l'inventory local et la structure de rôle ────────────────────
echo "📋  Préparation de l'inventory..."
ROLE_NAME=$(basename "${PLAYBOOK_DIR}")
vm_ssh "
  mkdir -p ${REMOTE_DIR}/roles &&
  ln -sfn /ansible ${REMOTE_DIR}/roles/${ROLE_NAME} &&
  cat > ${REMOTE_DIR}/inventory_sandbox.ini << 'EOF'
[all]
localhost ansible_connection=local
EOF
"

# ── 5. Exécuter le playbook via docker exec ───────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "🚀  Exécution : ${PLAYBOOK_FILE}"
echo "══════════════════════════════════════════"
vm_ssh "docker exec ${CONTAINER_NAME} bash -c '
  cd /ansible &&
  ansible-playbook -i inventory_sandbox.ini --connection=local ${PLAYBOOK_FILE}
'" && RESULT=0 || RESULT=$?

# ── 6. Rapport final ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
if [ "$RESULT" -eq 0 ]; then
  echo "✅  Playbook exécuté avec succès"
else
  echo "❌  Playbook terminé avec des erreurs (exit code: ${RESULT})"
fi
echo "══════════════════════════════════════════"

exit $RESULT
