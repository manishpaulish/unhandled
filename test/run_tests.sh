#!/usr/bin/env bash
# Three-way differential test.
#
# Every corpus program declares what it should do:
#     (* EXPECT: clean *)          runs to completion
#     (* EXPECT: crash <Effect> *) dies with Effect.Unhandled <Effect>
#
# We check the declared expectation against BOTH the analyser's prediction and
# the program's actual runtime behaviour. A disagreement between the analyser
# and the runtime is a real bug in the analyser, not a test-harness detail.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORPUS="$ROOT/test/corpus"
OCAMLC="${OCAMLC:-ocamlc}"
RUN="${OCAMLRUN:-}"
UNHANDLED="${UNHANDLED:-$ROOT/_build/default/bin/unhandled.exe}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
printf "%-22s %-14s %-14s %-14s %s\n" PROGRAM EXPECTED ANALYSER RUNTIME RESULT
printf -- "------------------------------------------------------------------------------\n"

for src in "$CORPUS"/*.ml; do
  name="$(basename "$src" .ml)"
  expect_line="$(head -20 "$src" | grep -o 'EXPECT:[^*]*' | head -1 | sed 's/EXPECT: *//;s/ *$//')"
  [ -z "$expect_line" ] && continue

  # analyser prediction, from an isolated build of just this file
  d="$WORK/$name"; mkdir -p "$d"; cp "$src" "$d/"
  ( cd "$d" && $OCAMLC -bin-annot -c "$name.ml" >/dev/null 2>&1 )
  out="$($RUN "$UNHANDLED" check "$d" 2>/dev/null)"
  if echo "$out" | grep -q "escapes unhandled"; then
    analyser="crash $(echo "$out" | sed -n 's/.*effect [A-Za-z_0-9]*\.\([A-Za-z_0-9]*\) escapes.*/\1/p' | head -1)"
  elif echo "$out" | grep -q "unknown identity"; then
    analyser="unknown"
  else
    analyser="clean"
  fi

  # actual runtime behaviour
  ( cd "$d" && $OCAMLC -o "$name.exe" "$name.ml" >/dev/null 2>&1 )
  rt_out="$( cd "$d" && $RUN "./$name.exe" 2>&1 )"; rc=$?
  if [ $rc -eq 0 ]; then runtime="clean"
  else
    eff="$(echo "$rt_out" | sed -n 's/.*Effect.Unhandled(\?[A-Za-z_0-9]*\.\([A-Za-z_0-9]*\).*/\1/p' | head -1)"
    runtime="crash ${eff:-?}"
  fi

  # The runtime does not always print the effect payload (it depends on
  # whether an enclosing handler declined the effect), so identity is compared
  # only when observable. Crash-vs-clean is always compared.
  exp_kind="${expect_line%% *}"; rt_kind="${runtime%% *}"
  ok=1
  [ "$analyser" = "$expect_line" ] || ok=0
  [ "$rt_kind" = "$exp_kind" ] || ok=0
  if [ "$runtime" != "crash ?" ] && [ "$rt_kind" = crash ] && [ "$runtime" != "$expect_line" ]; then ok=0; fi
  if [ $ok -eq 1 ]; then
    result="PASS"; pass=$((pass+1))
  else
    result="FAIL"; fail=$((fail+1))
  fi
  printf "%-22s %-14s %-14s %-14s %s\n" "$name" "$expect_line" "$analyser" "$runtime" "$result"
done

printf -- "------------------------------------------------------------------------------\n"
echo "$pass passed, $fail failed"

# ---------------------------------------------------------------- scenarios
# Multi-file behaviours the single-file corpus cannot express.
echo
echo "scenarios"
printf -- "------------------------------------------------------------------------------\n"
sfail=0
scenario () { # name dir cmd expected-substring
  local name="$1" dir="$2" cmd="$3" want="$4"
  # Compile in dependency order. Repeated passes are simpler and more robust
  # here than reimplementing ocamldep: a module compiles once its deps exist.
  ( cd "$ROOT/$dir" && for _ in 1 2 3; do
      for f in *.ml; do $OCAMLC -bin-annot -c "$f" >/dev/null 2>&1; done
    done )
  local got
  got="$(UNHANDLED_OCAMLC="$OCAMLC" UNHANDLED_RUNNER="$RUN" $RUN "$UNHANDLED" "$cmd" "$ROOT/$dir" 2>&1)"
  if echo "$got" | grep -q -- "$want"; then
    printf "%-40s PASS\n" "$name"
  else
    printf "%-40s FAIL (wanted: %s)\n" "$name" "$want"; sfail=$((sfail+1))
  fi
  ( cd "$ROOT/$dir" && rm -f *.cm* )
}
scenario "cross-module escape"      test/xmodule    check    "Svc.Ping escapes unhandled"
scenario "library contract"         test/xmodule    contract "may perform {Svc.Ping}"
scenario "witness confirms finding" test/xmodule    witness  "1/1 findings confirmed"
scenario "scheduler mismatch (B2)"  test/schedulers check    "E003"
scenario "re-exported effect alias"  test/alias     check    "0 error(s)"
scenario "finaliser boundary (B3)"   test/boundary  check    "from a finaliser"
scenario "signal handler (B3)"       test/boundary  check    "from a signal handler"
scenario "Effect.Unhandled guard"    test/guard     check    "1 error(s)"
scenario "effect inside a test case"  test/alcotest_like check "Suite.Needs_runtime escapes"
scenario "call via module alias"      test/modalias  check    "Worker.Job escapes"
scenario "handler-scope transfer"     test/transfer  check    "a new domain"
printf -- "------------------------------------------------------------------------------\n"
[ $sfail -eq 0 ] && echo "scenarios: all passed" || echo "scenarios: $sfail failed"
[ $((fail + sfail)) -eq 0 ]
