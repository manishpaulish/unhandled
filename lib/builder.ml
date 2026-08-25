(* Build symbolic effect expressions and function summaries from a typedtree. *)

open Typedtree

type node = {
  name : string;
  loc : Location.t;
  body : Eff_expr.t;
  (* Witness arguments, resolved to concrete syntax while the typed tree is in
     hand. Storing a Types.type_expr here would make summaries uncacheable:
     it is a cyclic compiler structure and cannot be marshalled. *)
  nargs : string list option;
}

type module_facts = {
  mf_modname : string;
  mf_nodes : node list;
  mf_init : Eff_expr.t;  (* effects performed when the module is initialised *)
  mf_arities : (Effect_id.t * int) list;  (* effect constructor arities *)
}

type ctx = {
  modname : string;
  unit_name : string;  (* the compilation unit, for per-file alias lookup *)
  toplevel : (string, string) Hashtbl.t;  (* Ident.unique_name -> M.name *)
  mutable nodes : node list;
  mutable arities : (Effect_id.t * int) list;
}

(* `module D = Foo` makes `D.record` appear as the path "D.record", which
   matches no summary, so the call resolves to nothing and the caller degrades
   to unknown. The second sweep showed this clearly: D.record_threshold, A.v,
   Detail.view_for and friends were all aliases into modules we had analysed.

   Aliases are recorded per compilation unit, because two files may each bind
   a different module to the name `D`. *)
let module_aliases : (string, string) Hashtbl.t = Hashtbl.create 64

let register_module_alias ~unit_name ~alias ~target =
  Hashtbl.replace module_aliases (unit_name ^ "|" ^ alias) target

(* Used by the cache to replay an entry's aliases, which are already keyed. *)
let register_module_alias_raw key target = Hashtbl.replace module_aliases key target

let resolve_alias ~unit_name name =
  match String.index_opt name '.' with
  | None -> name
  | Some i ->
      let head = String.sub name 0 i in
      let rest = String.sub name i (String.length name - i) in
      (match Hashtbl.find_opt module_aliases (unit_name ^ "|" ^ head) with
       | Some target -> target ^ rest
       | None -> name)

let rec collect_module_aliases_into acc ~unit_name ~modname (str : structure) =
  List.iter
    (fun item ->
      match item.str_desc with
      | Tstr_module { mb_id = Some id; mb_expr = { mod_desc = Tmod_ident (p, _); _ }; _ } ->
          let alias = Ident.name id and target = Path.name p in
          register_module_alias ~unit_name ~alias ~target;
          acc := (unit_name ^ "|" ^ alias, target) :: !acc
      | Tstr_module { mb_id = Some id; mb_expr = { mod_desc = Tmod_structure sub; _ }; _ } ->
          collect_module_aliases_into acc ~unit_name
            ~modname:(modname ^ "." ^ Ident.name id) sub
      | _ -> ())
    str.str_items

let qualify ctx (p : Path.t) =
  match p with
  | Path.Pident id ->
      let u = Ident.unique_name id in
      (match Hashtbl.find_opt ctx.toplevel u with
       | Some q -> q
       | None -> ctx.modname ^ "." ^ u)
  | _ -> resolve_alias ~unit_name:ctx.unit_name (Path.name p)

(* Immediate sub-expressions. [default_iterator.expr] walks one level using the
   iterator we hand it; our override collects without recursing, so we get the
   children of [e] and nothing deeper. This keeps handler scoping exact without
   enumerating every expression constructor. *)
let children (e : expression) =
  let acc = ref [] in
  let it = { Tast_iterator.default_iterator with
             expr = (fun _ child -> acc := child :: !acc) } in
  Tast_iterator.default_iterator.expr it e;
  List.rev !acc

let rec of_expr ctx (e : expression) : Eff_expr.t =
  match e.exp_desc with
  (* A function literal performs nothing where it is written; its effects
     belong to whoever calls it. *)
  | Texp_function _ -> Eff_expr.empty
  | Texp_ident _ | Texp_constant _ -> Eff_expr.empty
  | Texp_apply (f, args) -> of_apply ctx e f args
  | Texp_match (scrut, comp_cases, eff_cases, _) ->
      let handled = Effect_syntax.handled_of_effect_cases ~modname:ctx.modname eff_cases in
      Eff_expr.Join
        (Eff_expr.Handle (of_expr ctx scrut, handled)
         :: (List.map (fun c -> of_expr ctx c.c_rhs) comp_cases
             @ List.map (fun c -> of_expr ctx c.c_rhs) eff_cases))
  | Texp_try (body, exn_cases, eff_cases) ->
      let handled =
        (* An explicit `with Effect.Unhandled _` guard discharges everything
           the body performs: the author has dealt with the consequence. *)
        if Effect_syntax.guards_unhandled exn_cases then Effect_syntax.All
        else Effect_syntax.handled_of_effect_cases ~modname:ctx.modname eff_cases
      in
      Eff_expr.Join
        (Eff_expr.Handle (of_expr ctx body, handled)
         :: (List.map (fun c -> of_expr ctx c.c_rhs) exn_cases
             @ List.map (fun c -> of_expr ctx c.c_rhs) eff_cases))
  | Texp_let (_, vbs, body) ->
      let bound = List.map (fun vb -> bind_value ctx vb) vbs in
      Eff_expr.Join (of_expr ctx body :: bound)
  | _ -> Eff_expr.Join (List.map (of_expr ctx) (children e))

(* Effects of *calling* an expression of function type. *)
and effects_of_calling ctx (e : expression) : Eff_expr.t =
  match e.exp_desc with
  (* A function passed to a combinator gets the same treatment as one called
     directly. Without this, [List.filter Sys.file_exists paths] produced an
     unresolved call to a function the models already know is pure, which the
     first sweep duly reported as a cause of blindness. *)
  | Texp_ident (p, _, _) when Stdlib_models.is_known_pure (Path.name p) ->
      Eff_expr.empty
  | Texp_ident (p, _, _) -> Eff_expr.Call (qualify ctx p, e.exp_loc)
  | Texp_function (_, Tfunction_body b) -> of_expr ctx b
  | Texp_function (_, Tfunction_cases { cases; _ }) ->
      Eff_expr.Join (List.map (fun c -> of_expr ctx c.c_rhs) cases)
  | _ -> Eff_expr.Unknown e.exp_loc

and of_apply ctx e f args =
  (* Omitted arguments (partial application of a labelled function) carry no
     expression and are dropped. 5.4 spells that [Omitted ()] where 5.3 spells
     it [None], so the unwrapping lives in [Compat]. Note that dropping them
     shifts the positional indices used below, on both compilers alike. *)
  let arg_exprs = List.filter_map (fun (_, o) -> Compat.apply_arg o) args in
  let arg_effects = List.map (of_expr ctx) arg_exprs in
  match f.exp_desc with
  | Texp_ident (p, _, _) when Effect_syntax.is_perform p -> (
      match arg_exprs with
      | [ a ] -> (
          match Effect_syntax.effect_of_expr ~modname:ctx.modname a with
          | Some (id, arity) ->
              ctx.arities <- (id, arity) :: ctx.arities;
              Eff_expr.Join (Eff_expr.Perform (id, e.exp_loc) :: arg_effects)
          (* perform applied to a non-literal effect: identity unknown. *)
          | None -> Eff_expr.Unknown e.exp_loc)
      | _ -> Eff_expr.Unknown e.exp_loc)
  | Texp_ident (p, _, _) when Boundaries.find (Path.name p) <> None ->
      let r = Option.get (Boundaries.find (Path.name p)) in
      let cb =
        match List.nth_opt arg_exprs r.Boundaries.callback_arg with
        (* Sys.signal takes Signal_handle f, not f: unwrap the constructor so
           the handler itself is what gets analysed. *)
        | Some { exp_desc = Texp_construct (_, cd, [ inner ]); _ }
          when String.equal (Compat.cstr_name cd) "Signal_handle" -> Some inner
        | other -> other
      in
      let inner_eff =
        match cb with
        | Some c -> effects_of_calling ctx c
        | None -> Eff_expr.Const Effect_set.empty
      in
      let others =
        List.filteri (fun i _ -> i <> r.Boundaries.callback_arg) arg_exprs
        |> List.map (of_expr ctx)
      in
      Eff_expr.Join
        (Eff_expr.Boundary (r.Boundaries.why, inner_eff, e.exp_loc) :: others)
  | Texp_ident (p, _, _) when Schedulers.scheduler_of_run (Path.name p) <> None ->
      let sch = Option.get (Schedulers.scheduler_of_run (Path.name p)) in
      let comp_eff =
        match List.nth_opt arg_exprs 0 with
        | Some c -> effects_of_calling ctx c
        | None -> Eff_expr.Unknown e.exp_loc
      in
      let others = List.filteri (fun i _ -> i <> 0) arg_exprs |> List.map (of_expr ctx) in
      Eff_expr.Join (Eff_expr.Scheduler_run (sch, comp_eff, e.exp_loc) :: others)
  | Texp_ident (p, _, _) when Effect_syntax.handler_arg_index p <> None ->
      let idx = Option.get (Effect_syntax.handler_arg_index p) in
      let comp = List.nth_opt arg_exprs 0 in
      let handler = List.nth_opt arg_exprs idx in
      let handled =
        match handler with
        | Some h -> Effect_syntax.handled_of_handler_record ~modname:ctx.modname h
        | None -> Effect_syntax.handled_empty
      in
      let comp_eff =
        match comp with
        | Some c -> effects_of_calling ctx c
        | None -> Eff_expr.Unknown e.exp_loc
      in
      (* Arguments other than the computation are evaluated normally; their
         effects are NOT discharged by this handler. *)
      let others =
        List.filteri (fun i _ -> i <> 0) arg_exprs |> List.map (of_expr ctx)
      in
      Eff_expr.Join (Eff_expr.Handle (comp_eff, handled) :: others)
  (* Calling a scheduler's API requires its runtime, whether or not we have
     source for it. *)
  | Texp_ident (p, _, _)
    when Schedulers.api_requirement ~modname:ctx.modname (Path.name p) <> None ->
      let _, eff =
        Option.get (Schedulers.api_requirement ~modname:ctx.modname (Path.name p))
      in
      Eff_expr.Join
        (Eff_expr.Perform (Effect_id.of_string eff, e.exp_loc) :: arg_effects)
  | Texp_ident (p, _, _) -> (
      let name = Path.name p in
      match Stdlib_models.is_combinator name with
      | Some idxs ->
          (* Effect-polymorphic: the combinator performs what its function
             arguments perform. *)
          let applied =
            List.filteri (fun i _ -> List.mem i idxs) arg_exprs
            |> List.map (effects_of_calling ctx)
          in
          Eff_expr.Join (applied @ arg_effects)
      | None ->
          if Stdlib_models.is_known_pure name then Eff_expr.Join arg_effects
          else Eff_expr.Join (Eff_expr.Call (qualify ctx p, e.exp_loc) :: arg_effects))
  | _ -> Eff_expr.Join (of_expr ctx f :: arg_effects)

(* A value binding either defines a function (deferred effects, becomes a node)
   or runs now (its effects join the enclosing context). *)
and bind_value ctx (vb : value_binding) : Eff_expr.t =
  let name_of_pat (p : value general_pattern) =
    match p.pat_desc with Tpat_var (id, _, _) -> Some id | _ -> None
  in
  match (name_of_pat vb.vb_pat, vb.vb_expr.exp_desc) with
  | Some id, Texp_function _ ->
      let u = Ident.unique_name id in
      let qname =
        match Hashtbl.find_opt ctx.toplevel u with
        | Some q -> q
        | None -> ctx.modname ^ "." ^ u
      in
      let body = effects_of_calling ctx vb.vb_expr in
      ctx.nodes <-
        { name = qname; loc = vb.vb_loc; body;
          nargs = Synth.args_for vb.vb_expr.exp_type }
        :: ctx.nodes;
      Eff_expr.empty
  | _ -> of_expr ctx vb.vb_expr

(* Pre-pass: record every extension-constructor rebinding so effect identity
   can be canonicalised before any analysis runs. Deliberately separate from
   the main build, because the map must be complete for the very first
   [Effect_id.of_path] call. *)
let collect_module_aliases ~unit_name ~modname str =
  let acc = ref [] in
  collect_module_aliases_into acc ~unit_name ~modname str;
  !acc

let rec collect_aliases_into acc ~modname (str : structure) =
  List.iter
    (fun item ->
      match item.str_desc with
      | Tstr_typext te ->
          List.iter
            (fun (ext : extension_constructor) ->
              match ext.ext_kind with
              | Text_rebind (target, _) ->
                  let alias = modname ^ "." ^ Ident.name ext.ext_id in
                  let target = Path.name target in
                  Effect_id.register_alias ~alias ~target;
                  acc := (alias, target) :: !acc
              | Text_decl _ -> ())
            te.tyext_constructors
      | Tstr_module mb -> (
          match mb.mb_expr.mod_desc with
          | Tmod_structure sub ->
              let n =
                match mb.mb_id with
                | Some id -> modname ^ "." ^ Ident.name id
                | None -> modname
              in
              collect_aliases_into acc ~modname:n sub
          | _ -> ())
      | _ -> ())
    str.str_items

let rec of_structure ctx (str : structure) : Eff_expr.t =
  (* Register top-level names first so that mutually recursive references and
     cross-module references resolve to "M.name". *)
  List.iter
    (fun item ->
      match item.str_desc with
      | Tstr_value (_, vbs) ->
          List.iter
            (fun vb ->
              match vb.vb_pat.pat_desc with
              | Tpat_var (id, _, _) ->
                  Hashtbl.replace ctx.toplevel (Ident.unique_name id)
                    (ctx.modname ^ "." ^ Ident.name id)
              | _ -> ())
            vbs
      | _ -> ())
    str.str_items;
  let init =
    List.filter_map
      (fun item ->
        match item.str_desc with
        | Tstr_value (_, vbs) -> Some (Eff_expr.Join (List.map (bind_value ctx) vbs))
        | Tstr_eval (e, _) -> Some (of_expr ctx e)
        | Tstr_module mb -> Some (of_module ctx mb)
        | _ -> None)
      str.str_items
  in
  Eff_expr.Join init

and of_module ctx (mb : module_binding) =
  match mb.mb_expr.mod_desc with
  | Tmod_structure str ->
      let sub_name =
        match mb.mb_id with
        | Some id -> ctx.modname ^ "." ^ Ident.name id
        | None -> ctx.modname
      in
      let sub = { ctx with modname = sub_name } in
      let e = of_structure sub str in
      ctx.nodes <- sub.nodes @ ctx.nodes;
      ctx.arities <- sub.arities @ ctx.arities;
      e
  | _ -> Eff_expr.empty

let collect_aliases ~modname str =
  let acc = ref [] in
  collect_aliases_into acc ~modname str;
  !acc

let build ~modname (str : structure) : module_facts =
  ignore (collect_module_aliases ~unit_name:modname ~modname str);
  let ctx =
    { modname; unit_name = modname; toplevel = Hashtbl.create 64; nodes = [];
      arities = [] }
  in
  let init = of_structure ctx str in
  { mf_modname = modname; mf_nodes = ctx.nodes; mf_init = init;
    mf_arities = ctx.arities }
