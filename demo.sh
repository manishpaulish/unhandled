#!/usr/bin/env bash
# The demo, scripted so it is reproducible rather than remembered.
#
# Every claim here is executed, not asserted: programs are compiled and run,
# and their real output is shown next to what the analyser predicted.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
RUN="${OCAMLRUN:-}"
OCAMLC="${OCAMLC:-ocamlc}"
[ -x "$UNHANDLED" ] || [ -n "$RUN" ] || { echo "build first: dune build"; exit 2; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

hdr () { printf '\n\033[1m== %s ==\033[0m\n\n' "$1"; }
run () { printf '\033[2m$ %s\033[0m\n' "$*"; "$@"; }

hdr "1. Ten lines the compiler waves through"
mkdir -p "$W/a" && cd "$W/a"
cat > metrics.ml <<'EOF'
type _ Effect.t += Emit : string -> unit Effect.t
let log msg    = Effect.perform (Emit msg)
let process xs = List.iter log xs
let ()         = process ["batch-1"; "batch-2"]
EOF
cat metrics.ml
echo
echo "It compiles with no warnings:"
run $OCAMLC -bin-annot -c metrics.ml
echo "...and then:"
$OCAMLC -o metrics.exe metrics.ml >/dev/null 2>&1
$RUN ./metrics.exe 2>&1 | head -2 || true

hdr "2. What unhandled says about it"
run $RUN "$UNHANDLED" check "$W/a" || true

hdr "3. Every warning ships with a proof"
mkdir -p "$W/b" && cd "$W/b"
cat > svc.ml <<'EOF'
type _ Effect.t += Ping : string -> unit Effect.t
let service msg = Effect.perform (Ping msg)
let run_all xs  = List.iter service xs
EOF
cat > app.ml <<'EOF'
let () = Svc.run_all ["a"; "b"]
EOF
for _ in 1 2; do for f in *.ml; do $OCAMLC -bin-annot -c "$f" >/dev/null 2>&1; done; done
echo "The witness is generated, compiled and RUN:"
UNHANDLED_OCAMLC="$OCAMLC" UNHANDLED_RUNNER="$RUN" run $RUN "$UNHANDLED" witness "$W/b" || true
echo
echo "Generated source:"
cat "$W/b/_unhandled/w01/unhandled_witness.ml" 2>/dev/null || \
  cat _unhandled/w01/unhandled_witness.ml 2>/dev/null || true

hdr "4. A handler that cannot help (finaliser)"
mkdir -p "$W/c" && cd "$W/c"
cat > fin.ml <<'EOF'
type _ Effect.t += Log : unit Effect.t
let () = Gc.finalise (fun _ -> Effect.perform Log) (ref 0)
let () =
  match Gc.full_major () with          (* a handler for the very effect *)
  | () -> print_endline "no crash"
  | effect Log, k -> Effect.Deep.continue k ()
EOF
for _ in 1 2; do $OCAMLC -bin-annot -c fin.ml >/dev/null 2>&1; done
run $RUN "$UNHANDLED" check "$W/c" || true
echo "The program installs a handler for Log, and still:"
$OCAMLC -o fin.exe fin.ml >/dev/null 2>&1
$RUN ./fin.exe 2>&1 | head -2 || true

hdr "5. Calling Eio with no runtime"
mkdir -p "$W/d" && cd "$W/d"
cat > eio.ml <<'EOF'
module Mutex = struct let use_rw _ f = f () end
EOF
cat > bad.ml <<'EOF'
let helper () = Eio.Mutex.use_rw () (fun () -> ())
let () = helper ()
EOF
for _ in 1 2; do for f in *.ml; do $OCAMLC -bin-annot -c "$f" >/dev/null 2>&1; done; done
run $RUN "$UNHANDLED" check "$W/d" || true

hdr "6. Measured, not claimed"
cd "$ROOT"
echo "differential fuzzing, runtime as oracle:"
OCAMLC="$OCAMLC" OCAMLRUN="$RUN" UNHANDLED="$UNHANDLED" \
  START=1 COUNT=100 bash test/fuzz/run_fuzz.sh 2>&1 | tail -5
echo
echo "incremental checks:"
OCAMLC="$OCAMLC" OCAMLRUN="$RUN" UNHANDLED="$UNHANDLED" N=200 bash bench/perf.sh 2>&1 | tail -5
