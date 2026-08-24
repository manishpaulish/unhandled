let usage () =
  prerr_endline
    "unhandled - static effect-safety checker for OCaml 5\n\n\
     usage:\n\
    \  unhandled check <dir>      analyse .cmt files under <dir>\n\
    \  unhandled facts <dir>      dump raw perform/handler facts\n\
    \  unhandled summaries <dir>  print per-function effect summaries\n";
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
  | "facts" ->
      List.iter (fun f -> Printf.printf "cmt %s\n" f) files
  | _ -> usage ()
