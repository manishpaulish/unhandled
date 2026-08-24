#!/usr/bin/env bash
# Run the retroactive check over many fixing commits and emit a summary table.
#
# The claim we want is "would have caught M of N documented crashes". One
# anecdote is not a result; this produces the denominator too, including the
# commits we fail to build, because dropping those would inflate the rate.
#
#   bash bench/retro_batch.sh <name> <git-url> <commits-file> [subdir]
#
# commits-file: one commit SHA per line, '#' comments allowed. Each is a commit
# that FIXED an unhandled-effect problem; we analyse its parent.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:?usage: retro_batch.sh <name> <url> <commits-file> [subdir]}"
URL="${2:?}"
LIST="${3:?}"
SUB="${4:-}"
WORK="$ROOT/bench/_retro/$NAME"
OUT="$ROOT/bench/results"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
mkdir -p "$OUT"
CSV="$OUT/$NAME.retro.csv"
echo "commit,parent,subject,status,modules,escapes,scheduler,boundary,unknown" > "$CSV"

[ -d "$WORK/.git" ] || git clone -q "$URL" "$WORK" || { echo "clone failed"; exit 1; }

caught=0; missed=0; failed=0
while read -r sha rest; do
  case "$sha" in ''|\#*) continue;; esac
  cd "$WORK"
  git checkout -q --detach "$sha" 2>/dev/null || { echo "$sha: unknown commit"; continue; }
  subject="$(git log -1 --format=%s | tr ',' ';' | cut -c1-60)"
  parent="$(git rev-parse --short "$sha^" 2>/dev/null)"
  git checkout -q --detach "$sha^" 2>/dev/null || { echo "$sha: no parent"; continue; }
  git clean -qfd 2>/dev/null

  log="$OUT/$NAME.$parent.log"
  own=$(cd "$WORK/$SUB" && ls *.opam 2>/dev/null | sed 's/\.opam$//' | paste -sd, -)
  ig=""; [ -n "$own" ] && ig="--ignore-constraints-on=$own"
  ( cd "$WORK/$SUB" && opam install . --deps-only --yes --assume-depexts $ig ) >"$log" 2>&1
  ( cd "$WORK/$SUB" && timeout 900 opam exec -- dune build --root . @check -j "${JOBS:-2}" ) >>"$log" 2>&1

  mods=$(find "$WORK/$SUB/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$mods" -eq 0 ]; then
    echo "$sha,$parent,$subject,build_failed,0,0,0,0,0" >> "$CSV"
    printf "%-12s %-58s %s\n" "$parent" "$subject" "BUILD FAILED"
    failed=$((failed+1)); continue
  fi

  json="$OUT/$NAME.$parent.json"
  "$UNHANDLED" check "$WORK/$SUB/_build" --json > "$json" 2>>"$log"
  read -r esc sch bnd unk < <(python3 - "$json" <<'PY'
import json,sys
try:
    d=json.load(open(sys.argv[1]))["summary"]
    print(d["escapes"],d["scheduler_mismatch"],d["boundary"],d["unknown"])
except Exception:
    print(0,0,0,0)
PY
)
  real=$((esc+sch+bnd))
  if [ "$real" -gt 0 ]; then verdict="CAUGHT ($real)"; caught=$((caught+1))
  else verdict="not caught"; missed=$((missed+1)); fi
  echo "$sha,$parent,$subject,ok,$mods,$esc,$sch,$bnd,$unk" >> "$CSV"
  printf "%-12s %-58s %s\n" "$parent" "$subject" "$verdict"
done < "$LIST"

echo
echo "caught $caught, not caught $missed, build failed $failed"
echo "table: $CSV"
echo
echo "A 'not caught' row is a real result and belongs in the report: it is"
echo "either a limitation we can name, or a crash outside the classes we detect."
