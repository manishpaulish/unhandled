#!/usr/bin/env bash
# Differential fuzzing: analyser prediction vs actual execution.
#
#   predicted escape + crashed   -> agree
#   predicted clean   + ran ok   -> agree
#   predicted clean   + crashed  -> FALSE NEGATIVE (a missed bug: serious)
#   predicted escape  + ran ok   -> FALSE POSITIVE
#
# Disagreements are saved to test/fuzz/failures/ as regression candidates.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/test/fuzz"
OCAMLC="${OCAMLC:-ocamlc}"
RUN="${OCAMLRUN:-}"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
START="${START:-1}"; COUNT="${COUNT:-100}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$F/failures"

# Refuse to run against a missing or broken analyser. Without this check a
# failed invocation reads as "predicted clean" for every seed, and the run
# reports a wall of false negatives that are really just a missing binary.
probe="$WORK/probe"; mkdir -p "$probe"
printf 'type _ Effect.t += P : unit Effect.t\nlet () = Effect.perform P\n' > "$probe/probe.ml"
( cd "$probe" && $OCAMLC -bin-annot -c probe.ml >/dev/null 2>&1 ) \
  || { echo "FATAL: cannot compile with OCAMLC=$OCAMLC"; exit 2; }
# Capture first, then grep: the tool exits 1 when it finds something, and
# under `set -o pipefail` that would fail the pipeline even on a match.
probe_out="$($RUN "$UNHANDLED" check "$probe" 2>&1 || true)"
if ! echo "$probe_out" | grep -q "escapes unhandled"; then
  echo "FATAL: analyser at $UNHANDLED did not flag a known-bad probe program."
  echo "       Build it first; otherwise every seed reads as 'predicted clean'."
  exit 2
fi

agree=0; fp=0; fn=0; skipped=0
for ((s=START; s<START+COUNT; s++)); do
  d="$WORK/s$s"; mkdir -p "$d"
  $RUN "$F/gen" "$s" > "$d/prog.ml" 2>/dev/null || { skipped=$((skipped+1)); continue; }
  ( cd "$d" && $OCAMLC -bin-annot -c prog.ml >/dev/null 2>&1 ) || { skipped=$((skipped+1)); continue; }

  out="$($RUN "$UNHANDLED" check "$d" 2>/dev/null)"
  if echo "$out" | grep -qE "error\[E00[13]\]"; then predicted=escape; else predicted=clean; fi

  ( cd "$d" && $OCAMLC -o prog.exe prog.ml >/dev/null 2>&1 ) || { skipped=$((skipped+1)); continue; }
  if ( cd "$d" && timeout 10 $RUN ./prog.exe >/dev/null 2>&1 ); then actual=clean; else actual=crash; fi

  if   [ "$predicted" = escape ] && [ "$actual" = crash ]; then agree=$((agree+1))
  elif [ "$predicted" = clean  ] && [ "$actual" = clean ]; then agree=$((agree+1))
  elif [ "$predicted" = clean  ] && [ "$actual" = crash ]; then
    fn=$((fn+1)); cp "$d/prog.ml" "$F/failures/fn_seed$s.ml"
  else
    fp=$((fp+1)); cp "$d/prog.ml" "$F/failures/fp_seed$s.ml"
  fi
done

total=$((agree+fp+fn))
echo "seeds $START..$((START+COUNT-1))   analysed $total   skipped $skipped"
echo "  agree           $agree"
echo "  false positives $fp"
echo "  false negatives $fn"
if [ $total -gt 0 ]; then
  echo "  agreement       $(( agree * 100 / total ))%"
fi
[ $((fp+fn)) -eq 0 ]
