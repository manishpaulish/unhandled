(* The abstract domain: a finite set of known effects, or Top.

   [Top] means "may perform effects we could not determine" and arises from
   unresolved higher-order calls, calls to functions we have no summary for,
   and [perform] applied to a non-literal effect value. Top is deliberately
   *not* silently dropped: it is reported as an unknown, never as "clean". *)

type t = Known of Effect_id.Set.t | Top

let empty = Known Effect_id.Set.empty
let top = Top
let is_empty = function Known s -> Effect_id.Set.is_empty s | Top -> false
let singleton e = Known (Effect_id.Set.singleton e)

let of_list l = Known (Effect_id.Set.of_list l)

let join a b =
  match (a, b) with
  | Top, _ | _, Top -> Top
  | Known x, Known y -> Known (Effect_id.Set.union x y)

let join_list = List.fold_left join empty

(* Handler subtraction. [Top \ h] stays [Top]: an effect we could not identify
   might not be one of the handled ones, so removing them proves nothing. *)
let subtract t handled =
  match t with
  | Top -> Top
  | Known s -> Known (Effect_id.Set.diff s handled)

let leq a b =
  match (a, b) with
  | _, Top -> true
  | Top, Known _ -> false
  | Known x, Known y -> Effect_id.Set.subset x y

let equal a b = leq a b && leq b a

let remove_where pred = function
  | Top -> Top
  | Known s -> Known (Effect_id.Set.filter (fun e -> not (pred e)) s)

(* Top cannot be enumerated, so selection returns only what we can name. *)
let select pred = function
  | Top -> []
  | Known s -> Effect_id.Set.elements (Effect_id.Set.filter pred s)

let mem e = function Known s -> Effect_id.Set.mem e s | Top -> true

let elements = function Known s -> Effect_id.Set.elements s | Top -> []

let to_string = function
  | Top -> "<unknown>"
  | Known s ->
      if Effect_id.Set.is_empty s then "{}"
      else
        "{" ^ String.concat ", "
                (List.map Effect_id.to_string (Effect_id.Set.elements s)) ^ "}"
