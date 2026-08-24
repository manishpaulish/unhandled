# Status — end of build session

## What works right now (verified, not claimed)

Built and tested against **OCaml 5.3.0** compiled from source in a clean
environment. `make && bash test/run_tests.sh` → **10 corpus + 4 scenarios passed, 0 failed**, where
every case is checked against the analyser's prediction *and* the program's
actual runtime behaviour.

| Capability | State |
|---|---|
| `.cmt` ingestion via `compiler-libs` | done |
| Effect identity (module-qualified, `Cstr_extension`) | done |
| Abstract domain with absorbing `Top` | done |
| Syntactic handlers `match ... with effect` | done |
| `try ... with effect` (separate effect-case list) | done |
| `Effect.Deep.try_with` / `match_with` / `Shallow` via `effc` | done |
| `\| _ -> None` treated as forwarding, not handling | done, locked by test |
| Scoped handler subtraction | done |
| Call-graph Kleene fixpoint (incl. recursion) | done |
| Effect-polymorphic combinator summaries (`List.iter` etc.) | done |
| Blame paths from entry to `perform` | done |
| CLI `check` / `summaries` | done |
| Three-way differential test harness | done |
| Cross-module whole-program analysis | done |
| Witness generation (synthesise, compile, run, confirm) | done |
| Type-directed argument synthesis | done |
| Library mode: effect contracts (`contract`) | done |
| Scheduler model table + B2 mismatch detection (`E003`) | done |
| Scenario tests (cross-module, contract, witness, B2) | done |
| Differential fuzzer, runtime as oracle | done |
| **600 generated programs: 0 false positives, 0 false negatives** | measured |

## Next, in order

1. **Confirm real scheduler paths** in `models/schedulers.conf` against
   installed Eio/Riot sources. The mechanism is done; the data is provisional.
2. **Scale the fuzzer to 10k seeds** and add a branching mode, reported
   separately so join-imprecision is visible rather than hidden.
3. **Sweep harness** over opam repos; retroactive crash corpus.
4. 0-CFA behind `--cfa`, then LSP.
5. B3: boundary-crossing effects (signal handlers, finalisers, C callbacks).

## Known gaps

See `docs/LIMITATIONS.md`. The most important: effects performed inside
`effc` branch bodies are not yet attributed.

## Environment note

The sandbox this was built in has no opam access, so the compiler was built
from source and a `Makefile` fallback exists alongside the dune build. On a
normal machine, `dune build` is the supported path; `make` needs
`CL=$(ocamlc -where)/compiler-libs` only if `ocamlc -where` is unreliable.
