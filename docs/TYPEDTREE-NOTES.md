# Typedtree notes (OCaml 5.3.0)

Empirical findings from `ocamlc -dtypedtree` and the compiler's own `.mli`
files. **Do not take any of this from memory or from an LLM** — re-derive it
with the probes in `docs/typedtree-notes/` if you move to another compiler
version. Everything downstream depends on these shapes being right.

Probes: `t1_syntactic.ml`, `t2_deep.ml`, `t3_escape.ml`, `probe_paths.ml`.

---

## 1. `perform` is recognised by `Path.name`

```
Texp_apply (Texp_ident (p, _, _), [(Nolabel, Some arg)])
  where Path.name p = "Stdlib.Effect.perform"
```

The `-dtypedtree` output renders this as `Stdlib!.Effect.perform`. **The `!` is
a printer artefact and is not in `Path.name`.** Matching on the printed form
will silently fail. We accept `Stdlib.Effect.perform`, `Stdlib__Effect.perform`
and `Effect.perform`.

## 2. Effect identity comes from `Cstr_extension`

The argument of `perform` is normally `Texp_construct (_, cd, _)` where
`cd.cstr_tag = Types.Cstr_extension (path, _)`.

**Critical:** for an effect declared in the module being analysed, that path is
a `Pident`, so `Path.name` is the bare constructor name — `"Emit"`, not
`"Mymod.Emit"`. Two different modules can each declare `Emit`; those are
different effects and must not be unified. We therefore qualify bare paths with
the defining module name (`Effect_id.of_path ~modname`).

If the argument is not a literal constructor (the effect value came from a
variable), identity is unknown and the site must become `Top`, never "no
effect".

## 3. `Texp_match` and `Texp_try` carry effect cases in a *separate* list

From `typing/typedtree.mli`:

```ocaml
| Texp_match of expression * computation case list * value case list * partial
| Texp_try   of expression * value case list * value case list
```

The **third** component is the effect cases. Note `Texp_try` has them too —
`try e with effect A, k -> ...` is legal and easy to forget.

`Tast_iterator` walks both lists through the same `sub.case`, so an iterator
that only overrides `case` **cannot tell an effect case from an ordinary one**.
We override `expr` and destructure these two nodes explicitly.

The scrutinee of the match (or the body of the try) is the computation whose
effects the handler discharges.

A wildcard effect case (`| effect _, k ->`) genuinely handles *every* effect —
represented as `handled = All`.

## 4. `effc` handler records — the shape that matters most

Most real code, Eio included, installs handlers through the runtime API rather
than the 5.3 syntax. Confirmed shape for `Effect.Deep.try_with comp arg h`:

```
Texp_apply (Texp_ident "Stdlib.Effect.Deep.try_with",
            [comp; arg; Texp_record { fields = [| effc = Overridden (_, fn) |] }])

fn = Texp_function (_, Tfunction_body (
       Texp_match (Texp_ident "eff",
         [ Tpat_construct "A" -> Texp_construct "Some" [...]     (* HANDLED  *)
         ; Tpat_any           -> Texp_construct "None" ], ...))) (* FORWARDED *)
```

**The `| _ -> None` arm forwards to the outer handler; it handles nothing.**
Reading it as a catch-all makes the analyser silently blind — it is the single
most dangerous mistake in this project. `test/corpus/wildcard_trap.ml` locks
this behaviour down.

Arms whose right-hand side we cannot classify are treated as *not* handled.
That can cost precision but never hides a bug.

Handler-argument index is 2 for `Deep.try_with`, `Deep.match_with`,
`Shallow.continue_with`.

## 5. Constructor arities that differ from the obvious guess

Verified against 5.3.0 — several of these are the exact places a plausible
guess is wrong:

| Node | Arity |
|---|---|
| `Texp_ident` | `Path.t * Longident.t loc * value_description` |
| `Texp_construct` | `Longident.t loc * constructor_description * expression list` |
| `Texp_apply` | `expression * (arg_label * expression option) list` |
| `Texp_function` | `function_param list * function_body` |
| `Tstr_eval` | **2 args**, not 3 |
| `Tpat_alias` | **4 args** |
| `Texp_constraint` | **does not exist** — type constraints are erased |

`function_body = Tfunction_body of expression | Tfunction_cases of { cases; ... }`.

## 6. Getting the immediate children of an expression

Rather than enumerating forty constructors, hand `Tast_iterator`'s
*default* `expr` an iterator whose `expr` collects without recursing:

```ocaml
let children e =
  let acc = ref [] in
  let it = { Tast_iterator.default_iterator with
             expr = (fun _ child -> acc := child :: !acc) } in
  Tast_iterator.default_iterator.expr it e;
  List.rev !acc
```

This yields exactly one level. Every construct that is not a handler
installation is then handled generically and correctly.

## 7. Runtime observability of the unhandled effect (affects witness design)

The two crashes below are the *same* bug class but print differently:

```
Fatal error: exception Effect.Unhandled
Fatal error: exception Stdlib.Effect.Unhandled(Wildcard_trap.B)
```

The payload appears only in some cases (observed when an enclosing handler
declined the effect). **A witness must therefore not rely on parsing the crash
message.** The robust witness installs a handler for the specific effect it is
trying to prove and reports a positive confirmation when that effect arrives:

```ocaml
match target () with
| _ -> print_endline "NOT_CONFIRMED"
| effect Target, _ -> print_endline "CONFIRMED"
```

This proves the effect reaches an outer boundary unhandled, which is exactly
the claim being made, and does not depend on the printer.

## 8. Effect constructors can be re-exported, and the alias is what you see

```ocaml
module Effects = struct
  type _ Effect.t += Fork = Fiber.Fork    (* a rebinding, not a new effect *)
end
```

Both names denote the same runtime effect. The typed tree reports **the path
that was written**, not the original:

```
path=Orig.Fork                 uid=Orig.0
path=Reexport.Effects.Fork     uid=Reexport.0
```

The uid does not unify them either, so neither the path nor the uid is a
canonical identity on its own. Eio does exactly this (`Eio__core.Private.
Effects.Fork = Fiber.Fork`), so a handler written against one name would not
be seen to discharge a perform written against the other, and every such
program would be a false positive on the very first real sweep.

The fix is to follow the rebinding. In the typed tree a rebinding appears as

```ocaml
Tstr_typext { tyext_constructors = [ { ext_id; ext_kind = Text_rebind (path, _) } ] }
```

`Builder.collect_aliases` records `Module.ext_id -> path` for every unit in a
pre-pass, and `Effect_id.of_path` resolves through that map transitively. The
pre-pass has to complete before the first summary is built, because identity
must already be canonical when the first set is constructed.

Regression fixture: `test/alias/`.

## 9. Compiler version floor and the 5.4 move

Verified against the compilers' own `typing/typedtree.mli`:

| | 5.2 | 5.3 | 5.4 |
|---|---|---|---|
| `Texp_match` | `expr * computation case list * partial` | `expr * computation case list * value case list * partial` | same as 5.3 |
| `Texp_try` | `expr * value case list` | `expr * value case list * value case list` | same as 5.3 |
| constructor descriptions | `Types` | `Types` | **`Data_types`** |

**5.3 is the floor.** The effect-case lists only appear in 5.3, so on 5.1/5.2
the typed tree cannot express the thing this tool analyses. That is not a
portability gap to paper over: `match ... with effect` did not exist before
5.3 either.

**5.4 moved `constructor_description` and `Cstr_extension` from `Types` to a
new `Data_types` module, with no alias left behind.** `lib/compat_53.ml` and
`lib/compat_54.ml` isolate that; dune picks one on `%{ocaml_version}`. Call
sites must not annotate the argument type, because the type differs between
the two shims and inference is what makes the same code compile on both.
