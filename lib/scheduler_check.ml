(* B2: scheduler mismatch.

   OCaml's concurrency libraries are mutually incompatible effect schedulers.
   An Eio operation performed under Riot's runtime is not a missing handler in
   the ordinary sense: a handler is installed, it just belongs to the wrong
   library, and the program is guaranteed to crash. Reporting that as "effect
   escapes unhandled" would be technically true and practically useless, so it
   gets its own diagnostic. *)

type mismatch = {
  m_effect : Effect_id.t;
  m_owner : string;          (* scheduler the effect belongs to *)
  m_running_under : string;  (* scheduler actually installed here *)
  m_loc : Location.t;
}

let rec collect env acc (e : Eff_expr.t) =
  match e with
  | Eff_expr.Scheduler_run (name, t, loc) ->
      let inner = Solver.eval env t in
      let foreign =
        Effect_set.select
          (fun id ->
            match Schedulers.owner_of_effect (Effect_id.to_string id) with
            | Some o -> not (String.equal o name)
            | None -> false)
          inner
      in
      let acc =
        List.fold_left
          (fun a id ->
            let owner =
              Option.value ~default:"?"
                (Schedulers.owner_of_effect (Effect_id.to_string id))
            in
            { m_effect = id; m_owner = owner; m_running_under = name; m_loc = loc } :: a)
          acc foreign
      in
      collect env acc t
  | Eff_expr.Join l -> List.fold_left (collect env) acc l
  | Eff_expr.Handle (t, _) -> collect env acc t
  | _ -> acc

let check env (roots : Eff_expr.t list) =
  List.fold_left (collect env) [] roots |> List.rev
