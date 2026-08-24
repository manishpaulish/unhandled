type kind = Escapes of Effect_id.t | Unknown_effects

type finding = {
  f_kind : kind;
  f_entry : string;
  f_loc : Location.t;
  f_path : Solver.step list;
}

let string_of_loc (l : Location.t) =
  let p = l.Location.loc_start in
  Printf.sprintf "%s:%d:%d" p.Lexing.pos_fname p.Lexing.pos_lnum
    (p.Lexing.pos_cnum - p.Lexing.pos_bol)

let code = function Escapes _ -> "E001" | Unknown_effects -> "W002"

let headline f =
  match f.f_kind with
  | Escapes e ->
      Printf.sprintf "effect %s escapes unhandled" (Effect_id.to_string e)
  | Unknown_effects ->
      "effects of unknown identity may escape (unresolved call)"

let render buf f =
  Printf.bprintf buf "%s: %s[%s] %s\n"
    (string_of_loc f.f_loc)
    (match f.f_kind with Escapes _ -> "error" | Unknown_effects -> "warning")
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
  let errs = List.length (List.filter (fun f -> match f.f_kind with Escapes _ -> true | _ -> false) fs) in
  let warns = List.length fs - errs in
  Printf.bprintf buf "%d error(s), %d warning(s)\n" errs warns;
  Buffer.contents buf
