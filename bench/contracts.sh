#!/usr/bin/env bash
# Derive the effect contract of every library already built under bench/_work
# and write them all into one document.
#
# Why this exists. OCaml 5 has no way to state what effects a library asks its
# callers to handle: that is the whole premise of the problem, since the
# handlers are untyped. So the ecosystem has no such document, and nobody can
# write one by hand and keep it true. This produces it mechanically from the
# compiler's own typed trees, and regenerating it is one command.
#
#   bash bench/contracts.sh
#
# Output: docs/ECOSYSTEM-CONTRACTS.md
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/bench/_work}"
OUT="${OUT:-$ROOT/docs/ECOSYSTEM-CONTRACTS.md}"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"

[ -x "$UNHANDLED" ] || { echo "FATAL: $UNHANDLED not found. Run 'dune build'." >&2; exit 2; }
[ -d "$WORK" ] || { echo "FATAL: no $WORK. Run bench/sweep.sh first." >&2; exit 2; }

TO=""
if command -v timeout >/dev/null 2>&1; then TO=timeout
elif command -v gtimeout >/dev/null 2>&1; then TO=gtimeout; fi
T_CHECK="${T_CHECK:-300}"
limit () { if [ -n "$TO" ]; then "$TO" "$T_CHECK" "$@" </dev/null; else "$@" </dev/null; fi; }

STAMP="$( (md5 -q "$UNHANDLED" 2>/dev/null \
           || md5sum "$UNHANDLED" 2>/dev/null | cut -d' ' -f1) | cut -c1-12 )"

mkdir -p "$(dirname "$OUT")"
{
  echo "# Effect contracts, derived"
  echo
  echo "What each library asks its callers to handle, read out of the compiler's"
  echo "own typed trees rather than written by hand. OCaml 5's effect handlers are"
  echo "untyped, so nothing else in the ecosystem states this, and no hand-written"
  echo "version would stay true for long."
  echo
  echo "\`...unknown\` in a set means the contract is incomplete at that function"
  echo "because it calls into code with no \`.cmt\` available. It is printed rather"
  echo "than rounded away: a contract that quietly stops short is worth less than"
  echo "one that says where it stops."
  echo
  echo "Regenerate with \`bash bench/contracts.sh\`."
  echo
  echo "Analyser build \`$STAMP\`, generated $(date -u +%Y-%m-%d)."
  echo
} > "$OUT"

emitted=0
for dir in "$WORK"/*/; do
  name="$(basename "$dir")"
  [ -d "$dir/_build" ] || continue
  body="$(limit "$UNHANDLED" contract "$dir/_build" 2>/dev/null)"
  # A library with no effect contract is not interesting here, and printing an
  # empty section for it would bury the ones that are.
  echo "$body" | grep -q "may perform" || { printf "%-28s no contract\n" "$name"; continue; }
  n=$(echo "$body" | grep -c "may perform")
  {
    echo "## $name"
    echo
    echo '```'
    echo "$body"
    echo '```'
    echo
  } >> "$OUT"
  printf "%-28s %s function(s)\n" "$name" "$n"
  emitted=$((emitted+1))
done

echo
echo "$emitted librar(y|ies) with a contract, written to $OUT"
