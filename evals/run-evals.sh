#!/usr/bin/env bash
# run-evals.sh — Lance tous les evals et produit un rapport pass/fail
# Usage : bash evals/run-evals.sh
set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
SKIP=0

result() {
  local label="$1" status="$2"
  case "$status" in
    pass) echo "  ✅  PASS — ${label}"; PASS=$((PASS+1)) ;;
    fail) echo "  ❌  FAIL — ${label}"; FAIL=$((FAIL+1)) ;;
    skip) echo "  ⏭️   SKIP — ${label}"; SKIP=$((SKIP+1)) ;;
  esac
}

echo ""
echo "══════════════════════════════════════════"
echo "🧪  Evals harness Copilot CLI"
echo "══════════════════════════════════════════"

# ── Eval adversarial : guardrail check-paths ──────────────────────────────────
echo ""
echo "[ Adversarial ]"
if bash "${EVALS_DIR}/adversarial/test-paths.sh" 2>&1; then
  result "check-paths bloque chemin interdit" pass
else
  result "check-paths bloque chemin interdit" fail
fi

# ── Eval nominal et edge : nécessitent sandbox opérationnel ───────────────────
echo ""
echo "[ Nominal / Edge — sandbox requis ]"
if ssh -i "${HOME}/.ssh/copilot@code-vm" -o StrictHostKeyChecking=no -o ConnectTimeout=3 copilot@192.168.56.10 "docker info" >/dev/null 2>&1; then
  # Sandbox accessible — lancer les playbooks (nécessite sandbox.sh opérationnel)
  result "Nominal : install package (sandbox requis)" skip
  result "Edge : systemd dans container (limite connue)" skip
else
  echo "  ⚠️  code-vm inaccessible — evals sandbox ignorés"
  result "Nominal : install package" skip
  result "Edge : systemd dans container" skip
fi

# ── Rapport final ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  ✅ PASS : ${PASS}  |  ❌ FAIL : ${FAIL}  |  ⏭️  SKIP : ${SKIP}"
echo "══════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
