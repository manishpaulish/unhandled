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
echo "commit,parent,subject,status,modules,touched,covered,escapes,scheduler,boundary,unknown" > "$CSV"

[ -d "$WORK/.git" ] || git clone -q "$URL" "$WORK" || { echo "clone failed"; exit 1; }

# caught     = a real finding at the parent commit
# miss       = the fixed file compiled and we said nothing (a genuine miss)
# outofscope = the fixed file never compiled, so the bug was never shown to us
# failed     = nothing built at all
caught=0; miss=0; outofscope=0; failed=0
while read -r sha rest; do
  case "$sha" in ''|\#*) continue;; esac
  cd "$WORK"
  git checkout -q --detach "$sha" 2>/dev/null || { echo "$sha: unknown commit"; continue; }
  subject="$(git log -1 --format=%s | tr ',' ';' | cut -c1-60)"
  parent="$(git rev-parse --short "$sha^" 2>/dev/null)"
  # The .ml files this fix touched. If none of them compile at the parent
  # commit, the analyser is never shown the bug, and "not caught" says nothing
  # about the detector. Reporting one number for both outcomes is what made
  # the first batch uninterpretable.
  fixfiles="$(git show --name-only --format= "$sha" | grep -E '\.ml$' || true)"
  git checkout -q --detach "$sha^" 2>/dev/null || { echo "$sha: no parent"; continue; }
  git clean -qfd 2>/dev/null

  log="$OUT/$NAME.$parent.log"
  own=$(cd "$WORK/$SUB" && ls *.opam 2>/dev/null | sed 's/\.opam$//' | paste -sd, -)
  ig=""; [ -n "$own" ] && ig="--ignore-constraints-on=$own"
  ( cd "$WORK/$SUB" && opam install . --deps-only --yes --assume-depexts $ig ) >"$log" 2>&1
  ( cd "$WORK/$SUB" && timeout 900 opam exec -- dune build --root . @check -j "${JOBS:-2}" ) >>"$log" 2>&1

  mods=$(find "$WORK/$SUB/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$mods" -eq 0 ]; then
    echo "$sha,$parent,$subject,build_failed,0,0,0,0,0,0,0" >> "$CSV"
    printf "%-12s %-58s %s\n" "$parent" "$subject" "BUILD FAILED"
    failed=$((failed+1)); continue
  fi

  touched=0; covered=0
  for f in $fixfiles; do
    touched=$((touched+1))
    base="$(basename "$f" .ml)"
    if find "$WORK/$SUB/_build" -iname "*${base}.cmt" 2>/dev/null | grep -q .; then
      covered=$((covered+1))
    fi
  done

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
  if [ "$real" -gt 0 ]; then
    verdict="CAUGHT ($real)"; caught=$((caught+1))
  elif [ "$touched" -gt 0 ] && [ "$covered" -eq 0 ]; then
    verdict="out of scope (0/$touched fixed files compiled)"; outofscope=$((outofscope+1))
  else
    verdict="MISS ($covered/$touched fixed files compiled)"; miss=$((miss+1))
  fi
  echo "$sha,$parent,$subject,ok,$mods,$touched,$covered,$esc,$sch,$bnd,$unk" >> "$CSV"
  printf "%-12s %-58s %s\n" "$parent" "$subject" "$verdict"
done < "$LIST"

scoped=$((caught+miss))
echo
echo "caught $caught, missed $miss, out of scope $outofscope, build failed $failed"
if [ "$scoped" -gt 0 ]; then
  echo "catch rate over commits actually presented to the analyser: $caught/$scoped"
else
  echo "catch rate: undefined -- no fixed file was ever compiled, so the"
  echo "analyser was not shown a single one of these bugs."
fi
echo "table: $CSV"
echo
echo "Read the three outcomes apart. A MISS is a real result about the"
echo "detector and belongs in the report. 'Out of scope' is a result about"
echo "the corpus: the file the fix touched never compiled here, so nothing"
echo "was asked of the analyser. Reporting those two as one number is how a"
echo "0/6 gets mistaken for a statement about the tool."
