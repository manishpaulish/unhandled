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
  local log="$OUT/$name.log"
  local t0; t0=$(date +%s)
  local status=ok modules=0 findings=0 esc=0 unk=0 sched=0 bound=0
  : > "$log"

  if [ ! -d "$dir/.git" ]; then
    git clone -q --depth 1 "$url" "$dir" >>"$log" 2>&1 || status=clone_failed
  fi

  if [ "$status" = ok ]; then
    # Dependency resolution and build are recorded separately: "could not
    # install deps" and "code does not compile" are different problems and
    # lumping them together makes the attrition column useless.
    echo "=== opam install --deps-only ===" >> "$log"
    # Monorepos (eio ships eio, eio_linux, eio_main, eio_posix) declare version
    # constraints on each other. Resolving them all together fails against the
    # working tree: eio_linux wants "eio < 1.5" while the checkout IS 1.5. Tell
    # opam to ignore constraints on the repo's own packages.
    local own
    own=$( cd "$dir/$sub" && ls *.opam 2>/dev/null | sed 's/\.opam$//' | paste -sd, - )
    local ignore=""
    [ -n "$own" ] && ignore="--ignore-constraints-on=$own"
    # --assume-depexts skips the system-package check rather than invoking brew
    # or apt. A package that genuinely needs a system library will fail at
    # build time and be recorded as attrition, which is preferable to this
    # script installing things on someone's machine.
    local opam_flags="--deps-only --yes --assume-depexts $ignore"
    if ! ( cd "$dir/$sub" && opam install . $opam_flags --with-test >>"$log" 2>&1 ); then
      echo "(deps-only with tests failed; retrying without --with-test)" >> "$log"
      ( cd "$dir/$sub" && opam install . $opam_flags >>"$log" 2>&1 ) || status=deps_failed
    fi
  fi

  if [ "$status" = ok ] || [ "$status" = deps_failed ]; then
    echo "=== dune build @check ===" >> "$log"
    # --root . is essential. Without it dune searches upward, finds THIS
    # project's dune-project, and tries to build the clone as part of us:
    #   Error: Don't know about directory bench/_work/eio
    if ( cd "$dir/$sub" && timeout 900 opam exec -- dune build --root . @check -j "$JOBS" >>"$log" 2>&1 ); then
      status=ok
    else
      # A partial build is still worth analysing: many repos fail only in
      # their test or example stanzas, and the library .cmt files we care
      # about are already on disk. Report it as partial rather than throwing
      # the data away.
      if [ "$(find "$dir/$sub/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
        status=partial
      else
        [ "$status" = deps_failed ] || status=build_failed
      fi
    fi
  fi

  if [ "$status" = ok ] || [ "$status" = partial ]; then
    modules=$(find "$dir/$sub/_build" -name '*.cmt' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$modules" -eq 0 ]; then
      status=no_cmt
    else
      local json="$OUT/$name.json"
      "$UNHANDLED" check "$dir/$sub/_build" --json > "$json" 2>>"$log"
      read -r findings esc unk sched bound < <(python3 - "$json" <<'PY2'
import json,sys
try:
    d=json.load(open(sys.argv[1]))["summary"]
    print(d["total"],d["escapes"],d["unknown"],d["scheduler_mismatch"],d["boundary"])
except Exception:
    print(0,0,0,0,0)
PY2
)
    fi
  fi

  local t1; t1=$(date +%s)
  echo "$name,$status,$modules,$findings,$esc,$unk,$sched,$bound,$((t1-t0))" >> "$CSV"
  printf "%-18s %-14s modules=%-5s findings=%-4s (esc=%s sched=%s bound=%s)\n" \
    "$name" "$status" "$modules" "$findings" "$esc" "$sched" "$bound"
  case "$status" in
    ok|partial) ;;
    *)
      echo "    why: (last lines of $log)"
      tail -n 12 "$log" | sed 's/^/    | /'
      ;;
  esac
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
ok=[r for r in rows if r["status"] in ("ok","partial")]
def s(k): return sum(int(r[k]) for r in ok)
print(f"analysed {len(ok)}/{len(rows)} repos, {s('modules')} modules")
print(f"  escapes            {s('escapes')}")
print(f"  scheduler mismatch {s('scheduler_mismatch')}")
print(f"  boundary crossings {s('boundary')}")
print(f"  unknown-effect warnings {s('unknown')}")
for r in rows:
    if r["status"] not in ("ok","partial"):
        print(f"  attrition: {r['repo']} -> {r['status']} (see bench/results/{r['repo']}.log)")
    elif r["status"]=="partial":
        print(f"  partial:   {r['repo']} built enough to analyse {r['modules']} modules")
PY
