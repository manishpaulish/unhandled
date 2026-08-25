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
  (* Paths under [apis] that do NOT require the runtime: constructors, vtable
     builders and non-blocking accessors. Without these the api rule is too
     blunt, and the first three escapes this tool ever reported on third-party
     code were all of this kind -- library module initialisers calling
     Eio.Flow.Pi.source or Eio.Stream.create, neither of which can suspend.

     This list grows only when a false positive is observed AND the function's
     purity is confirmed in the scheduler's own source. Guessing here trades a
     false positive for a false negative, which is the worse of the two. *)
  pure : string list;
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
      (* Confirmed against ocaml-multicore/eio @ ab4dd74:
           lib_eio/flow.mli    Pi.source/sink/shutdown/two_way return a
                               Resource.handler built from a first-class
                               module. No I/O, nothing to suspend.
           lib_eio/resource.mli:59  handler : 't binding list -> handler
           lib_eio/stream.mli  create allocates a queue; only add and take
                               block. take_nonblocking, length and is_empty
                               are documented as not waiting. *)
      pure = [ "Eio.Flow.Pi."; "Eio.Resource.handler"; "Eio.Stream.create";
               "Eio.Stream.length"; "Eio.Stream.is_empty";
               "Eio.Stream.take_nonblocking" ];
      requires = "Eio__core.Suspend.Suspend" };
    { name = "riot"; runs = [ "Riot.run" ]; prefixes = [ "Riot" ];
      apis = [ "Riot." ]; pure = []; requires = "Riot.Effects.Receive" };
    { name = "moonpool"; runs = [ "Moonpool.run" ]; prefixes = [ "Moonpool" ];
      apis = []; pure = []; requires = "Moonpool.Effects.Suspend" };
    { name = "miou"; runs = [ "Miou.run"; "Miou_unix.run" ]; prefixes = [ "Miou" ];
      apis = []; pure = []; requires = "Miou.Effects.Suspend" };
    { name = "mock_a"; runs = [ "Sched_a.run" ]; prefixes = [ "Sched_a" ];
      apis = []; pure = []; requires = "Sched_a.Yield" };
    { name = "mock_b"; runs = [ "Sched_b.run" ]; prefixes = [ "Sched_b" ];
      apis = []; pure = []; requires = "Sched_b.Tick" } ]

let table = ref builtin
let all () = !table

(* Printed by [unhandled models]. The table is an assumption about the world,
   not something derived from the code under analysis, so it has to be
   inspectable: a reader who disagrees with a finding should be able to see
   the premise it rests on without reading our source. *)
let describe () =
  let b = Buffer.create 512 in
  List.iter
    (fun s ->
      Buffer.add_string b (Printf.sprintf "scheduler %s\n" s.name);
      List.iter (fun r -> Buffer.add_string b (Printf.sprintf "  run       %s\n" r)) s.runs;
      List.iter (fun p -> Buffer.add_string b (Printf.sprintf "  prefix    %s\n" p)) s.prefixes;
      List.iter (fun a -> Buffer.add_string b (Printf.sprintf "  api       %s\n" a)) s.apis;
      List.iter (fun p -> Buffer.add_string b (Printf.sprintf "  pure      %s\n" p)) s.pure;
      if s.requires <> "" then
        Buffer.add_string b (Printf.sprintf "  requires  %s\n" s.requires);
      Buffer.add_char b '\n')
    !table;
  Buffer.contents b

(* Optional override file, same data in a line-oriented format so it stays
   reviewable in a pull request. *)
let load_file path =
  if Sys.file_exists path then (
    let ic = open_in path in
    let acc = ref [] and cur = ref None in
    (* Entries are accumulated by prepending, so put every list back into file
       order on the way out. Otherwise a table loaded from disk and the same
       table compiled in would print differently and could not be compared. *)
    let flush () =
      match !cur with
      | Some s ->
          acc :=
            { s with runs = List.rev s.runs; prefixes = List.rev s.prefixes;
                     apis = List.rev s.apis; pure = List.rev s.pure }
            :: !acc
      | None -> ()
    in
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
                | "scheduler" -> flush (); cur := Some { name = v; runs = []; prefixes = []; apis = []; pure = []; requires = "" }
                | "run" -> (match !cur with Some s -> cur := Some { s with runs = v :: s.runs } | None -> ())
                | "prefix" -> (match !cur with Some s -> cur := Some { s with prefixes = v :: s.prefixes } | None -> ())
                | "api" -> (match !cur with Some s -> cur := Some { s with apis = v :: s.apis } | None -> ())
                | "pure" -> (match !cur with Some s -> cur := Some { s with pure = v :: s.pure } | None -> ())
                | "requires" -> (match !cur with Some s -> cur := Some { s with requires = v } | None -> ())
                | _ -> ())
       done
     with End_of_file -> ());
    flush ();
    close_in ic;
    if !acc <> [] then table := List.rev !acc)

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
         (* A constructor or vtable builder is under the same prefix as the
            operations but cannot suspend, so it does not imply a runtime. *)
         && not (List.exists (fun p -> starts_with p path) s.pure)
      then Some (s.name, s.requires)
      else None)
    !table

(* Which scheduler owns this effect, if any? Used to tell "you forgot a
   handler" apart from "you are running this under the wrong runtime". *)
let owner_of_effect id =
  List.find_map
    (fun s -> if List.exists (has_prefix id) s.prefixes then Some s.name else None)
    !table
