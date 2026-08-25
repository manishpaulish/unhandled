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
#
# Order matters. The first run of this script was given "2271", meaning issue
# #2271, and git happily resolved it as an abbreviated commit SHA -- so it
# analysed an unrelated commit and reported nothing. Only treat the argument as
# a SHA when it actually looks like one.
if [ ${#REF} -ge 7 ] && echo "$REF" | grep -qE '^[0-9a-f]+$' \
   && git rev-parse --verify -q "$REF^{commit}" >/dev/null; then
  FIX="$REF"
else
  echo "searching commit messages for '$REF'"
  git log --all --oneline --grep="$REF" | head -20
  FIX="$(git log --all --format=%H --grep="$REF" | head -1)"
  if [ -z "$FIX" ]; then
    echo "no commit message matches '$REF'."
    echo "Try the issue number, a phrase from the fix, or a full commit SHA."
    exit 1
  fi
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

# Coverage of the fix.
#
# "Not caught" is two very different results wearing one label. If the file the
# fix touched never compiled, the analyser was never shown the bug and the run
# says nothing about the detector. If it did compile and we stayed silent, that
# is a real miss worth investigating. Without this section the first batch was
# reported as 0 of 6 with no way to tell which kind of zero it was.
echo
echo "coverage of the fix"
printf -- "----------------------------------------------------------------\n"
covered=0; touched=0
for f in $(git show --name-only --format= "$FIX" | grep -E '\.ml$' || true); do
  touched=$((touched+1))
  base="$(basename "$f" .ml)"
  if find "$WORK/$SUB/_build" -iname "*${base}.cmt" 2>/dev/null | grep -q .; then
    printf "  %-56s compiled\n" "$f"; covered=$((covered+1))
  else
    printf "  %-56s NOT COMPILED\n" "$f"
  fi
done
if [ "$touched" -eq 0 ]; then
  echo "  (the fix touched no .ml files: it may be a config or script change)"
else
  echo "$covered of $touched file(s) touched by the fix were analysed"
fi
[ "$covered" -eq 0 ] && [ "$touched" -gt 0 ] && \
  echo "  => a 'not caught' below is a corpus gap, not a detector gap"
printf -- "----------------------------------------------------------------\n"
echo

"$UNHANDLED" check "$WORK/$SUB/_build" | tee "$OUT/$NAME.retro.txt"
echo
echo "Recorded at $OUT/$NAME.retro.txt"
echo "Compare against the effect named in the original crash report."
