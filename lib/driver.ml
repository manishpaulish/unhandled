(* Load .cmt files, analyse, produce findings. *)

let rec find_cmts dir acc =
  match Sys.readdir dir with
  | entries ->
      Array.fold_left
        (fun acc e ->
          let p = Filename.concat dir e in
          if Sys.is_directory p then find_cmts p acc
          else if Filename.check_suffix p ".cmt" then p :: acc
          else acc)
        acc entries
  | exception Sys_error _ -> acc

type unit_facts = {
  uf_file : string;
  uf_source : string option;
  uf_facts : Builder.module_facts;
}

(* cmt_sourcefile is usually relative to the build directory; try the obvious
   places and give up honestly rather than guessing. *)
let resolve_source cmtfile (cmt : Cmt_format.cmt_infos) =
  match cmt.Cmt_format.cmt_sourcefile with
  | None -> None
  | Some s ->
      let candidates =
        [ s;
          Filename.concat (Filename.dirname cmtfile) (Filename.basename s);
          Filename.concat cmt.Cmt_format.cmt_builddir s ]
      in
      List.find_opt Sys.file_exists candidates

let load file =
  match Cmt_format.read_cmt file with
  | cmt -> (
      match cmt.Cmt_format.cmt_annots with
      | Cmt_format.Implementation str ->
          Some { uf_file = file;
                 uf_source = resolve_source file cmt;
                 uf_facts = Builder.build ~modname:cmt.Cmt_format.cmt_modname str }
      | _ -> None)
  | exception _ -> None

(* Two phases: collect rebinding aliases from every unit, then build. Effect
   identity must already be canonical when the first summary is constructed. *)
let collect_aliases files =
  List.iter
    (fun file ->
      match Cmt_format.read_cmt file with
      | cmt -> (
          match cmt.Cmt_format.cmt_annots with
          | Cmt_format.Implementation str ->
              Builder.collect_aliases ~modname:cmt.Cmt_format.cmt_modname str
          | _ -> ())
      | exception _ -> ())
    files

let analyse files =
  collect_aliases files;
  let units = List.filter_map load files in
  let nodes = List.concat_map (fun u -> u.uf_facts.Builder.mf_nodes) units in
  let env = Solver.solve nodes in
  let findings =
    List.concat_map
      (fun u ->
        let mf = u.uf_facts in
        let escaping = Solver.eval env mf.Builder.mf_init in
        let entry = mf.Builder.mf_modname ^ " (module initialisation)" in
        let loc =
          Location.in_file
            (Filename.remove_extension (Filename.basename u.uf_file) ^ ".ml")
        in
        match escaping with
        | Effect_set.Top ->
            [ { Report.f_kind = Report.Unknown_effects; f_entry = entry; f_loc = loc; f_path = [] } ]
        | Effect_set.Known s ->
            Effect_id.Set.elements s
            |> List.map (fun e ->
                   let path =
                     match Solver.blame_path env nodes e mf.Builder.mf_init with
                     | Some p -> p
                     | None -> []
                   in
                   let loc = match path with
                     | { Solver.st_loc; _ } :: _ -> st_loc
                     | [] -> loc
                   in
                   { Report.f_kind = Report.Escapes e; f_entry = entry; f_loc = loc; f_path = path }))
      units
  in
  (* B2: scheduler mismatches, found anywhere in the program rather than only
     at entry points, since the wrong runtime is a local mistake. *)
  let roots =
    List.map (fun u -> u.uf_facts.Builder.mf_init) units
    @ List.concat_map
        (fun u -> List.map (fun (n : Builder.node) -> n.Builder.body) u.uf_facts.Builder.mf_nodes)
        units
  in
  let b2 =
    Scheduler_check.check env roots
    |> List.map (fun (m : Scheduler_check.mismatch) ->
           { Report.f_kind =
               Report.Scheduler_mismatch (m.Scheduler_check.m_effect,
                                          m.Scheduler_check.m_owner,
                                          m.Scheduler_check.m_running_under);
             f_entry =
               Printf.sprintf "%s runtime" m.Scheduler_check.m_running_under;
             f_loc = m.Scheduler_check.m_loc;
             f_path = [] })
  in
  (* An effect flagged as a scheduler mismatch also escapes, but "you used the
     wrong runtime" is the useful diagnosis; reporting both just doubles the
     noise for one mistake. *)
  let mismatched =
    List.filter_map
      (fun (f : Report.finding) ->
        match f.Report.f_kind with
        | Report.Scheduler_mismatch (e, _, _) -> Some e
        | _ -> None)
      b2
  in
  let findings =
    List.filter
      (fun (f : Report.finding) ->
        match f.Report.f_kind with
        | Report.Escapes e -> not (List.exists (Effect_id.equal e) mismatched)
        | _ -> true)
      findings
  in
  let b3 =
    Boundary_check.check env roots
    |> List.map (fun (c : Boundary_check.crossing) ->
           { Report.f_kind =
               Report.Boundary_crossing (c.Boundary_check.b_effect,
                                         c.Boundary_check.b_why);
             f_entry = c.Boundary_check.b_why;
             f_loc = c.Boundary_check.b_loc;
             f_path = [] })
  in
  (units, env, findings @ b2 @ b3)
