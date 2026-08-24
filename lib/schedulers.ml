(* Scheduler model table.

   Handlers for Eio/Riot/Moonpool effects live inside compiled dependencies we
   often have no .cmt for, so they cannot be discovered by analysis. They are
   supplied as data instead: which entry point installs handlers for which
   family of effects. This is also what makes cross-scheduler leakage
   detectable, since we then know which scheduler each effect belongs to. *)

type t = { name : string; runs : string list; prefixes : string list }

let builtin =
  [ { name = "eio";
      runs = [ "Eio_main.run"; "Eio_linux.run"; "Eio_posix.run" ];
      prefixes = [ "Eio"; "Eio_core" ] };
    { name = "riot"; runs = [ "Riot.run" ]; prefixes = [ "Riot" ] };
    { name = "moonpool"; runs = [ "Moonpool.run" ]; prefixes = [ "Moonpool" ] };
    { name = "miou"; runs = [ "Miou.run"; "Miou_unix.run" ]; prefixes = [ "Miou" ] };
    { name = "mock_a"; runs = [ "Sched_a.run" ]; prefixes = [ "Sched_a" ] };
    { name = "mock_b"; runs = [ "Sched_b.run" ]; prefixes = [ "Sched_b" ] } ]

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
                | "scheduler" -> flush (); cur := Some { name = v; runs = []; prefixes = [] }
                | "run" -> (match !cur with Some s -> cur := Some { s with runs = v :: s.runs } | None -> ())
                | "prefix" -> (match !cur with Some s -> cur := Some { s with prefixes = v :: s.prefixes } | None -> ())
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

let has_prefix id p =
  let n = String.length p in
  String.length id > n && String.sub id 0 n = p && id.[n] = '.'

(* Which scheduler owns this effect, if any? Used to tell "you forgot a
   handler" apart from "you are running this under the wrong runtime". *)
let owner_of_effect id =
  List.find_map
    (fun s -> if List.exists (has_prefix id) s.prefixes then Some s.name else None)
    !table
