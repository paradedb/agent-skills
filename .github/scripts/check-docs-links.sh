#!/bin/bash
#
# check-docs-links.sh
#
# Verifies that every docs.paradedb.com URL in this repository resolves, and that every
# doc path the skill tells agents to fetch is still served. The skill is only as good as
# the pages it points at, and a renamed docs page is invisible until an agent 404s on it.

set -uo pipefail

failed=0

check() {
  local url=$1 source=$2 code
  code=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 30 --retry 2 "$url")
  if [[ "$code" == "200" ]]; then
    printf '  ok  %s  (%s)\n' "$url" "$source"
  else
    printf 'FAIL  %s  (%s) -> HTTP %s\n' "$url" "$source" "$code"
    failed=1
  fi
}

echo "Checking docs.paradedb.com URLs referenced in markdown..."
while read -r url; do
  [[ -n "$url" ]] || continue
  check "$url" "markdown link"
done < <(grep -rhoE 'https://docs\.paradedb\.com[^])"'"'"' <>]*' --include='*.md' . |
  sed 's/[.,:;]$//' | grep -v '\$' | sort -u) # drop the templated URL in the embedded script

echo
echo "Checking doc paths the skill fetches..."
while read -r path; do
  [[ -n "$path" ]] || continue
  check "https://docs.paradedb.com/$path" "scripts/paradedb-docs"
done < <(grep -rhoE 'scripts/paradedb-docs [A-Za-z0-9./_-]+\.(md|txt)' --include='*.md' . | awk '{print $2}' | sort -u)

echo
if [[ "$failed" -ne 0 ]]; then
  echo "One or more documentation links are broken."
  exit 1
fi
echo "All documentation links resolve."
