(* The abstract domain: the effects we could identify, plus a flag for whether
   anything unidentifiable is also in play.

   This used to be [Known of set | Top], where Top discarded everything. On
   real code that was actively harmful: a module initialiser that touches one
   unresolved external call collapsed to Top, and every known escaping effect
   in that module became invisible. The first ecosystem sweep reported zero
   escapes and 61 unknown warnings across 174 modules, which is exactly the
   shape that failure produces.

   Tracking both means an unresolved call costs precision only about the part
   we could not see. *)

type t = { known : Effect_id.Set.t; unknown : bool }

let empty = { known = Effect_id.Set.empty; unknown = false }
let top = { known = Effect_id.Set.empty; unknown = true }
let singleton e = { known = Effect_id.Set.singleton e; unknown = false }
let of_list l = { known = Effect_id.Set.of_list l; unknown = false }

let is_empty t = Effect_id.Set.is_empty t.known && not t.unknown
let has_unknown t = t.unknown
let known_elements t = Effect_id.Set.elements t.known

let join a b =
  { known = Effect_id.Set.union a.known b.known;
    unknown = a.unknown || b.unknown }

let join_list = List.fold_left join empty

(* Handler subtraction removes what we can name. The unknown component
   survives: an effect we could not identify might not be one of the handled
   ones, so discharging them proves nothing about it. *)
let subtract t handled = { t with known = Effect_id.Set.diff t.known handled }

let remove_where pred t =
  { t with known = Effect_id.Set.filter (fun e -> not (pred e)) t.known }

let select pred t = Effect_id.Set.elements (Effect_id.Set.filter pred t.known)

(* Membership is over the identified part only. Blame reconstruction uses this
   to decide whether to walk into a callee, and "might be inside the unknown
   part" is not evidence of a path. *)
let mem e t = Effect_id.Set.mem e t.known

let leq a b =
  Effect_id.Set.subset a.known b.known && ((not a.unknown) || b.unknown)

let equal a b = leq a b && leq b a

let to_string t =
  let names =
    List.map Effect_id.to_string (Effect_id.Set.elements t.known)
  in
  match (names, t.unknown) with
  | [], false -> "{}"
  | [], true -> "<unknown>"
  | ns, false -> "{" ^ String.concat ", " ns ^ "}"
  | ns, true -> "{" ^ String.concat ", " ns ^ ", ...unknown}"
