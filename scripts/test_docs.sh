#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

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

assert_not_contains() {
  local needle=$1
  local file=$2

  if grep -Fq "$needle" "$file"; then
    fail "did not expect '$needle' in $file"
  fi
}

cd "$ROOT_DIR"

npx -y markdownlint-cli2 README.md SKILL.md EXAMPLES.md

assert_contains ".github/copilot-instructions.md" README.md
assert_not_contains "github.copilot.chat.codeGeneration.instructions" README.md

OUTPUT_FILE="$TMP_DIR/.github/copilot-instructions.md"
"$ROOT_DIR/scripts/render_copilot_instructions.sh" "$OUTPUT_FILE"

[[ -s "$OUTPUT_FILE" ]] || fail "rendered Copilot instructions file is empty"

if [[ $(head -n 1 "$OUTPUT_FILE") != "# ParadeDB Skill" ]]; then
  fail "rendered Copilot instructions do not start with the skill heading"
fi

assert_contains "# ParadeDB Skill" "$OUTPUT_FILE"
assert_contains "## Response Guidelines" "$OUTPUT_FILE"
assert_contains "## Network Failure Rules (Mandatory)" "$OUTPUT_FILE"
assert_contains "# ParadeDB Example Prompts" "$OUTPUT_FILE"
assert_contains "## Ask For Structured Answers" "$OUTPUT_FILE"
assert_contains "Use ParadeDB docs from https://docs.paradedb.com/llms-full.txt." \
  "$OUTPUT_FILE"

echo "Docs validation passed."
