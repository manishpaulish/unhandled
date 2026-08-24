(* A Language Server for unhandled.

   Deliberately small: it reacts to open and save, not to every keystroke.
   Effects are a whole-program property and the analysis reads .cmt files, so
   there is nothing useful to say about a buffer that has not been compiled.
   Re-checking on save is honest about that, and the summary cache is what
   makes it fast enough to do every time. *)

let log fmt = Printf.eprintf ("[unhandled-lsp] " ^^ fmt ^^ "\n%!")

(* ------------------------------------------------------------------ framing *)

let read_message ic =
  let rec headers len =
    match input_line ic with
    | exception End_of_file -> None
    | line ->
        let line = String.trim line in
        if line = "" then Some len
        else
          let lower = String.lowercase_ascii line in
          let prefix = "content-length:" in
          if String.length lower > String.length prefix
             && String.sub lower 0 (String.length prefix) = prefix
          then
            let v =
              String.trim
                (String.sub line (String.length prefix)
                   (String.length line - String.length prefix))
            in
            headers (int_of_string_opt v)
          else headers len
  in
  match headers None with
  | None | Some None -> None
  | Some (Some len) ->
      let buf = Bytes.create len in
      really_input ic buf 0 len;
      Some (Bytes.to_string buf)

let send oc (v : Json.t) =
  let body = Json.to_string v in
  Printf.fprintf oc "Content-Length: %d\r\n\r\n%s" (String.length body) body;
  flush oc

let respond oc id result =
  send oc (Json.Obj [ ("jsonrpc", Json.Str "2.0"); ("id", id); ("result", result) ])

let notify oc m params =
  send oc
    (Json.Obj
       [ ("jsonrpc", Json.Str "2.0"); ("method", Json.Str m); ("params", params) ])

(* --------------------------------------------------------------------- URIs *)

let uri_to_path u =
  let u = if String.length u > 7 && String.sub u 0 7 = "file://" then
            String.sub u 7 (String.length u - 7) else u in
  let b = Buffer.create (String.length u) in
  let i = ref 0 in
  while !i < String.length u do
    if u.[!i] = '%' && !i + 2 < String.length u then (
      (match int_of_string_opt ("0x" ^ String.sub u (!i + 1) 2) with
       | Some c -> Buffer.add_char b (Char.chr c)
       | None -> Buffer.add_char b u.[!i]);
      i := !i + 3)
    else (Buffer.add_char b u.[!i]; incr i)
  done;
  Buffer.contents b

let path_to_uri p =
  let b = Buffer.create (String.length p + 8) in
  Buffer.add_string b "file://";
  String.iter
    (fun c ->
      match c with
      | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '/' | '.' | '_' | '-' | '~' ->
          Buffer.add_char b c
      | c -> Buffer.add_string b (Printf.sprintf "%%%02X" (Char.code c)))
    p;
  Buffer.contents b

(* ------------------------------------------------------------- project shape *)

let rec find_root dir =
  if Sys.file_exists (Filename.concat dir "dune-project") then Some dir
  else
    let up = Filename.dirname dir in
    if up = dir then None else find_root up

(* A finding's filename comes from the compiler and is relative to the build
   context. Resolve it back to something the editor can open. *)
let resolve_in_root root fname =
  let direct = Filename.concat root fname in
  if Sys.file_exists direct then Some direct
  else
    let base = Filename.basename fname in
    let found = ref None in
    let rec walk d depth =
      if depth > 6 || !found <> None then ()
      else
        match Sys.readdir d with
        | entries ->
            Array.iter
              (fun e ->
                if !found = None && e <> "_build" && e <> ".git" then
                  let p = Filename.concat d e in
                  if Sys.is_directory p then walk p (depth + 1)
                  else if e = base then found := Some p)
              entries
        | exception Sys_error _ -> ()
    in
    walk root 0;
    !found

(* ------------------------------------------------------------- diagnostics *)

let range_of_loc (l : Location.t) =
  let p = l.Location.loc_start in
  let line = max 0 (p.Lexing.pos_lnum - 1) in
  let col = max 0 (p.Lexing.pos_cnum - p.Lexing.pos_bol) in
  Json.Obj
    [ ("start", Json.Obj [ ("line", Json.Int line); ("character", Json.Int col) ]);
      ("end", Json.Obj [ ("line", Json.Int line); ("character", Json.Int (col + 1)) ]) ]

let severity_of (f : Report.finding) =
  match f.Report.f_kind with Report.Unknown_effects -> 2 | _ -> 1

let diagnostic root (f : Report.finding) =
  (* The blame path becomes relatedInformation, which editors render as a
     clickable chain: the point of the finding is the path, not the line. *)
  let related =
    f.Report.f_path
    |> List.filter_map (fun (s : Solver.step) ->
           let fname = s.Solver.st_loc.Location.loc_start.Lexing.pos_fname in
           match resolve_in_root root fname with
           | None -> None
           | Some p ->
               Some
                 (Json.Obj
                    [ ("location",
                       Json.Obj
                         [ ("uri", Json.Str (path_to_uri p));
                           ("range", range_of_loc s.Solver.st_loc) ]);
                      ("message", Json.Str s.Solver.st_what) ]))
  in
  Json.Obj
    [ ("range", range_of_loc f.Report.f_loc);
      ("severity", Json.Int (severity_of f));
      ("source", Json.Str "unhandled");
      ("code", Json.Str (Report.code f.Report.f_kind));
      ("message", Json.Str (Report.headline f));
      ("relatedInformation", Json.List related) ]

(* Files we published for last time, so they can be cleared when they go clean.
   Without this a fixed error stays on screen forever. *)
let published : (string, unit) Hashtbl.t = Hashtbl.create 16

let analyse_and_publish oc path =
  match find_root (Filename.dirname path) with
  | None -> log "no dune-project above %s" path
  | Some root ->
      let build = Filename.concat root "_build" in
      if not (Sys.file_exists build) then
        log "no _build under %s; run dune build" root
      else (
        Cache.set_dir (Filename.concat build ".unhandled-cache");
        let files = Driver.find_cmts build [] in
        let _, _, findings = Driver.analyse files in
        let by_file = Hashtbl.create 16 in
        List.iter
          (fun (f : Report.finding) ->
            let fname = f.Report.f_loc.Location.loc_start.Lexing.pos_fname in
            match resolve_in_root root fname with
            | None -> ()
            | Some p ->
                let cur = try Hashtbl.find by_file p with Not_found -> [] in
                Hashtbl.replace by_file p (f :: cur))
          findings;
        (* Clear anything that reported last time and is clean now. *)
        Hashtbl.iter
          (fun p () ->
            if not (Hashtbl.mem by_file p) then
              notify oc "textDocument/publishDiagnostics"
                (Json.Obj
                   [ ("uri", Json.Str (path_to_uri p));
                     ("diagnostics", Json.List []) ]))
          published;
        Hashtbl.reset published;
        Hashtbl.iter
          (fun p fs ->
            Hashtbl.replace published p ();
            notify oc "textDocument/publishDiagnostics"
              (Json.Obj
                 [ ("uri", Json.Str (path_to_uri p));
                   ("diagnostics",
                    Json.List (List.rev_map (diagnostic root) fs)) ]))
          by_file;
        (* The opened file may be clean; say so explicitly. *)
        if not (Hashtbl.mem by_file path) then
          notify oc "textDocument/publishDiagnostics"
            (Json.Obj
               [ ("uri", Json.Str (path_to_uri path));
                 ("diagnostics", Json.List []) ]))

(* --------------------------------------------------------------------- loop *)

let capabilities =
  Json.Obj
    [ ("capabilities",
       Json.Obj
         [ ("textDocumentSync",
            Json.Obj
              [ ("openClose", Json.Bool true); ("save", Json.Bool true);
                ("change", Json.Int 0) ]) ]);
      ("serverInfo",
       Json.Obj [ ("name", Json.Str "unhandled"); ("version", Json.Str "0.4") ]) ]

let handle oc msg =
  let m = Json.to_string_opt (Json.member "method" msg) in
  let id = Json.member "id" msg in
  let params = Json.member "params" msg in
  let doc_path () =
    Json.member "textDocument" params |> Json.member "uri" |> Json.to_string_opt
    |> Option.map uri_to_path
  in
  match m with
  | Some "initialize" -> respond oc id capabilities; false
  | Some "initialized" -> false
  | Some "textDocument/didOpen" | Some "textDocument/didSave" ->
      (match doc_path () with
       | Some p -> (try analyse_and_publish oc p with e -> log "error: %s" (Printexc.to_string e))
       | None -> ());
      false
  | Some "shutdown" -> respond oc id Json.Null; false
  | Some "exit" -> true
  | Some other -> if id <> Json.Null then respond oc id Json.Null else log "ignored %s" other; false
  | None -> false

let run () =
  set_binary_mode_in stdin true;
  set_binary_mode_out stdout true;
  let rec loop () =
    match read_message stdin with
    | None -> ()
    | Some body -> (
        match Json.of_string body with
        | msg -> if handle stdout msg then () else loop ()
        | exception Json.Parse_error e -> log "bad json: %s" e; loop ())
  in
  loop ()
