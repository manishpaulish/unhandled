(* Constructor-description access for OCaml 5.4.

   In 5.4 these types moved from [Types] to a new [Data_types] module with no
   alias left behind, so every use has to go through this shim. Nothing here
   annotates the argument type: it is inferred from the module that is
   selected, which is what lets the same call sites compile on both. *)

let ext_path cd =
  match cd.Data_types.cstr_tag with
  | Data_types.Cstr_extension (p, _) -> Some p
  | _ -> None

let cstr_name cd = cd.Data_types.cstr_name
let cstr_arity cd = cd.Data_types.cstr_arity
