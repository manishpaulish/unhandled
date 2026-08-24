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

let analyse files =
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
  (units, env, findings)
