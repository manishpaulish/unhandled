# unhandled

**A static effect-safety checker for OCaml 5 — the analyzer that proves its own warnings.**

OCaml 5's effect handlers are untyped. The manual says so plainly:

> Unlike languages such as Eff and Koka, effect handlers in OCaml do not
> provide effect safety; the compiler does not statically ensure that all the
> effects performed by the program are handled.

So this compiles with zero warnings and crashes in production:

```ocaml
type _ Effect.t += Emit : string -> unit Effect.t

let log msg    = Effect.perform (Emit msg)
let process xs = List.iter log xs
let ()         = process (load_batch ())
```

`unhandled` catches it before you ship it:

```
$ unhandled check .
esc_simple.ml:4:9: error[E001] effect Esc_simple.Emit escapes unhandled
  entry     Esc_simple (module initialisation)
  via       esc_simple.ml:4:9   calls Esc_simple.process
  then      esc_simple.ml:3:27  calls Esc_simple.log
  then      esc_simple.ml:2:17  performs Emit

1 error(s), 0 warning(s)
```

No forked compiler, no annotations, no code changes: it reads the `.cmt` files
your build already produces.

## Status

Week 1 of SegFault 2026. Working today:

- effect inference from typed ASTs, with module-qualified effect identity
- call-graph fixpoint with correct, **scoped** handler subtraction
- syntactic handlers (`match`/`try ... with effect`, OCaml 5.3+)
- runtime-API handlers (`Effect.Deep.try_with` / `match_with` / `Shallow`),
  including correct treatment of the `| _ -> None` forwarding arm
- effect-polymorphic summaries for higher-order stdlib combinators
- blame paths from module entry down to the offending `perform`

## Build

```
dune build
dune exec bin/unhandled.exe -- check _build/default
```

## Test

`test/run_tests.sh` is a three-way differential test: for every corpus program
it compares the declared expectation, the analyser's prediction, **and what the
program actually does when executed**.

```
$ bash test/run_tests.sh
PROGRAM                EXPECTED       ANALYSER       RUNTIME        RESULT
------------------------------------------------------------------------------
esc_simple             crash Emit     crash Emit     crash ?        PASS
lambda_iter            crash Emit     crash Emit     crash ?        PASS
local_helper           crash Ping     crash Ping     crash ?        PASS
nested_forward         clean          clean          clean          PASS
nested_partial         crash B        crash B        crash B        PASS
ok_deep                clean          clean          clean          PASS
ok_handled             clean          clean          clean          PASS
recursion              crash Tick     crash Tick     crash ?        PASS
try_effect             clean          clean          clean          PASS
wildcard_trap          crash B        crash B        crash B        PASS
------------------------------------------------------------------------------
10 passed, 0 failed
```

## Documentation

- `docs/TYPEDTREE-NOTES.md` — empirical notes on the OCaml 5.3 typed tree. Read
  this before touching `lib/effect_syntax.ml`.
- `docs/DESIGN.md` — the analysis, and why it is shaped this way.
- `docs/LIMITATIONS.md` — where it is unsound, stated plainly.

## Licence

MIT.
