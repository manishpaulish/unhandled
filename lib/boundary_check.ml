(* Collect B3 findings: effects that can reach a fatal context. *)

type crossing = {
  b_effect : Effect_id.t;
  b_why : string;
  b_loc : Location.t;
}

let rec collect env acc (e : Eff_expr.t) =
  match e with
  | Eff_expr.Boundary (why, t, loc) ->
      let inner = Solver.eval env t in
      let acc =
        Effect_set.select (fun _ -> true) inner
        |> List.fold_left
             (fun a id -> { b_effect = id; b_why = why; b_loc = loc } :: a)
             acc
      in
      collect env acc t
  | Eff_expr.Join l -> List.fold_left (collect env) acc l
  | Eff_expr.Handle (t, _) | Eff_expr.Scheduler_run (_, t, _) -> collect env acc t
  | _ -> acc

let check env roots = List.fold_left (collect env) [] roots |> List.rev
