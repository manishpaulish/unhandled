(* Constructor-description access for OCaml 5.3.

   In 5.4 these types moved from [Types] to a new [Data_types] module with no
   alias left behind, so every use has to go through this shim. Nothing here
   annotates the argument type: it is inferred from the module that is
   selected, which is what lets the same call sites compile on both. *)

let ext_path cd =
  match cd.Types.cstr_tag with
  | Types.Cstr_extension (p, _) -> Some p
  | _ -> None

let cstr_name cd = cd.Types.cstr_name
let cstr_arity cd = cd.Types.cstr_arity
