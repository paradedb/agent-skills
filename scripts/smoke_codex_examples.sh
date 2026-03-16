#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RUNNER=${RUNNER:-codex}
TMP_DIR=$(mktemp -d)
OUTPUT_FILE=${OUTPUT_FILE:-"$TMP_DIR/codex-smoke-output.md"}
RUN_LOG="$TMP_DIR/codex-smoke.log"
MAX_ATTEMPTS=${MAX_ATTEMPTS:-36}
SLEEP_SECONDS=${SLEEP_SECONDS:-5}

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

fail() {
  echo "error: $*" >&2
  exit 1
}

assert_contains() {
  local needle=$1
  local file=$2

  if ! grep -Fq "$needle" "$file"; then
    fail "expected '$needle' in $file"
  fi
}

if ! command -v "$RUNNER" >/dev/null 2>&1; then
  fail "missing agent runner: $RUNNER"
fi

PROMPT=$(cat <<'EOF'
Read SKILL.md and EXAMPLES.md in the current directory.
Use ParadeDB docs from https://docs.paradedb.com/llms-full.txt.
Assume products(id bigint primary key, name text, description text, category text).
Return only a markdown document with these headings in order:
## Runnable SQL
## Short Explanation
## Version Assumptions
## Edge Cases and Tradeoffs
Create a BM25 index for full-text search on my products table.
EOF
)

"$RUNNER" --search exec --ephemeral --sandbox read-only -C "$ROOT_DIR" \
  -o "$OUTPUT_FILE" "$PROMPT" >"$RUN_LOG" 2>&1 &

RUNNER_PID=$!

for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1)); do
  if [[ -s "$OUTPUT_FILE" ]]; then
    break
  fi

  if ! kill -0 "$RUNNER_PID" 2>/dev/null; then
    break
  fi

  sleep "$SLEEP_SECONDS"
done

if [[ ! -s "$OUTPUT_FILE" ]]; then
  wait "$RUNNER_PID" || true
  cat "$RUN_LOG" >&2
  fail "runner did not produce an output file"
fi

assert_contains "## Runnable SQL" "$OUTPUT_FILE"
assert_contains "## Short Explanation" "$OUTPUT_FILE"
assert_contains "## Version Assumptions" "$OUTPUT_FILE"
assert_contains "## Edge Cases and Tradeoffs" "$OUTPUT_FILE"
assert_contains "USING bm25" "$OUTPUT_FILE"
assert_contains "CREATE INDEX" "$OUTPUT_FILE"

if kill -0 "$RUNNER_PID" 2>/dev/null; then
  kill "$RUNNER_PID" 2>/dev/null || true
  wait "$RUNNER_PID" 2>/dev/null || true
else
  wait "$RUNNER_PID" || true
fi

echo "Codex smoke test passed. Output: $OUTPUT_FILE"
