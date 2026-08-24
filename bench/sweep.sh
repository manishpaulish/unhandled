#!/usr/bin/env bash
# Ecosystem sweep: run `unhandled` across real projects and emit a results CSV.
#
# Requires opam and a 5.x switch. Everything is recorded, including failures:
# a repo that will not build is corpus attrition, not something to quietly
# drop, because the denominator matters when reporting findings.
#
#   bash bench/sweep.sh                 # all repos in bench/repos.txt
#   REPOS="eio picos" bash bench/sweep.sh
#   JOBS=4 bash bench/sweep.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/bench/_work}"
OUT="${OUT:-$ROOT/bench/results}"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
JOBS="${JOBS:-2}"
mkdir -p "$WORK" "$OUT"

if [ ! -x "$UNHANDLED" ]; then
  echo "FATAL: $UNHANDLED not found. Run 'dune build' first." >&2; exit 2
fi
command -v opam >/dev/null || { echo "FATAL: opam not found." >&2; exit 2; }

CSV="$OUT/sweep.csv"
echo "repo,status,modules,findings,escapes,unknown,scheduler_mismatch,boundary,seconds" > "$CSV"

run_one () {
  local name="$1" url="$2" sub="${3:-}"
  local dir="$WORK/$name"
  local t0; t0=$(date +%s)
  local status=ok modules=0 findings=0 esc=0 unk=0 sched=0 bound=0

  if [ ! -d "$dir/.git" ]; then
    git clone -q --depth 1 "$url" "$dir" 2>/dev/null || { status=clone_failed; }
  fi
  if [ "$status" = ok ]; then
    ( cd "$dir/$sub" && opam install . --deps-only --yes >/dev/null 2>&1 ) || true
    # @check builds .cmt files without a full build, which is all we need.
    if ! ( cd "$dir/$sub" && timeout 900 opam exec -- dune build @check -j "$JOBS" >/dev/null 2>&1 ); then
      status=build_failed
    fi
  fi
  if [ "$status" = ok ]; then
    modules=$(find "$dir/$sub/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$modules" -eq 0 ]; then
      status=no_cmt
    else
      local json="$OUT/$name.json"
      "$UNHANDLED" check "$dir/$sub/_build" --json > "$json" 2>/dev/null
      read -r findings esc unk sched bound < <(python3 - "$json" <<'PY'
import json,sys
try:
    d=json.load(open(sys.argv[1]))["summary"]
    print(d["total"],d["escapes"],d["unknown"],d["scheduler_mismatch"],d["boundary"])
except Exception:
    print(0,0,0,0,0)
PY
)
    fi
  fi
  local t1; t1=$(date +%s)
  echo "$name,$status,$modules,$findings,$esc,$unk,$sched,$bound,$((t1-t0))" >> "$CSV"
  printf "%-18s %-14s modules=%-5s findings=%-4s (esc=%s sched=%s bound=%s)\n" \
    "$name" "$status" "$modules" "$findings" "$esc" "$sched" "$bound"
}

while read -r name url sub; do
  case "$name" in ''|\#*) continue;; esac
  if [ -n "${REPOS:-}" ] && ! echo " $REPOS " | grep -q " $name "; then continue; fi
  run_one "$name" "$url" "${sub:-}"
done < "$ROOT/bench/repos.txt"

echo
echo "results: $CSV"
python3 - "$CSV" <<'PY'
import csv,sys
rows=list(csv.DictReader(open(sys.argv[1])))
ok=[r for r in rows if r["status"]=="ok"]
def s(k): return sum(int(r[k]) for r in ok)
print(f"analysed {len(ok)}/{len(rows)} repos, {s('modules')} modules")
print(f"  escapes            {s('escapes')}")
print(f"  scheduler mismatch {s('scheduler_mismatch')}")
print(f"  boundary crossings {s('boundary')}")
print(f"  unknown-effect warnings {s('unknown')}")
for r in rows:
    if r["status"]!="ok": print(f"  attrition: {r['repo']} -> {r['status']}")
PY
