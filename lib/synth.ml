(* Type-directed synthesis of witness arguments.

   This lives apart from the witness generator because it has to run while the
   typed tree is still in hand. A [Types.type_expr] is a cyclic structure owned
   by the compiler and cannot be serialised, so summaries cannot carry one if
   they are to be cached across runs. Resolving each callee's arguments to
   concrete syntax at build time keeps the cached node free of compiler types.

   Values are deliberately non-trivial: an empty list would make
   [List.iter f []] perform nothing and the witness would prove nothing. *)

let rec value_of (ty : Types.type_expr) : string option =
  match Types.get_desc ty with
  | Types.Tlink t -> value_of t
  | Types.Tsubst (t, _) -> value_of t
  | Types.Tpoly (t, _) -> value_of t
  | Types.Ttuple ts ->
      let parts = List.map value_of ts in
      if List.exists (fun x -> x = None) parts then None
      else Some ("(" ^ String.concat ", " (List.map Option.get parts) ^ ")")
  | Types.Tconstr (p, args, _) -> (
      match (Path.name p, args) with
      | "unit", _ -> Some "()"
      | "int", _ -> Some "1"
      | "bool", _ -> Some "true"
      | "float", _ -> Some "1.0"
      | "char", _ -> Some "'w'"
      | "string", _ -> Some "\"witness\""
      | "list", [ a ] -> Option.map (fun v -> "[" ^ v ^ "]") (value_of a)
      | "array", [ a ] -> Option.map (fun v -> "[|" ^ v ^ "|]") (value_of a)
      | "option", [ a ] -> Option.map (fun v -> "(Some " ^ v ^ ")") (value_of a)
      | _ -> None)
  | _ -> None

let rec params ty acc =
  match Types.get_desc ty with
  | Types.Tarrow (_, a, b, _) -> params b (a :: acc)
  | Types.Tlink t -> params t acc
  | _ -> List.rev acc

(* [None] means "no witness can be built for this callee", which is reported
   rather than guessed at. *)
let args_for (ty : Types.type_expr) : string list option =
  match params ty [] with
  | [] -> None
  | ps ->
      let vs = List.map value_of ps in
      if List.exists (fun x -> x = None) vs then None
      else Some (List.map Option.get vs)
