(* Scheduler model table.

   Handlers for Eio/Riot/Moonpool effects live inside compiled dependencies we
   often have no .cmt for, so they cannot be discovered by analysis. They are
   supplied as data instead: which entry point installs handlers for which
   family of effects. This is also what makes cross-scheduler leakage
   detectable, since we then know which scheduler each effect belongs to. *)

type t = {
  name : string;
  runs : string list;
  prefixes : string list;
  (* Calling into this scheduler's API requires its runtime. We almost never
     have .cmt files for an installed dependency, so without this a call to
     Eio.Mutex.use_rw is merely "unresolved": it carries no named effect, and
     both the escape check and the boundary check have nothing to report. The
     retroactive batch caught 0 of 6 for exactly this reason. *)
  apis : string list;
  requires : string;  (* representative effect such a call performs *)
}

let builtin =
  [ (* Confirmed against ocaml-multicore/eio @ d3c8dd9. Prefixes use the
       mangled library names from the dune stanzas (eio__core, eio_unix). *)
    { name = "eio";
      runs = [ "Eio_main.run"; "Eio_linux.run"; "Eio_linux.run_event_loop";
               "Eio_posix.run" ];
      prefixes = [ "Eio__core"; "Eio_unix"; "Eio" ];
      apis = [ "Eio."; "Eio_unix."; "Eio__core." ];
      requires = "Eio__core.Suspend.Suspend" };
    { name = "riot"; runs = [ "Riot.run" ]; prefixes = [ "Riot" ];
      apis = [ "Riot." ]; requires = "Riot.Effects.Receive" };
    { name = "moonpool"; runs = [ "Moonpool.run" ]; prefixes = [ "Moonpool" ];
      apis = []; requires = "Moonpool.Effects.Suspend" };
    { name = "miou"; runs = [ "Miou.run"; "Miou_unix.run" ]; prefixes = [ "Miou" ];
      apis = []; requires = "Miou.Effects.Suspend" };
    { name = "mock_a"; runs = [ "Sched_a.run" ]; prefixes = [ "Sched_a" ];
      apis = []; requires = "Sched_a.Yield" };
    { name = "mock_b"; runs = [ "Sched_b.run" ]; prefixes = [ "Sched_b" ];
      apis = []; requires = "Sched_b.Tick" } ]

let table = ref builtin

(* Optional override file, same data in a line-oriented format so it stays
   reviewable in a pull request. *)
let load_file path =
  if Sys.file_exists path then (
    let ic = open_in path in
    let acc = ref [] and cur = ref None in
    let flush () = match !cur with Some s -> acc := s :: !acc | None -> () in
    (try
       while true do
         let line = String.trim (input_line ic) in
         if line = "" || line.[0] = '#' then ()
         else
           match String.index_opt line ' ' with
           | None -> ()
           | Some i ->
               let key = String.sub line 0 i in
               let v = String.trim (String.sub line i (String.length line - i)) in
               (match key with
                | "scheduler" -> flush (); cur := Some { name = v; runs = []; prefixes = []; apis = []; requires = "" }
                | "run" -> (match !cur with Some s -> cur := Some { s with runs = v :: s.runs } | None -> ())
                | "prefix" -> (match !cur with Some s -> cur := Some { s with prefixes = v :: s.prefixes } | None -> ())
                | "api" -> (match !cur with Some s -> cur := Some { s with apis = v :: s.apis } | None -> ())
                | "requires" -> (match !cur with Some s -> cur := Some { s with requires = v } | None -> ())
                | _ -> ())
       done
     with End_of_file -> ());
    flush ();
    close_in ic;
    if !acc <> [] then table := !acc)

(* Which scheduler does this call start, if any? *)
let scheduler_of_run path =
  List.find_map (fun s -> if List.mem path s.runs then Some s.name else None) !table

let prefixes_of name =
  match List.find_opt (fun s -> s.name = name) !table with
  | Some s -> s.prefixes
  | None -> []

(* OCaml mangles nested library modules with double underscores, so the same
   effect can appear as Eio__core.Cancel.Get_context or as
   Eio__core__Cancel.Get_context depending on how it is referenced. A real
   crash report from the wild reads:

     Fatal error: exception Stdlib.Effect.Unhandled(Eio__core__Cancel.Get_context)

   Requiring a '.' separator would miss exactly that. Accept either. *)
let starts_with pre s =
  String.length s >= String.length pre && String.sub s 0 (String.length pre) = pre

let has_prefix id p =
  let n = String.length p in
  String.length id > n && String.sub id 0 n = p
  && (id.[n] = '.' || id.[n] = '_')

(* Does calling this path require a scheduler runtime? Returns the effect such
   a call performs, so an unresolved dependency still contributes a *named*
   effect rather than an anonymous unknown. *)
let api_requirement path =
  List.find_map
    (fun s ->
      if s.requires <> "" && List.exists (fun a -> starts_with a path) s.apis
         && not (List.mem path s.runs)
      then Some (s.name, s.requires)
      else None)
    !table

(* Which scheduler owns this effect, if any? Used to tell "you forgot a
   handler" apart from "you are running this under the wrong runtime". *)
let owner_of_effect id =
  List.find_map
    (fun s -> if List.exists (has_prefix id) s.prefixes then Some s.name else None)
    !table
