(* Compiler-libs differences, for OCaml 5.3.

   Three unrelated 5.4 changes reach this project, and all of them are
   isolated here rather than sprinkled through the analysis code:

     1. [constructor_description] and [label_description] moved from [Types]
        to a new [Data_types] module, with no alias left behind.
     2. Labelled tuples changed [Types.Ttuple]'s payload from
        [type_expr list] to [(string option * type_expr) list].
     3. [Typedtree.Tpat_alias] gained a fifth field.

   Nothing here annotates the argument types: they are inferred from whichever
   shim is selected, which is what lets the same call sites compile on both
   compilers. See docs/TYPEDTREE-NOTES.md section 10. *)

let ext_path cd =
  match cd.Types.cstr_tag with
  | Types.Cstr_extension (p, _) -> Some p
  | _ -> None

let cstr_name cd = cd.Types.cstr_name
let cstr_arity cd = cd.Types.cstr_arity
let lbl_name lbl = lbl.Types.lbl_name

(* Components of a tuple type, dropping labels where the compiler has them. *)
let tuple_types ts = ts

(* One argument of a [Texp_apply]: the expression, or [None] if the call
   omitted it. 5.3 already gives an option; 5.4 gives [arg_or_omitted]. *)
let apply_arg a = a

(* [Tpat_alias]'s arity differs, so the pattern match itself has to live in the
   shim. Returning the aliased sub-pattern is all any caller wants from it. *)
let alias_pat : type k. k Typedtree.pattern_desc -> Typedtree.pattern option =
  function
  | Typedtree.Tpat_alias (p, _, _, _) -> Some p
  | _ -> None
