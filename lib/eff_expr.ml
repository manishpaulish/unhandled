(* A symbolic effect expression.

   We do not compute an effect *set* directly while walking the tree, because
   handler subtraction is scoped to a sub-expression: the effects of everything
   inside [try_with comp () h] are discharged by [h], including effects that
   arrive through calls. Building a symbolic term first, and evaluating it
   against call summaries afterwards, keeps that scoping exact. *)

type t =
  | Const of Effect_set.t
  | Perform of Effect_id.t * Location.t
  | Unknown of Location.t              (* Top with a place to blame *)
  | Call of string * Location.t
  | Join of t list
  | Handle of t * Effect_syntax.handled

let empty = Const Effect_set.empty
let join ts = Join ts
