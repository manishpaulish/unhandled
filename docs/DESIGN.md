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

`Effect_set.t = { known : Effect_id.Set.t; unknown : bool }`.

`unknown` records that something unidentifiable is also in play: an unresolved
higher-order call, a function with no summary, `perform` on a non-literal
effect value.

This was originally `Known of set | Top`, and the difference matters. Under the
old domain a module initialiser that touched a single unresolved external call
collapsed to `Top`, discarding every effect we *had* identified in that module.
The first ecosystem sweep showed the symptom clearly: 174 modules of real code,
zero escapes, 61 unknown warnings. Carrying both components means an unresolved
call costs precision only about the part we could not see.

Two rules keep it honest:

- Handler subtraction removes only from `known`; `unknown` survives, since an
  effect we could not identify might not be one of the handled ones.
- `unknown` is reported as a warning, never silently treated as clean.

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
