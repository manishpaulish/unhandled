# Design

## Pipeline

```
.cmt files -> extract -> symbolic effect expressions -> fixpoint -> escapes -> blame
```

## Why symbolic effect expressions

Handler subtraction is scoped to a *sub-expression*, not to a function. In

```ocaml
let f () = Effect.Deep.try_with g () h; Effect.perform E
```

`h` discharges whatever `g` performs — including effects arriving through calls
inside `g` — but it does not touch the `perform E` that follows.

Computing an effect *set* during the walk cannot express that, because the
contribution of `g` is not known until `g` has been solved. So the walk builds a
term:

```ocaml
type t =
  | Const of Effect_set.t
  | Perform of Effect_id.t * Location.t
  | Unknown of Location.t
  | Call of string * Location.t
  | Join of t list
  | Handle of t * handled
```

and the fixpoint evaluates it once summaries exist. Scoping stays exact and
blame paths fall out of the same structure.

## Domain

`Effect_set.t = Known of set | Top`.

`Top` means "may perform something we could not identify": an unresolved
higher-order call, a function with no summary, `perform` on a non-literal
effect. Two rules keep it honest:

- `Top \ handled = Top`. Removing known effects from an unknown set proves
  nothing.
- `Top` is reported as a warning, never silently treated as clean.

## Fixpoint

Summaries start at bottom (`{}`) and are recomputed until stable. The lattice is
finite and `eval` is monotone, so this terminates; recursion therefore gets its
least fixed point rather than an arbitrary answer.

## Effect identity

Extension-constructor path, qualified with the defining module when the path is
a `Pident`. `Mod_a.Emit` and `Mod_b.Emit` are different effects.

## Higher-order flow

Three tiers, in increasing precision:

1. **Conservative** — an unknown function value is `Top`.
2. **Effect-polymorphic combinators** (implemented) — `List.iter f xs` performs
   exactly what calling `f` performs. Without this, every idiomatic program
   degrades to `Top` and the tool is useless on real code.
3. **0-CFA** (planned) — resolve function values that flow through variables and
   data structures.

## Entry points

A module's initialisation effects are the join of its top-level bindings'
right-hand sides and top-level evaluations. A function literal contributes
nothing where it is written; its effects belong to whoever calls it. Anything
escaping module initialisation escapes the program.
