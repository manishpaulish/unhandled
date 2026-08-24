# Retroactive corpus

Historical, publicly documented `Effect.Unhandled` crashes. The claim we want
to be able to make is "would have caught N of M documented crashes", and it
does not depend on any maintainer replying to us, which is why this corpus
exists alongside the live sweep.

Sourced via the GitHub API:
`https://api.github.com/search/issues?q="Effect.Unhandled"+in:title`

## R1 — jeong-sik/masc#2271 (closed, fixed)

> `Fatal error: exception Stdlib.Effect.Unhandled(Eio__core__Cancel.Get_context)`
>
> Eio-native file operations require an Eio scheduler context. The test
> executable runs without `Eio_main.run`, causing `Effect.Unhandled` when
> `Eio.Cancel.Get_context` is raised.
>
> Fix: wrap the metrics test in `Eio_main.run`.

**This is precisely the B1/B2 case.** An Eio effect is reachable from an entry
point with no `Eio_main.run` anywhere on the path. Reproducing it needs the
repo at the parent of the fixing commit, plus its dependencies, so it is a task
for a machine with opam.

Two implementation bugs were found by reading this report:

1. The effect prints as `Eio__core__Cancel.Get_context` — OCaml's double
   underscore module mangling, **not** `Eio__core.Cancel.Get_context`. The
   prefix matcher required a `.` separator and would have missed every Eio
   effect in a real project. Fixed in `Schedulers.has_prefix`.
2. Sibling PRs (#1642, #3143, #3172) show the same codebase deliberately
   guarding with `try ... with Effect.Unhandled _ -> fallback`, in over fifty
   places. Flagging those would have been technically defensible and
   practically useless. Now recognised as a guard; see `test/guard/`.

## The corpus

`git log --all --grep="Effect.Unhandled"` on masc returns thirty commits. Six
are recorded in `bench/retro_commits_masc.txt`; the clearest read as "wrap
these tests in an Eio context", meaning that before the fix the code ran Eio
operations with no runtime installed. That is the same failure as R1.

Run the batch:

```
bash bench/retro_batch.sh masc https://github.com/jeong-sik/masc.git \
     bench/retro_commits_masc.txt
```

It analyses each commit's parent and writes `bench/results/masc.retro.csv`.
Commits that fail to build are recorded as such: they are part of the
denominator, and dropping them would inflate the catch rate.

## Candidates still to reproduce

- masc#1642, #3143, #3172 — the guard pattern itself, useful as negative tests.
- ocaml/ocaml#14644 — a bytecode heap-corruption bug involving
  `Effect.Unhandled`. Not our target class: a runtime defect, not a missing
  handler. Recorded so it is not mistaken for a finding.

## What the first retroactive attempt taught us

Two things, before any crash was reproduced.

`retro.sh masc ... 2271` printed `fix 2271` and analysed an unrelated commit:
git resolved the issue number as an abbreviated commit SHA. The script now only
treats the argument as a SHA when it is at least seven hex characters and
resolves, and searches commit messages first otherwise.

The sweep's blindness ranking was dominated by one library:

```
38  Alcotest.test_case
37  Alcotest.run
 4  Alcotest.testable
```

Roughly 79 of 107 unknown-effect warnings came from Alcotest, which meant
**every test executable was opaque** -- and test code is where these crashes
actually happen, R1 included. `Alcotest.test_case` takes the test body as a
function argument, so it is a higher-order combinator like `List.iter` and is
now modelled as one. `test/alcotest_like` covers it.

## Result of the first batch: caught 0 of 6

All six parents built and were analysed. Nothing was reported. This is the most
useful result the project has produced, because the reason is structural.

Read what those commits actually fix:

- *wrap coverage test helpers in Eio context*
- *wrap Eio-dependent tests in Eio context*
- *wrap state tests in Eio.Switch.run for Cancel.protect*
- *guard Domain_pool_ref submits against non-Eio callers*
- *surface an actionable error when Eio work runs on a bare systhread*

None of these is a handler missing from the call graph. Each is a **dynamic
context transfer**: code moves to a systhread, a new domain, or a fiber outside
the enclosing switch, and the handler stack installed at the call site does not
travel with it. The analysis modelled lexical and call-graph scope only, so it
had nothing to say.

Worse, `Domain.spawn` was modelled as a *combinator*, attributing the spawned
function's effects to its caller. That is exactly backwards: the spawned code
runs where the caller's handlers do not exist. The model actively asserted the
opposite of the truth.

Handler-scope transfers are now a boundary class (`Domain.spawn`,
`Thread.create`, `Eio_unix.run_in_systhread`), verified against the runtime in
`test/transfer/`: a program with a handler wrapped around
`Domain.join (Domain.spawn job)` still dies with
`Effect.Unhandled(Spawned.Work)`.

The honest reading for the report: a catch rate of 0/6 was not noise to be
tuned away, it was the analysis being blind to the most common real-world
failure mode. Whether the fix changes the number is the next measurement, and
whatever it returns goes in the table.

## Method

For each entry: check out the parent of the fixing commit, build with
`dune build @check`, run `unhandled check`, and record whether the effect named
in the report appears. Both outcomes go in the table; a documented crash we do
*not* catch is the most informative result available and belongs in the report.
