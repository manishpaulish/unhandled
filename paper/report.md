# unhandled: a static effect-safety checker for OCaml 5

**Team Skill Issue — SegFault 2026**

---

## 1. The problem

OCaml 5's effect handlers are untyped. The manual states it directly, in
*Language extensions → Effect handlers → Unhandled effects*:

> Unlike languages such as Eff and Koka, effect handlers in OCaml do not
> provide effect safety; the compiler does not statically ensure that all the
> effects performed by the program are handled.

A missing handler compiles without warnings and raises `Effect.Unhandled` at
the point of `perform`. Effect handlers power OCaml 5's concurrency stack —
Eio, Riot, Miou, Moonpool, Domainslib — so the language's flagship feature
ships with no static guard against its own failure mode. Typed effect systems
are active research with no landing date.

`unhandled` is a static analyser that reports effects which can escape, working
from the compiler's own typed ASTs, with no annotations and no forked compiler.

## 2. Approach

**Symbolic effect expressions.** Handler subtraction is scoped to a
sub-expression, not to a function: in `try_with g () h; perform E`, the handler
discharges what `g` performs — including effects arriving through calls — but
not the `perform E` that follows. A pass that accumulated effect *sets* could
not express this, because `g`'s contribution is unknown until `g` is solved. So
the walk builds a term:

```
t ::= Const s | Perform e | Unknown | Call f
    | Join [t] | Handle (t, h) | Scheduler_run (s, t) | Boundary (why, t)
```

which is evaluated after summaries exist. Scoping stays exact, and blame paths
fall out of the same structure.

**Domain.** `{ known : EffectSet; unknown : bool }`. The `unknown` flag records
that something unidentifiable is also in play. An earlier design used
`Known of set | Top`, where one unresolved call collapsed the whole set; §4.4
describes how the ecosystem sweep exposed that.

**Fixpoint.** Summaries start at bottom and are recomputed until stable. The
lattice is finite and evaluation is monotone, so recursion receives its least
fixed point.

## 3. What it detects

| Code | Class |
|---|---|
| E001 | An effect escapes to a program entry point with no handler on the path |
| E003 | An effect belonging to one scheduler is performed under another's runtime |
| E004 | An effect reaches a context where no handler can ever catch it |
| W002 | Effects of unidentifiable origin may escape, with the unresolved callees named |

E004 covers finalisers, signal handlers, GC alarms, memprof callbacks, C
`caml_callback` frames — all documented by the manual as always fatal — and
**handler-scope transfers**: `Domain.spawn`, `Thread.create`,
`Eio_unix.run_in_systhread`. A handler lives on one fiber's stack; moving
execution elsewhere leaves it behind.

**Library and executable modes.** A library that performs effects is not buggy;
its handler lives in the application. `unhandled contract` reports what a
module asks callers to handle; `check` reports errors for whole programs.
Without this distinction every Eio-based library reads as broken.

**Witnesses.** Each finding is turned into a program that is generated,
compiled and run. The witness installs a handler for the effect under
suspicion and reports a positive confirmation when it arrives — it does not
parse the crash message, because the runtime prints the effect payload only
sometimes. A confirmed finding is a true positive by construction.

## 4. Evaluation

### 4.1 Differential fuzzing, with the runtime as oracle

`test/fuzz` generates random effectful programs. It does not compute an
expected answer: it asks the analyser whether an effect escapes, then **runs
the program**. Reality decides.

| Mode | Programs | False positives | False negatives | Agreement |
|---|---|---|---|---|
| branch-free | 600 | 0 | 0 | 100% |
| branching | 400 | 21 (5.3%) | 0 | 94.7% |

**Zero false negatives across 1000 generated programs.** The imprecision is
one-sided: the analyser over-approximates and never goes quiet about a crash
that happens. The branching false positives are join over-approximation, and
we verified that rather than assuming it: in `fp_seed122` the flagged `perform`
sits in an `else` branch that never executes. The two modes are reported
separately so known imprecision cannot bury a real defect.

### 4.2 Production code

The corpus is derived from opam rather than written by hand: every published
package depending on `eio`, `eio_main`, `picos`, `domainslib`, `riot`,
`moonpool` or `miou`, resolved to its `dev-repo` and deduplicated by URL
(`bench/discover.sh`). 114 packages, 5 dropped for having no usable
`dev-repo`, **85 repositories**. An earlier hand-written list of 4 was not a
search, and a finding rate measured over it would have been a finding rate
over one person's recall.

#### The first three escapes were ours, not theirs

The first escapes this tool ever reported on third-party code were three in
`cohttp-eio`, and triaging them against the upstream source showed all three
were false positives:

```
cohttp-eio/src/body.ml:20    let of_string =
                               let ops = Eio.Flow.Pi.source (module S) in ...
cohttp-eio/src/utils.ml:44   let flow_of_reader =
                               let handler = Eio.Flow.Pi.source (module R) in ...
cohttp-eio/tests/test_forward_proxy.ml:9    Eio.Stream.create 1
```

The analyser was right about *when*: those calls really do run at module
initialisation. It was wrong about *what*. `Pi.source` builds a
`Resource.handler` from a first-class module, `Stream.create` allocates a
queue, and neither can suspend. The argument that settles it needs no source
reading: `cohttp-eio` is widely deployed, so if its module initialisation
required a runtime, every program linking it would die before `main`.

The cause was the `api` rule treating every path under `Eio.` as requiring the
runtime. `models/schedulers.conf` now carries a `pure` exception list, each
entry cited to a line in eio's own source, and the list grows only on an
observed false positive whose purity is then confirmed there — guessing would
trade a false positive for a false negative, and the false negative is the one
we claim not to have. `cohttp-eio` went from 3 escapes to 0; `test/eio_pure`
and `test/eio_api` pin both directions of the rule.

We report this because it is the honest shape of the result. A tool whose
first real-world findings are all its own fault, found by reading the code it
accused, is worth more than one that reports three numbers and never checks
them.

`contract` extracts correct, useful contracts from the same corpus:

```
module Picos
  Picos.Trigger.await                may perform {Picos.Trigger.Await}
  Picos.Fiber.spawn                  may perform {Picos.Fiber.Spawn}
  Picos.Fiber.yield                  may perform {Picos.Fiber.Yield}
  Picos.Fiber.Maybe.current_and_check_if may perform {Picos.Fiber.Current, ...unknown}

module Picos_std_structured__Run
  Picos_std_structured__Run.spawn    may perform {Picos.Fiber.Spawn, ...unknown}
```

`...unknown` marks a contract that is incomplete at that function because it
calls into code with no `.cmt`. Printing it is the point: a contract that
quietly rounded down to a clean-looking set would be worth less than one that
says where it stops knowing.

### 4.3 Incremental checks

Summaries are cached per module, keyed by `.cmt` digest **and by the digest of
the analyser binary**. 200 modules: cold 0.18s, warm 0.05s, plus ~10ms per run
to hash the checker itself. `bench/perf.sh` compares cached against
`--no-cache` output byte for byte before reporting a timing, and
`test/run_tests.sh` asserts that cold, warm and `--no-cache` runs agree.

The second half of the key is not defensive dressing. Keyed on the `.cmt`
alone, changing the analyser and leaving the sources untouched makes every
module a cache hit carrying the *previous* build's answer: a false negative
manufactured by the cache rather than by the analysis, and one that CI cannot
see because CI always starts cold. We found it by sabotage — breaking
`Compat.alias_pat` and watching the false positive it should have caused fail
to appear on a warm run. When the checker cannot identify its own build it
refuses the cache instead of trusting a key that does not distinguish builds.

The same run exposed a second, quieter problem: the scenario tests did not
clear `.unhandled-cache` between runs, so locally they could pass against a
broken analyser. They now start cold.

### 4.4 A negative result, and what it cost

We attempted to reproduce six documented `Effect.Unhandled` crashes by
analysing the commit before each fix. **Caught 0 of 6, with 0 build failures.**

Three rounds of fixes did not move that number, and each round found a real
defect:

1. The domain discarded identified effects whenever any call was unresolved.
2. Alcotest accounted for ~79 of 107 unknown-effect warnings, so every test
   executable was opaque; module aliases (`module D = Foo`) resolved to
   nothing.
3. `Domain.spawn` was modelled as a combinator, attributing spawned effects to
   the caller — the opposite of the truth.
4. Eio, being an installed dependency with no `.cmt`, contributed no named
   effect at all, so nothing could be reported about a call into it.

None was the reason. The reason is verifiable in one command:

```
$ find bench/_retro/masc/_build -name '*.cmt' | grep -ci eio
0
```

The application's Eio-dependent modules never compiled in our environment. The
corpus never contained the buggy code, so no model could have caught it.

**The transferable finding: a synthetic corpus validates the algorithm, only
real code validates the model.** All four defects were found by contact with
real projects. The 1000-program fuzzer found none of them, because generated
programs call nothing the analyser cannot see.

### 4.5 Two compilers

The full suite passes on OCaml 5.3 and 5.4, verified in CI on both. Reading
the typed tree makes the tool sensitive to compiler internals, and 5.4 moved
four of the things it reads: constructor and label descriptions to a new
`Data_types` module, an extra field on `Tpat_alias`, labels into
`Types.Ttuple`, and `Texp_apply`'s arguments from `expression option` to
`arg_or_omitted`. All four are isolated in a shim selected by dune on
`%{ocaml_version}`; `docs/TYPEDTREE-NOTES.md` section 10 tabulates them
alongside the constructs verified *unchanged*, so the audit can be checked
rather than trusted. Development happened on 5.3 and nothing on a 5.3 machine
could have found any of them.

One result here is worth more than the portability itself. 5.4 stopped
printing the effect payload in `Effect.Unhandled` for two corpus programs that
printed it on 5.3. Nothing had to change: witnesses confirm a finding by
installing a handler for the effect they are trying to prove and observing it
arrive, never by parsing the crash message (section 7 of the same document).
A checker built on `grep` would have produced a suite of broken proofs on a
compiler upgrade that changed no semantics at all.

## 5. Limitations

Stated in full in `docs/LIMITATIONS.md`. The ones that matter:

- **Unsound** for effects performed inside `effc` branch bodies, dynamically
  built handler records, and closures reaching call sites through data
  structures (0-CFA is not implemented).
- **Conditionals** are joined, so an effect on a never-taken branch is still
  reported: 5.3% of 400 generated branching programs.
- **Modelling assumptions** about third-party libraries — `Unix`, `Str`,
  `Ptime`, `Yojson` and others treated as performing no user effects; Alcotest
  modelled as a combinator; a call into Eio's API modelled as requiring the Eio
  runtime. Each was added because measurement showed it dominating the blind
  spots, and a wrong entry hides bugs rather than adding noise.
- **`try ... with Effect.Unhandled`** is treated as discharging its body. One
  real codebase does this in over fifty places deliberately.
- **Whole-program analysis needs the whole program.** §4.4 is the honest
  demonstration of what that costs.

## 6. Related work

`ocamlexc` (Leroy and Pessaux) is the classic uncaught-*exception* analyser,
unmaintained since roughly OCaml 3.12 and predating effects. Salto (INRIA)
targets OCaml 4.14, a version without effects. Jane Street's `handled_effect`
is an opt-in typed API requiring code to be rewritten. Modal effect types are
the eventual real fix, with no implementation timeline.

Effects are harder to analyse than exceptions: handlers install dynamically,
continuations resume, the handled set is decided by runtime handler records
rather than syntax, and effect identity is scheduler-scoped. Constructor
re-export makes identity itself non-obvious — `Eio__core.Private.Effects.Fork`
and `Fiber.Fork` are the same effect under two paths, and neither the path nor
the uid unifies them.

## 7. Conclusion

`unhandled` reports effects that escape, in four classes, on unmodified OCaml 5
code, and proves its findings by executing them. It is measured rather than
asserted: zero false negatives over 1000 generated programs, a published
false-positive rate, sub-second incremental checks, and a negative result
reported in full rather than tuned away.

Reproduce everything with `make demo`.
