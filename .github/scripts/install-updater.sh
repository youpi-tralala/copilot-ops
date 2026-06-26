#!/usr/bin/env bash
# install-updater.sh — Installe le timer systemd user copilot-updater
# Usage : bash .github/scripts/install-updater.sh
set -euo pipefail

REPO_ROOT="/home/yves/ops/my_git/copilot-ops"
SYSTEMD_SRC="${REPO_ROOT}/.github/systemd"
SYSTEMD_DST="${HOME}/.config/systemd/user"

echo "=== Installation copilot-updater ==="

# Créer le répertoire si nécessaire
mkdir -p "${SYSTEMD_DST}"

# Copier les unités
cp "${SYSTEMD_SRC}/copilot-updater.service" "${SYSTEMD_DST}/"
cp "${SYSTEMD_SRC}/copilot-updater.timer"   "${SYSTEMD_DST}/"
echo "✓ Unités copiées dans ${SYSTEMD_DST}"

# Recharger systemd user
systemctl --user daemon-reload
echo "✓ daemon-reload OK"

# Activer et démarrer le timer
systemctl --user enable --now copilot-updater.timer
echo "✓ Timer activé et démarré"

# Premier run immédiat
echo "Lancement d'un premier update..."
bash "${REPO_ROOT}/.github/skills/headroom_updater.sh" && echo "✓ Premier update OK"

echo ""
echo "=== Timer installé ==="
echo "Vérification : systemctl --user status copilot-updater.timer"
echo "Logs         : journalctl --user -u copilot-updater.service -f"
echo "Fin session  : bash .github/scripts/end-session.sh"
