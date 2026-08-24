#!/usr/bin/env bash
# Retroactive check: does the analyser catch a crash that really happened?
#
# Mature libraries do not carry unhandled-effect bugs -- their test suites
# pass, so by construction the effects are handled. The bugs exist in history,
# at the commit before someone fixed them. This checks out that commit and asks
# whether we would have caught it.
#
#   bash bench/retro.sh <name> <git-url> <fixing-commit-or-search-term> [subdir]
#
# Example, for the crash recorded in bench/RETROACTIVE.md as R1:
#   bash bench/retro.sh masc https://github.com/jeong-sik/masc.git 2271
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:?usage: retro.sh <name> <url> <commit-or-search> [subdir]}"
URL="${2:?}"
REF="${3:?}"
SUB="${4:-}"
WORK="$ROOT/bench/_retro/$NAME"
OUT="$ROOT/bench/results"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
mkdir -p "$OUT" "$(dirname "$WORK")"

if [ ! -d "$WORK/.git" ]; then
  echo "cloning $URL (full history; this is slower than the sweep on purpose)"
  git clone -q "$URL" "$WORK" || { echo "clone failed"; exit 1; }
fi
cd "$WORK"

# Accept either an explicit commit or a search term matched against messages.
if git rev-parse --verify -q "$REF^{commit}" >/dev/null; then
  FIX="$REF"
else
  echo "searching commit messages for '$REF'"
  git log --all --oneline --grep="$REF" | head -20
  FIX="$(git log --all --format=%H --grep="$REF" | head -1)"
  [ -z "$FIX" ] && { echo "no commit matches '$REF'"; exit 1; }
fi
PARENT="$(git rev-parse "$FIX^")"
echo "fix     $FIX"
echo "parent  $PARENT   <- analysing this"
git checkout -q "$PARENT" || { echo "checkout failed"; exit 1; }

own=$(cd "$WORK/$SUB" && ls *.opam 2>/dev/null | sed 's/\.opam$//' | paste -sd, -)
ignore=""; [ -n "$own" ] && ignore="--ignore-constraints-on=$own"
( cd "$WORK/$SUB" && opam install . --deps-only --yes --assume-depexts $ignore ) >"$OUT/$NAME.retro.log" 2>&1
( cd "$WORK/$SUB" && opam exec -- dune build --root . @check -j "${JOBS:-2}" ) >>"$OUT/$NAME.retro.log" 2>&1

mods=$(find "$WORK/$SUB/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
echo "modules analysed: $mods"
[ "$mods" -eq 0 ] && { echo "nothing built; see $OUT/$NAME.retro.log"; exit 1; }

"$UNHANDLED" check "$WORK/$SUB/_build" | tee "$OUT/$NAME.retro.txt"
echo
echo "Recorded at $OUT/$NAME.retro.txt"
echo "Compare against the effect named in the original crash report."
