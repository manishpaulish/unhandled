(* Kleene fixpoint over function summaries, plus blame-path reconstruction. *)

module SMap = Map.Make (String)
module SSet = Set.Make (String)

type env = Effect_set.t SMap.t

let lookup (env : env) name =
  match SMap.find_opt name env with
  | Some s -> s
  (* No summary: an external function we cannot see. Unknown, not empty. *)
  | None -> Effect_set.top

let rec eval env (e : Eff_expr.t) : Effect_set.t =
  match e with
  | Eff_expr.Const s -> s
  | Eff_expr.Perform (id, _) -> Effect_set.singleton id
  | Eff_expr.Unknown _ -> Effect_set.top
  | Eff_expr.Call (name, _) -> lookup env name
  | Eff_expr.Join l -> List.fold_left (fun a x -> Effect_set.join a (eval env x)) Effect_set.empty l
  | Eff_expr.Handle (t, h) -> Effect_syntax.subtract_handled (eval env t) h
  | Eff_expr.Boundary _ -> Effect_set.empty
  | Eff_expr.Scheduler_run (name, t, _) ->
      let prefixes = Schedulers.prefixes_of name in
      Effect_set.remove_where
        (fun e -> List.exists (Schedulers.has_prefix (Effect_id.to_string e)) prefixes)
        (eval env t)

(* Least fixed point. The lattice is finite (the effects mentioned in the
   program, plus Top) and [eval] is monotone, so iteration terminates; the
   bound is a safety net for malformed input. *)
let solve (nodes : Builder.node list) : env =
  let init = List.fold_left (fun m (n : Builder.node) ->
      SMap.add n.Builder.name Effect_set.empty m) SMap.empty nodes in
  let rec iterate env n =
    if n > 1000 then env
    else
      let env', changed =
        List.fold_left
          (fun (acc, ch) (nd : Builder.node) ->
            let v = eval acc nd.Builder.body in
            let old = lookup acc nd.Builder.name in
            if Effect_set.equal v old then (acc, ch)
            else (SMap.add nd.Builder.name v acc, true))
          (env, false) nodes
      in
      if changed then iterate env' (n + 1) else env'
  in
  iterate init 0

(* ------------------------------------------------------------------- blame *)

type step = { st_what : string; st_loc : Location.t; st_callee : string option }

let node_table nodes =
  List.fold_left
    (fun m (n : Builder.node) -> SMap.add n.Builder.name n m)
    SMap.empty nodes

let covers (h : Effect_syntax.handled) eff =
  match h with
  | Effect_syntax.All -> true
  | Effect_syntax.Only s -> Effect_id.Set.mem eff s

(* Find one concrete path from an effect expression down to a [perform] of
   [eff] that no enclosing handler discharges. Used to explain a finding. *)
let blame_path env nodes eff root =
  let tbl = node_table nodes in
  let rec go visiting e =
    match e with
    | Eff_expr.Perform (id, loc) when Effect_id.equal id eff ->
        Some [ { st_what = "performs " ^ Effect_id.short eff; st_loc = loc; st_callee = None } ]
    | Eff_expr.Perform _ | Eff_expr.Const _ | Eff_expr.Unknown _ -> None
    | Eff_expr.Call (name, loc) ->
        if SSet.mem name visiting then None
        else if not (Effect_set.mem eff (lookup env name)) then None
        else (
          match SMap.find_opt name tbl with
          | None -> Some [ { st_what = "calls " ^ name ^ " (no source available)"; st_loc = loc; st_callee = None } ]
          | Some nd ->
              (match go (SSet.add name visiting) nd.Builder.body with
               | Some rest -> Some ({ st_what = "calls " ^ name; st_loc = loc; st_callee = Some name } :: rest)
               | None -> None))
    | Eff_expr.Join l ->
        List.fold_left (fun acc x -> match acc with Some _ -> acc | None -> go visiting x) None l
    | Eff_expr.Handle (t, h) -> if covers h eff then None else go visiting t
    | Eff_expr.Boundary _ -> None
    | Eff_expr.Scheduler_run (name, t, _) ->
        let prefixes = Schedulers.prefixes_of name in
        if List.exists (Schedulers.has_prefix (Effect_id.to_string eff)) prefixes
        then None else go visiting t
  in
  go SSet.empty root


(* Which calls made us blind?

   A module reported as "unknown effects may escape" is useless on its own: it
   says we failed without saying where. Naming the unresolved callees turns the
   warning into a work list, since the frequent ones are exactly the functions
   worth adding to the models. *)
let unknown_sources env nodes root =
  let tbl = node_table nodes in
  let acc = ref [] in
  let rec go visiting e =
    match e with
    | Eff_expr.Unknown loc -> acc := ("<unresolved value>", loc) :: !acc
    | Eff_expr.Call (name, loc) ->
        if SSet.mem name visiting then ()
        else (
          match SMap.find_opt name tbl with
          | None ->
              (* No summary at all: external code with no .cmt. *)
              if Effect_set.has_unknown (lookup env name) then
                acc := (name, loc) :: !acc
          | Some nd ->
              if Effect_set.has_unknown (lookup env name) then
                go (SSet.add name visiting) nd.Builder.body)
    | Eff_expr.Join l -> List.iter (go visiting) l
    | Eff_expr.Handle (t, _) -> go visiting t
    | Eff_expr.Scheduler_run (_, t, _) -> go visiting t
    | Eff_expr.Boundary _ -> ()
    | Eff_expr.Const _ | Eff_expr.Perform _ -> ()
  in
  go SSet.empty root;
  (* Most frequent first, deduplicated by callee. *)
  let counts = Hashtbl.create 16 in
  List.iter
    (fun (n, loc) ->
      match Hashtbl.find_opt counts n with
      | Some (c, l) -> Hashtbl.replace counts n (c + 1, l)
      | None -> Hashtbl.replace counts n (1, loc))
    !acc;
  Hashtbl.fold (fun n (c, loc) a -> (n, c, loc) :: a) counts []
  |> List.sort (fun (_, a, _) (_, b, _) -> compare b a)
