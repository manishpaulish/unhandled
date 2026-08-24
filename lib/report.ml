type kind =
  | Escapes of Effect_id.t
  | Unknown_effects
  | Scheduler_mismatch of Effect_id.t * string * string  (* effect, owner, running under *)
  | Boundary_crossing of Effect_id.t * string           (* effect, fatal context *)

type finding = {
  f_kind : kind;
  f_entry : string;
  f_loc : Location.t;
  f_path : Solver.step list;
}

let string_of_loc (l : Location.t) =
  let p = l.Location.loc_start in
  if p.Lexing.pos_lnum <= 0 then p.Lexing.pos_fname
  else
    Printf.sprintf "%s:%d:%d" p.Lexing.pos_fname p.Lexing.pos_lnum
      (p.Lexing.pos_cnum - p.Lexing.pos_bol)

let code = function
  | Escapes _ -> "E001"
  | Unknown_effects -> "W002"
  | Scheduler_mismatch _ -> "E003"
  | Boundary_crossing _ -> "E004"

let headline f =
  match f.f_kind with
  | Escapes e ->
      Printf.sprintf "effect %s escapes unhandled" (Effect_id.to_string e)
  | Unknown_effects ->
      "effects of unknown identity may escape (unresolved call)"
  | Scheduler_mismatch (e, owner, under) ->
      Printf.sprintf
        "effect %s belongs to the %s scheduler but is performed under the %s runtime"
        (Effect_id.to_string e) owner under
  | Boundary_crossing (e, why) ->
      Printf.sprintf
        "effect %s can be performed from %s, where no handler can ever catch it"
        (Effect_id.to_string e) why

let render buf f =
  Printf.bprintf buf "%s: %s[%s] %s\n"
    (string_of_loc f.f_loc)
    (match f.f_kind with Unknown_effects -> "warning" | _ -> "error")
    (code f.f_kind) (headline f);
  Printf.bprintf buf "  entry     %s\n" f.f_entry;
  List.iteri
    (fun i (s : Solver.step) ->
      Printf.bprintf buf "  %-9s %s  %s\n"
        (if i = 0 then "via" else "then")
        (string_of_loc s.Solver.st_loc) s.Solver.st_what)
    f.f_path;
  Buffer.add_char buf '\n'

let render_all fs =
  let buf = Buffer.create 1024 in
  List.iter (render buf) fs;
  let errs = List.length (List.filter (fun f -> match f.f_kind with Unknown_effects -> false | _ -> true) fs) in
  let warns = List.length fs - errs in
  Printf.bprintf buf "%d error(s), %d warning(s)\n" errs warns;
  Buffer.contents buf

(* ------------------------------------------------------------------- JSON *)

(* Hand-rolled so the tool keeps zero external dependencies. Only the escapes
   below can appear in our strings, but escape properly anyway: a project path
   with a backslash in it should not silently corrupt a sweep result. *)
let json_escape s =
  let b = Buffer.create (String.length s + 8) in
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | '\t' -> Buffer.add_string b "\\t"
      | '\r' -> Buffer.add_string b "\\r"
      | c when Char.code c < 0x20 ->
          Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char b c)
    s;
  Buffer.contents b

let q s = "\"" ^ json_escape s ^ "\""

let kind_name = function
  | Escapes _ -> "escape"
  | Unknown_effects -> "unknown"
  | Scheduler_mismatch _ -> "scheduler_mismatch"
  | Boundary_crossing _ -> "boundary"

let effect_name = function
  | Escapes e | Scheduler_mismatch (e, _, _) | Boundary_crossing (e, _) ->
      Effect_id.to_string e
  | Unknown_effects -> ""

let json_of_finding f =
  let steps =
    f.f_path
    |> List.map (fun (s : Solver.step) ->
           Printf.sprintf "{\"loc\":%s,\"what\":%s}"
             (q (string_of_loc s.Solver.st_loc)) (q s.Solver.st_what))
    |> String.concat ","
  in
  Printf.sprintf
    "{\"code\":%s,\"kind\":%s,\"effect\":%s,\"loc\":%s,\"entry\":%s,\"message\":%s,\"path\":[%s]}"
    (q (code f.f_kind)) (q (kind_name f.f_kind)) (q (effect_name f.f_kind))
    (q (string_of_loc f.f_loc))
    (q f.f_entry) (q (headline f)) steps

let render_json fs =
  let counts kind =
    List.length (List.filter (fun f -> code f.f_kind = kind) fs)
  in
  Printf.sprintf
    "{\"summary\":{\"total\":%d,\"escapes\":%d,\"unknown\":%d,\"scheduler_mismatch\":%d,\"boundary\":%d},\"findings\":[%s]}\n"
    (List.length fs) (counts "E001") (counts "W002") (counts "E003")
    (counts "E004")
    (String.concat "," (List.map json_of_finding fs))
