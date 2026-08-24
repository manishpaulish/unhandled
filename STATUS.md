# Status

## What works right now (verified, not claimed)

`make && bash test/run_tests.sh` on **OCaml 5.3.0** →
**11 corpus + 13 scenarios + 3 cache checks + 4 language-server checks passed,
0 failed**. Every corpus case is checked against the analyser's prediction *and*
the program's actual runtime behaviour.

| Capability | State |
|---|---|
| `.cmt` ingestion via `compiler-libs` | done |
| Effect identity (module-qualified, `Cstr_extension`) | done |
| Abstract domain: identified effects plus an unknown flag | done |
| Syntactic handlers `match ... with effect` | done |
| `try ... with effect` (separate effect-case list) | done |
| `Effect.Deep.try_with` / `match_with` / `Shallow` via `effc` | done |
| `\| _ -> None` treated as forwarding, not handling | done, locked by test |
| Scoped handler subtraction | done |
| Call-graph Kleene fixpoint (incl. recursion) | done |
| Effect-polymorphic combinator summaries (`List.iter` etc.) | done |
| Blame paths from entry to `perform` | done |
| CLI `check` / `summaries` / `contract` / `witness` / `facts` | done |
| Three-way differential test harness | done |
| Cross-module whole-program analysis | done |
| Witness generation (synthesise, compile, run, confirm) | done |
| Type-directed argument synthesis | done |
| Scheduler model table + B2 mismatch detection (`E003`) | done |
| Eio entry points and effects confirmed against upstream source | done |
| Effect-constructor alias canonicalisation (rebindings) | done |
| B3: effects in finalisers, signal handlers, GC alarms, C callbacks (`E004`) | done |
| Stdlib purity model (removes unknown-effect noise) | done |
| JSON output (`check --json`) | done |
| Sweep over real projects | done: 4 repos, 316 modules |
| Self-host: 0 errors on own sources, wired into CI | done |
| `try ... with Effect.Unhandled` guard recognition | done |
| Handler-scope transfers: Domain.spawn, Thread.create, systhreads | done |
| Alcotest / Unix / module-alias resolution (blindness 48 -> 20 on masc) | done |
| Retroactive corpus: 6 commits, caught 0, build failed 0 | measured; see `bench/NEGATIVE-RESULT.md` |
| Eio API requirement model (`api`/`requires`) | done |
| Incremental cache, keyed on `.cmt` **and analyser** digest | done; cold/warm/`--no-cache` agreement asserted in the suite |
| `make demo`: six sections, all executed live | done |
| LSP server with blame path as `relatedInformation` | done, protocol-tested |
| Differential fuzzer, runtime as oracle | done |
| **1000 generated programs: 0 false negatives** | measured |
| Branch-free: 600 programs, 0 FP, 0 FN | measured |
| Branching: 400 programs, 5.3% FP, 0 FN (join over-approximation) | measured |
| CI on OCaml 5.3 and 5.4 | both green (run #9, commit `83e5ef7`) |
| Full suite under 5.4.1 locally | 11 corpus + 13 scenarios + 3 cache + 4 LSP, 0 failed |

## Next, in order

1. **Confirm riot / moonpool / miou scheduler paths** against their sources.
   Eio is done and cited in `models/schedulers.conf`; the others are still
   provisional and labelled as such.
2. **Scale the fuzzer to 10k seeds** and add recursion and multi-module
   generation.
3. Post the tool to `discuss.ocaml.org` — the only remaining route to
   third-party validation, since the retroactive corpus produced none.
4. 0-CFA behind `--cfa`, for function values that flow through data.

## Known gaps

See `docs/LIMITATIONS.md`. The most important: effects performed inside `effc`
branch bodies are not yet attributed.

## Build

```
dune build
bash test/run_tests.sh
```

A `Makefile` fallback exists for environments without opam or dune; it selects
the same compat shim by inspecting `ocamlc -version`. `dune build` is the
supported path.
