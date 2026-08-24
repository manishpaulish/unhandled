let usage () =
  prerr_endline
    "unhandled - static effect-safety checker for OCaml 5\n\n\
     usage:\n\
    \  unhandled check <dir>      analyse .cmt files under <dir>\n\
    \  unhandled facts <dir>      dump raw perform/handler facts\n\
    \  unhandled summaries <dir>  print per-function effect summaries\n\
    \  unhandled witness <dir>    generate, compile and RUN a witness per finding\n";
  exit 2

let () =
  if Array.length Sys.argv < 3 then usage ();
  let cmd = Sys.argv.(1) and dir = Sys.argv.(2) in
  let files = Driver.find_cmts dir [] in
  if files = [] then (Printf.eprintf "no .cmt files under %s\n" dir; exit 2);
  match cmd with
  | "check" ->
      let _, _, findings = Driver.analyse files in
      print_string (Report.render_all findings);
      exit (if List.exists (fun f -> match f.Report.f_kind with Report.Escapes _ -> true | _ -> false) findings then 1 else 0)
  | "summaries" ->
      let units, env, _ = Driver.analyse files in
      List.iter
        (fun (u : Driver.unit_facts) ->
          let mf = u.Driver.uf_facts in
          Printf.printf "module %s\n" mf.Builder.mf_modname;
          List.iter
            (fun (n : Builder.node) ->
              Printf.printf "  %-32s %s\n" n.Builder.name
                (Effect_set.to_string (Solver.lookup env n.Builder.name)))
            (List.rev mf.Builder.mf_nodes);
          Printf.printf "  %-32s %s\n" "<module init>"
            (Effect_set.to_string (Solver.eval env mf.Builder.mf_init)))
        units
  | "witness" ->
      let units, env, findings = Driver.analyse files in
      let nodes = List.concat_map (fun (u : Driver.unit_facts) -> u.Driver.uf_facts.Builder.mf_nodes) units in
      let arities = List.concat_map (fun (u : Driver.unit_facts) -> u.Driver.uf_facts.Builder.mf_arities) units in
      let ocamlc = try Sys.getenv "UNHANDLED_OCAMLC" with Not_found -> "ocamlc" in
      let runner = try Sys.getenv "UNHANDLED_RUNNER" with Not_found -> "" in
      let work = "_unhandled" in
      ignore (Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote work)));
      (* Link the target's module plus any module whose initialisation is
         effect-free. Pulling in a main whose init already leaks would crash
         before the witness could report anything. *)
      let module_of name =
        match String.rindex_opt name '.' with
        | Some i -> String.sub name 0 i
        | None -> name
      in
      let clean_sources target =
        let tmod = module_of target in
        let pick want =
          List.filter_map
            (fun (u : Driver.unit_facts) ->
              let mf = u.Driver.uf_facts in
              let is_target = String.equal mf.Builder.mf_modname tmod in
              let clean = Effect_set.is_empty (Solver.eval env mf.Builder.mf_init) in
              if (want && is_target) || ((not want) && (not is_target) && clean)
              then u.Driver.uf_source else None)
            units
        in
        let srcs = pick false @ pick true in
        if srcs = [] then List.filter_map (fun (u : Driver.unit_facts) -> u.Driver.uf_source) units
        else srcs
      in
      let n = ref 0 and confirmed = ref 0 and total = ref 0 in
      List.iter
        (fun (f : Report.finding) ->
          incr n;
          let id = Printf.sprintf "w%02d" !n in
          let label =
            match f.Report.f_kind with
            | Report.Escapes e -> Effect_id.to_string e
            | Report.Unknown_effects -> "<unknown>"
          in
          match Witness.generate ~nodes ~arities f with
          | Error why -> Printf.printf "%-4s  %-26s  %-24s %s\n" id label "-" ("not constructible: " ^ why)
          | Ok (target, src) ->
              incr total;
              let dir = Filename.concat work id in
              ignore (Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote dir)));
              let outcome =
                Witness.verify ~ocamlc ~runner ~dir ~sources:(clean_sources target) ~witness_src:src
              in
              (match outcome with
               | Witness.Confirmed | Witness.Confirmed_by_crash -> incr confirmed
               | _ -> ());
              Printf.printf "%-4s  %-26s  %-24s %s\n" id label target
                (Witness.string_of_outcome outcome))
        findings;
      Printf.printf "\n%d/%d findings confirmed by execution\n" !confirmed !total
  | "facts" ->
      List.iter (fun f -> Printf.printf "cmt %s\n" f) files
  | _ -> usage ()
