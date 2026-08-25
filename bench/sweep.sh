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
#   REPOS_FILE=bench/repos.generated.txt bash bench/sweep.sh   # see discover.sh
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
# Append, and keep whatever is already there. A sweep over 85 repositories runs
# for hours; losing all of it because one entry hung is not acceptable, so a
# repo already present in the CSV is skipped on the next run. FORCE=1 redoes
# everything, and deleting a single line redoes that one repo.
if [ ! -s "$CSV" ] || [ "${FORCE:-0}" = 1 ]; then
  echo "repo,status,modules,findings,escapes,unknown,scheduler_mismatch,boundary,seconds" > "$CSV"
fi

# Every external command gets a time limit and a closed stdin.
#
# Without these the sweep stalls silently and indefinitely: opam will sit at a
# prompt forever if it decides to ask something --yes does not cover, a clone
# against an unreachable host never returns, and neither writes anything to
# say so. Observed in practice as four hours of no output.
TO=""
if command -v timeout >/dev/null 2>&1; then TO=timeout
elif command -v gtimeout >/dev/null 2>&1; then TO=gtimeout
else
  echo "warning: no timeout(1) on PATH; a hung repository will stall the sweep." >&2
  echo "         brew install coreutils, or expect to babysit it." >&2
fi
T_CLONE="${T_CLONE:-300}"; T_DEPS="${T_DEPS:-900}"; T_BUILD="${T_BUILD:-900}"
limit () { # limit <seconds> <command...>
  local s="$1"; shift
  if [ -n "$TO" ]; then "$TO" "$s" "$@" </dev/null; else "$@" </dev/null; fi
}
export OPAMYES=1 OPAMCOLOR=never OPAMNOSELFUPGRADE=1 GIT_TERMINAL_PROMPT=0

run_one () {
  local name="$1" url="$2" sub="${3:-}"
  local dir="$WORK/$name"
  local log="$OUT/$name.log"
  local t0; t0=$(date +%s)
  local status=ok modules=0 findings=0 esc=0 unk=0 sched=0 bound=0
  : > "$log"

  # Say what we are about to do before doing it, so a stall names its own
  # culprit instead of leaving the last *completed* repo as the only clue.
  printf "%-24s ... " "$name"

  if [ ! -d "$dir/.git" ]; then
    limit "$T_CLONE" git clone -q --depth 1 "$url" "$dir" >>"$log" 2>&1 || status=clone_failed
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
    if ! ( cd "$dir/$sub" && limit "$T_DEPS" opam install . $opam_flags --with-test >>"$log" 2>&1 ); then
      echo "(deps-only with tests failed; retrying without --with-test)" >> "$log"
      ( cd "$dir/$sub" && limit "$T_DEPS" opam install . $opam_flags >>"$log" 2>&1 ) || status=deps_failed
    fi
  fi

  if [ "$status" = ok ] || [ "$status" = deps_failed ]; then
    echo "=== dune build @check ===" >> "$log"
    # --root . is essential. Without it dune searches upward, finds THIS
    # project's dune-project, and tries to build the clone as part of us:
    #   Error: Don't know about directory bench/_work/eio
    if ( cd "$dir/$sub" && limit "$T_BUILD" opam exec -- dune build --root . @check -j "$JOBS" >>"$log" 2>&1 ); then
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
  printf "\r%-24s %-14s modules=%-5s findings=%-4s (esc=%s sched=%s bound=%s) %ss\n" \
    "$name" "$status" "$modules" "$findings" "$esc" "$sched" "$bound" "$((t1-t0))"
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
  # Skip only what actually produced data. A failure is not a result worth
  # keeping: the first long run lost its network partway through and recorded
  # 67 repositories as clone_failed, and skipping those on the retry would have
  # frozen a transient outage into the corpus permanently. ok and partial are
  # terminal; everything else is retried, which the time limits make cheap.
  if [ "${FORCE:-0}" != 1 ] \
     && grep -qE "^$name,(ok|partial)," "$CSV" 2>/dev/null; then
    printf "%-24s %s\n" "$name" "(done, skipping)"
    continue
  fi
  # Drop any earlier failed row for this repo so the CSV keeps one line each.
  if grep -q "^$name," "$CSV" 2>/dev/null; then
    grep -v "^$name," "$CSV" > "$CSV.tmp" && mv "$CSV.tmp" "$CSV"
  fi
  run_one "$name" "$url" "${sub:-}"
done < "${REPOS_FILE:-$ROOT/bench/repos.txt}"

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
