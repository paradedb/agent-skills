#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 OUTPUT_PATH [SKILL_FILE] [EXAMPLES_FILE]" >&2
  exit 1
fi

OUTPUT_PATH=$1
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SKILL_FILE=${2:-"$ROOT_DIR/SKILL.md"}
EXAMPLES_FILE=${3:-"$ROOT_DIR/EXAMPLES.md"}

if [[ ! -f "$SKILL_FILE" ]]; then
  echo "error: missing skill file: $SKILL_FILE" >&2
  exit 1
fi

if [[ ! -f "$EXAMPLES_FILE" ]]; then
  echo "error: missing examples file: $EXAMPLES_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

{
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    !in_frontmatter {
      if (!started && $0 == "") {
        next
      }
      started = 1
      print
    }
  ' "$SKILL_FILE"
  printf '\n\n'
  cat "$EXAMPLES_FILE"
} > "$OUTPUT_PATH"
