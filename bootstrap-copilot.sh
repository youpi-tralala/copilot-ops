#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTRUCTIONS_FILE="${REPO_ROOT}/.github/copilot-instructions.md"

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap-copilot.sh --ack [--no-headroom] [-- <command> ...]
  ./bootstrap-copilot.sh --print-only

Behavior:
  1. Enforces reading .github/copilot-instructions.md first.
  2. Starts Headroom proxy on localhost:8787 when available.
  3. Runs the provided command after acknowledgement.
EOF
}

print_instructions() {
  if [ ! -f "${INSTRUCTIONS_FILE}" ]; then
    echo "Missing file: ${INSTRUCTIONS_FILE}" >&2
    exit 1
  fi

  local hash_value
  hash_value="$(sha256sum "${INSTRUCTIONS_FILE}" | awk '{print $1}')"

  echo "=== COPILOT BOOTSTRAP ==="
  echo "Read first: .github/copilot-instructions.md"
  echo "sha256: ${hash_value}"
  echo
  if command -v rtk >/dev/null 2>&1; then
    rtk read "${INSTRUCTIONS_FILE}"
  else
    cat "${INSTRUCTIONS_FILE}"
  fi
  echo
}

ACK=0
PRINT_ONLY=0
WITH_HEADROOM=1

while [ $# -gt 0 ]; do
  case "$1" in
    --ack)
      ACK=1
      shift
      ;;
    --print-only)
      PRINT_ONLY=1
      shift
      ;;
    --with-headroom)
      WITH_HEADROOM=1
      shift
      ;;
    --no-headroom)
      WITH_HEADROOM=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

print_instructions

if [ "${PRINT_ONLY}" -eq 1 ]; then
  exit 0
fi

if [ "${ACK}" -ne 1 ]; then
  echo "Refusing to continue without --ack." >&2
  echo "Run: ./bootstrap-copilot.sh --ack -- <command>" >&2
  exit 2
fi

if [ "${WITH_HEADROOM}" -eq 1 ] && command -v headroom >/dev/null 2>&1; then
  if command -v rtk >/dev/null 2>&1; then
    HEADROOM_CHECK_CMD=(rtk curl -sS http://localhost:8787/stats)
  else
    HEADROOM_CHECK_CMD=(curl -sS http://localhost:8787/stats)
  fi

  if ! "${HEADROOM_CHECK_CMD[@]}" >/dev/null 2>&1; then
    setsid headroom proxy --port 8787 >/tmp/headroom-proxy.log 2>&1 < /dev/null &
    sleep 1
  fi
  export OPENAI_BASE_URL="http://localhost:8787/v1"
  export ANTHROPIC_BASE_URL="http://localhost:8787"
fi

if [ $# -gt 0 ]; then
  exec "$@"
fi

echo "Bootstrap complete."
