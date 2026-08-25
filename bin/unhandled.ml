let usage () =
  prerr_endline
    "unhandled - static effect-safety checker for OCaml 5\n\n\
     usage:\n\
    \  unhandled check <dir>      analyse .cmt files under <dir>\n\
    \                             (--json for machine-readable output)\n\
    \  unhandled facts <dir>      dump raw perform/handler facts\n\
    \  unhandled summaries <dir>  print per-function effect summaries\n\
    \  unhandled witness <dir>    generate, compile and RUN a witness per finding\n\
    \  unhandled contract <dir>   library mode: the effect contract of each function\n\
    \  unhandled models           print the scheduler model table in force\n\
    \n\
    \  --no-cache                 ignore and do not write the summary cache\n\
    \  --models <file>            replace the built-in scheduler table\n";
  exit 2

(* The scheduler table is data, not analysis: it says which entry point installs
   handlers for which effects. Shipping it as a file the tool never reads would
   make models/schedulers.conf decorative, so it is loadable here, and
   [unhandled models] prints whichever table is actually in force. *)
let load_models () =
  let rec find i =
    if i + 1 >= Array.length Sys.argv then ()
    else if Sys.argv.(i) = "--models" then Schedulers.load_file Sys.argv.(i + 1)
    else find (i + 1)
  in
  find 1;
  match Sys.getenv_opt "UNHANDLED_MODELS" with
  | Some p when Array.for_all (fun a -> a <> "--models") Sys.argv ->
      Schedulers.load_file p
  | _ -> ()

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "models" then (
    load_models ();
    print_string (Schedulers.describe ());
    exit 0);
  if Array.length Sys.argv < 3 then usage ();
  let cmd = Sys.argv.(1) and dir = Sys.argv.(2) in
  load_models ();
  (* --no-cache exists so the cache can be measured against, and so a
     suspected cache bug can be ruled in or out in one run. *)
  if Array.exists (fun a -> a = "--no-cache") Sys.argv then
    Cache.set_enabled false;
  Cache.set_dir (Filename.concat dir ".unhandled-cache");
  let files = Driver.find_cmts dir [] in
  if files = [] then (Printf.eprintf "no .cmt files under %s\n" dir; exit 2);
  match cmd with
  | "check" ->
      let _, _, findings = Driver.analyse files in
      let json = Array.exists (fun a -> a = "--json") Sys.argv in
      print_string
        (if json then Report.render_json findings else Report.render_all findings);
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
            | Report.Scheduler_mismatch (e, _, _) -> Effect_id.to_string e
            | Report.Boundary_crossing (e, _) -> Effect_id.to_string e
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
  | "contract" ->
      (* Library mode. A library that performs effects is not buggy: its
         handler lives in the application. What matters is that its contract
         is visible, so callers know what they must handle.

         Functions whose set is Top are listed separately. Mixing them in
         would fill the contract with "<unknown>" lines that say nothing; the
         count still gets reported, because a contract derived mostly from
         unanalysed calls is worth far less and the reader should know. *)
      let units, env, _ = Driver.analyse files in
      let unknown = ref 0 in
      List.iter
        (fun (u : Driver.unit_facts) ->
          let mf = u.Driver.uf_facts in
          let rows =
            List.rev mf.Builder.mf_nodes
            |> List.filter_map (fun (n : Builder.node) ->
                   let set = Solver.lookup env n.Builder.name in
                   if Effect_set.known_elements set <> [] then
                     Some (n.Builder.name, set)
                   else if Effect_set.has_unknown set then (incr unknown; None)
                   else None)
          in
          (* One line per function. A contract is a statement about a name, so
             printing that name three times because it has three binding sites
             in the tree is noise, and it is the first thing a reader stops
             trusting. Same name and same set collapses to one row; the same
             name with a *different* set is kept, because that is a real
             disagreement worth seeing rather than hiding. *)
          let rows =
            let seen = Hashtbl.create 64 in
            List.filter
              (fun (name, s) ->
                let key = name ^ " => " ^ Effect_set.to_string s in
                if Hashtbl.mem seen key then false
                else (Hashtbl.add seen key (); true))
              rows
          in
          if rows <> [] then (
            Printf.printf "module %s\n" mf.Builder.mf_modname;
            List.iter
              (fun (name, s) ->
                Printf.printf "  %-34s may perform %s\n" name (Effect_set.to_string s))
              rows;
            print_newline ()))
        units;
      if !unknown > 0 then
        Printf.printf
          "%d function(s) omitted: their effects depend on calls into code with no .cmt available.\n"
          !unknown
  | "facts" ->
      List.iter (fun f -> Printf.printf "cmt %s\n" f) files
  | _ -> usage ()
