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
| Eio entry points and effects confirmed against upstream source | done |
| Effect-constructor alias canonicalisation (rebindings) | done |
| B3: effects in finalisers, signal handlers, GC alarms, C callbacks (`E004`) | done |
| Stdlib purity model (removes unknown-effect noise) | done |
| JSON output (`check --json`) | done |
| Sweep harness (`bench/sweep.sh`, 13 verified repos) | ready, needs opam |
| Self-host: 0 errors on own sources, wired into CI | done |
| OCaml 5.3 + 5.4 support via compat shim | done (5.4 path verified by CI) |
| `try ... with Effect.Unhandled` guard recognition | done |
| Handler-scope transfers: Domain.spawn, Thread.create, systhreads | done |
| Alcotest / Unix / module-alias resolution (blindness 48 -> 20 on masc) | done |
| Retroactive corpus: 6 commits, caught 0, build failed 0 | measured; see bench/NEGATIVE-RESULT.md |
| Eio API requirement model (`api`/`requires`) | done |
| Scenario tests (cross-module, contract, witness, B2) | done |
| Differential fuzzer, runtime as oracle | done |
| **1000 generated programs: 0 false negatives** | measured |
| Branch-free: 600 programs, 0 FP, 0 FN | measured |
| Branching: 400 programs, 5.3% FP, 0 FN (join over-approximation) | measured |

## Next, in order

1. **Confirm riot/moonpool/miou paths** against their sources. Eio is done and
   cited in `models/schedulers.conf`; the others are still provisional.
2. **Scale the fuzzer to 10k seeds** now that both modes are in place, and add
   recursion and multi-module generation.
3. **Sweep harness** over opam repos; retroactive crash corpus.
4. 0-CFA behind `--cfa`, then LSP.
5. 0-CFA for function values that flow through data.

## Known gaps

See `docs/LIMITATIONS.md`. The most important: effects performed inside
`effc` branch bodies are not yet attributed.

## What I need from you

The sweep is the critical path and it cannot run here: this sandbox has no
opam access, so real projects cannot be built and no `.cmt` files exist for
them. `bench/sweep.sh` is written and ready.

```
dune build
bash bench/sweep.sh                 # ~13 repos, expect attrition
REPOS="eio picos" bash bench/sweep.sh    # quick first look
```

Paste back `bench/results/sweep.csv` and I can triage the findings, drive the
witness generator over them, and turn the survivors into upstream issues.

## Environment note

The sandbox this was built in has no opam access, so the compiler was built
from source and a `Makefile` fallback exists alongside the dune build. On a
normal machine, `dune build` is the supported path; `make` needs
`CL=$(ocamlc -where)/compiler-libs` only if `ocamlc -where` is unreliable.
