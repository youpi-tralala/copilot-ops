#!/usr/bin/env bash
# sync-plan.sh — copie le plan de session le plus récent dans le repo et commit si modifié
set -euo pipefail

# trouver le plan le plus récent dans session-state
SRC=$(ls -t /home/yves/.copilot/session-state/*/plan.md 2>/dev/null | head -1 || true)
if [ -z "${SRC}" ]; then
  echo "No plan.md found in session-state."
  exit 0
fi
DST="/home/yves/ops/my_git/copilot-ops/plan.md"

# comparer
if [ -f "${DST}" ] && cmp -s "${SRC}" "${DST}"; then
  echo "No changes in plan.md"
  exit 0
fi

# copier
cp "${SRC}" "${DST}"
cd /home/yves/ops/my_git/copilot-ops

# commit only if changes
if git add plan.md && git diff --staged --quiet; then
  echo "No staged changes after add"
  exit 0
fi

git commit -m "chore: sync plan.md (auto)" --author="Copilot <223556219+Copilot@users.noreply.github.com>" || true
# push (ignore failure)
git push origin main || true

echo "plan.md synced from ${SRC} to ${DST}"
