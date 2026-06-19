#!/usr/bin/env bash
# sandbox.sh — Teste un playbook Ansible dans un container Docker éphémère sur code-vm
# Usage : bash sandbox.sh <chemin_du_projet_ansible>
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
VM_USER="copilot"
VM_IP="192.168.56.10"
VM_KEY="${HOME}/.ssh/copilot@code-vm"
PLAYBOOK_DIR="${1:?Usage: sandbox.sh <chemin_du_projet_ansible>}"
PLAYBOOK_FILE="${2:-playbook_harden_servers.yml}"

TIMESTAMP=$(date +%s)
CONTAINER_NAME="sandbox-${TIMESTAMP}"
REMOTE_DIR="/home/copilot/sandbox_${TIMESTAMP}"

# ── Helpers ───────────────────────────────────────────────────────────────────
vm_ssh() { ssh -i "$VM_KEY" -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" "$@"; }
vm_scp() { scp -i "$VM_KEY" -o StrictHostKeyChecking=no -r "$@"; }

cleanup() {
  echo ""
  echo "──────────────────────────────────────────"
  echo "🧹  Nettoyage du sandbox..."
  vm_ssh "docker rm -f ${CONTAINER_NAME} 2>/dev/null || true; rm -rf ${REMOTE_DIR}" || true
  echo "✅  Container et fichiers temporaires supprimés"
}
trap cleanup EXIT

# ── 1. Copier le projet sur la VM ─────────────────────────────────────────────
echo "📦  Copie du projet vers code-vm:${REMOTE_DIR}..."
vm_ssh "mkdir -p ${REMOTE_DIR}"
vm_scp "${PLAYBOOK_DIR}/." "${VM_USER}@${VM_IP}:${REMOTE_DIR}/"

# ── 2. Lancer le container Docker ─────────────────────────────────────────────
echo "🐳  Démarrage du container ${CONTAINER_NAME}..."
vm_ssh "docker run -d \
  --name ${CONTAINER_NAME} \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  debian:bookworm \
  sleep infinity"

# Installation synchrone dans le container (bloque jusqu'à la fin)
echo "📥  Installation des paquets dans le container (peut prendre ~60s)..."
vm_ssh "docker exec ${CONTAINER_NAME} bash -c '
  apt-get update -qq &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    openssh-server python3 sudo systemd systemd-sysv 2>&1
'"

# ── 3. Injecter la clé publique copilot dans le container ─────────────────────
echo "🔑  Injection de la clé SSH dans le container..."
# Copier la clé via docker cp (évite les problèmes d'escaping multi-niveaux)
vm_ssh "mkdir -p /tmp/sandbox_${TIMESTAMP}"
# Copier clé publique et privée depuis WSL vers la VM
vm_scp "${HOME}/.ssh/copilot@code-vm.pub" "${VM_USER}@${VM_IP}:/tmp/sandbox_${TIMESTAMP}/authorized_keys"
vm_scp "${HOME}/.ssh/copilot@code-vm" "${VM_USER}@${VM_IP}:/tmp/sandbox_${TIMESTAMP}/sandbox_key"
vm_ssh "chmod 600 /tmp/sandbox_${TIMESTAMP}/sandbox_key"
vm_ssh "
  docker exec ${CONTAINER_NAME} mkdir -p /root/.ssh &&
  docker cp /tmp/sandbox_${TIMESTAMP}/authorized_keys ${CONTAINER_NAME}:/root/.ssh/authorized_keys &&
  docker exec ${CONTAINER_NAME} chmod 700 /root/.ssh &&
  docker exec ${CONTAINER_NAME} chmod 600 /root/.ssh/authorized_keys &&
  docker exec ${CONTAINER_NAME} bash -c 'echo \"PermitRootLogin yes\" >> /etc/ssh/sshd_config' &&
  docker exec ${CONTAINER_NAME} bash -c 'mkdir -p /run/sshd && /usr/sbin/sshd' &&
  rm -rf /tmp/sandbox_${TIMESTAMP}
"

# ── 4. Récupérer l'IP du container ────────────────────────────────────────────
CONTAINER_IP=$(vm_ssh "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_NAME}")
echo "🌐  IP container : ${CONTAINER_IP}"

# ── 5. Attendre que SSH soit prêt ─────────────────────────────────────────────
echo "⏳  Attente SSH dans le container..."
vm_ssh "for i in \$(seq 1 20); do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 root@${CONTAINER_IP} 'exit' 2>/dev/null && break
  sleep 2
done"

# ── 6. Préparer l'inventory et la structure de rôle ──────────────────────────
echo "📋  Préparation de l'inventory Ansible..."
# Nettoyer known_hosts pour éviter le conflit avec un container précédent à la même IP
vm_ssh "ssh-keygen -f /home/copilot/.ssh/known_hosts -R ${CONTAINER_IP} 2>/dev/null || true"

vm_ssh "cat > ${REMOTE_DIR}/inventory_sandbox.ini << EOF
[all]
sandbox ansible_host=${CONTAINER_IP} ansible_user=root ansible_ssh_private_key_file=/tmp/sandbox_${TIMESTAMP}/sandbox_key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF"

# Le playbook appelle 'role: ansible-role-harden-servers'
# La structure du projet EST le rôle → créer le lien attendu par Ansible
vm_ssh "
  mkdir -p ${REMOTE_DIR}/roles &&
  ln -sfn ${REMOTE_DIR} ${REMOTE_DIR}/roles/ansible-role-harden-servers
"

# ── 7. Exécuter le playbook ────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "🚀  Exécution du playbook : ${PLAYBOOK_FILE}"
echo "══════════════════════════════════════════"
vm_ssh "cd ${REMOTE_DIR} && ansible-playbook -i inventory_sandbox.ini ${PLAYBOOK_FILE}" && RESULT=0 || RESULT=$?

# ── 8. Rapport final ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
if [ "$RESULT" -eq 0 ]; then
  echo "✅  Playbook exécuté avec succès"
else
  echo "❌  Playbook terminé avec des erreurs (exit code: ${RESULT})"
fi
echo "══════════════════════════════════════════"

exit $RESULT
