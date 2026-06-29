#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"

STATUS_ALLOWED_REGEX='^(active|draft|archived)$'
TYPE_ALLOWED_REGEX='^(instructions|connaissance|ressource|journal|rapport|runbook)$'

FAIL=0

iter_files() {
  if [ -f "$TARGET" ]; then
    printf '%s\n' "$TARGET"
  else
    find "$TARGET" -type f -name '*.md' | sort
  fi
}

while IFS= read -r file; do
  # Frontmatter block.
  if ! head -n 1 "$file" | grep -q '^---$'; then
    echo "Missing frontmatter start: $file"
    FAIL=1
    continue
  fi

  if ! awk 'NR==1{infm=1;next} infm && /^---$/{found=1; exit} END{exit(found?0:1)}' "$file" >/dev/null; then
    echo "Missing frontmatter end: $file"
    FAIL=1
    continue
  fi

  FM="$(awk 'NR==1{infm=1;next} infm && /^---$/{exit} infm{print}' "$file")"

  for k in date tags status project type; do
    if ! printf '%s\n' "$FM" | grep -q "^${k}:"; then
      echo "Missing frontmatter key '${k}': $file"
      FAIL=1
    fi
  done

  status_value="$(printf '%s\n' "$FM" | sed -n 's/^status:[[:space:]]*//p' | head -1)"
  type_value="$(printf '%s\n' "$FM" | sed -n 's/^type:[[:space:]]*//p' | head -1)"

  if [ -n "$status_value" ] && ! printf '%s\n' "$status_value" | grep -Eq "$STATUS_ALLOWED_REGEX"; then
    echo "Invalid status '$status_value': $file"
    FAIL=1
  fi

  if [ -n "$type_value" ] && ! printf '%s\n' "$type_value" | grep -Eq "$TYPE_ALLOWED_REGEX"; then
    echo "Invalid type '$type_value': $file"
    FAIL=1
  fi

done < <(iter_files)

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

echo "Frontmatter validation passed."
