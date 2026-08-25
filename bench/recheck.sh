#!/usr/bin/env bash
# Re-analyse every repository already cloned and built under bench/_work,
# without cloning, resolving dependencies or building anything again.
#
# Why this exists. A sweep takes hours, almost all of it in opam and dune. The
# analysis itself takes seconds. So during a long sweep it is normal to fix the
# analyser and rebuild it, and the rows already written then came from a
# different program than the rows written afterwards. That happened here: a
# sweep recorded eio_linux with 20 escapes while a fix that removed all of them
# was being compiled in another terminal.
#
# A findings table whose rows come from different builds is not a measurement.
# This regenerates all of them against one binary, in minutes.
#
#   bash bench/recheck.sh
#   UNHANDLED=/path/to/unhandled.exe bash bench/recheck.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/bench/_work}"
OUT="${OUT:-$ROOT/bench/results}"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
mkdir -p "$OUT"

[ -x "$UNHANDLED" ] || { echo "FATAL: $UNHANDLED not found. Run 'dune build'." >&2; exit 2; }
[ -d "$WORK" ] || { echo "FATAL: no $WORK. Run bench/sweep.sh first." >&2; exit 2; }

# Stamp the table with the analyser that produced it, so a reader can tell
# whether two tables are comparable.
STAMP="$( (md5 -q "$UNHANDLED" 2>/dev/null || md5sum "$UNHANDLED" 2>/dev/null | cut -d' ' -f1) )"
CSV="$OUT/recheck.csv"
echo "# analyser=$STAMP generated=$(date -u +%Y-%m-%dT%H:%MZ)" > "$CSV"
echo "repo,modules,findings,escapes,unknown,scheduler_mismatch,boundary,seconds" >> "$CSV"

echo "analyser $STAMP"
printf -- "----------------------------------------------------------------\n"

total_repos=0; total_mods=0; t_esc=0; t_sched=0; t_bound=0; t_unk=0
for dir in "$WORK"/*/; do
  name="$(basename "$dir")"
  [ -d "$dir/_build" ] || continue
  mods=$(find "$dir/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
  [ "$mods" -eq 0 ] && continue

  t0=$(date +%s)
  json="$OUT/$name.recheck.json"
  # A repository that kills the checker must not kill the table.
  if ! "$UNHANDLED" check "$dir/_build" --json > "$json" 2>/dev/null; then
    if [ ! -s "$json" ]; then
      printf "%-28s %s\n" "$name" "checker failed or was killed, recorded as such"
      echo "$name,$mods,,,,,," >> "$CSV"
      continue
    fi
  fi
  t1=$(date +%s)

  read -r f e u s b < <(python3 - "$json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))["summary"]
    print(d["total"], d["escapes"], d["unknown"], d["scheduler_mismatch"], d["boundary"])
except Exception:
    print(0, 0, 0, 0, 0)
PY
)
  echo "$name,$mods,$f,$e,$u,$s,$b,$((t1-t0))" >> "$CSV"
  printf "%-28s modules=%-5s findings=%-4s (esc=%s sched=%s bound=%s)\n" \
    "$name" "$mods" "$f" "$e" "$s" "$b"
  total_repos=$((total_repos+1)); total_mods=$((total_mods+mods))
  t_esc=$((t_esc+e)); t_sched=$((t_sched+s)); t_bound=$((t_bound+b)); t_unk=$((t_unk+u))
done

printf -- "----------------------------------------------------------------\n"
echo "$total_repos repositories, $total_mods modules, one analyser build"
echo "  escapes                 $t_esc"
echo "  scheduler mismatch      $t_sched"
echo "  boundary crossings      $t_bound"
echo "  unknown-effect warnings $t_unk"
echo
echo "table: $CSV"
echo "These numbers are comparable to each other. The ones in sweep.csv are not,"
echo "if the analyser was rebuilt while that sweep was running."
