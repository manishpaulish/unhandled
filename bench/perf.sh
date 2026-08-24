#!/usr/bin/env bash
# Cold versus warm timing, and a cache-consistency check.
#
# The consistency check matters more than the timing: a cache that changes the
# answer is worse than no cache, so the two outputs are compared byte for byte
# before any number is reported.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
RUN="${OCAMLRUN:-}"
OCAMLC="${OCAMLC:-ocamlc}"
N="${N:-200}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
cat > base.ml <<'EOF'
type _ Effect.t += Log : string -> unit Effect.t
let emit s = Effect.perform (Log s)
EOF
for i in $(seq 1 $((N-1))); do
  cat > "m$i.ml" <<EOF
let helper$i x = Base.emit x
let run$i () =
  match helper$i "x" with
  | () -> ()
  | effect (Base.Log _), k -> Effect.Deep.continue k ()
let chain$i () = List.iter helper$i ["a"; "b"]
EOF
done
for _ in 1 2; do
  for f in base.ml $(ls m*.ml | sort -V); do $OCAMLC -bin-annot -c "$f" >/dev/null 2>&1; done
done
echo "modules: $(ls *.cmt | wc -l | tr -d ' ')"

rm -rf .unhandled-cache
$RUN "$UNHANDLED" check . --no-cache > nocache.txt 2>&1
rm -rf .unhandled-cache
$RUN "$UNHANDLED" check . > cold.txt 2>&1
$RUN "$UNHANDLED" check . > warm.txt 2>&1

if ! diff -q nocache.txt warm.txt >/dev/null; then
  echo "FAIL: cached output differs from uncached output"
  diff nocache.txt warm.txt | head -20
  exit 1
fi
echo "consistency: cached and uncached output identical"

t () { local s; s=$( { /usr/bin/time -p "$@" >/dev/null; } 2>&1 | awk '/^real/{print $2}' ); echo "$s"; }
rm -rf .unhandled-cache
echo "cold: $(t $RUN "$UNHANDLED" check .)s"
echo "warm: $(t $RUN "$UNHANDLED" check .)s"
echo "warm: $(t $RUN "$UNHANDLED" check .)s"
