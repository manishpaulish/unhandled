(* A minimal JSON reader and writer.

   Hand-written to keep the tool dependency-free: an editor plugin that needs
   an opam solve before it will start is an editor plugin nobody installs.
   Only what LSP traffic actually contains is supported. *)

type t =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | Str of string
  | List of t list
  | Obj of (string * t) list

exception Parse_error of string

(* ------------------------------------------------------------------ writing *)

let escape b s =
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | '\r' -> Buffer.add_string b "\\r"
      | '\t' -> Buffer.add_string b "\\t"
      | c when Char.code c < 0x20 ->
          Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char b c)
    s

let rec write b = function
  | Null -> Buffer.add_string b "null"
  | Bool x -> Buffer.add_string b (if x then "true" else "false")
  | Int n -> Buffer.add_string b (string_of_int n)
  | Float f -> Buffer.add_string b (Printf.sprintf "%g" f)
  | Str s -> Buffer.add_char b '"'; escape b s; Buffer.add_char b '"'
  | List l ->
      Buffer.add_char b '[';
      List.iteri (fun i x -> if i > 0 then Buffer.add_char b ','; write b x) l;
      Buffer.add_char b ']'
  | Obj kvs ->
      Buffer.add_char b '{';
      List.iteri
        (fun i (k, v) ->
          if i > 0 then Buffer.add_char b ',';
          Buffer.add_char b '"'; escape b k; Buffer.add_string b "\":";
          write b v)
        kvs;
      Buffer.add_char b '}'

let to_string v =
  let b = Buffer.create 256 in
  write b v;
  Buffer.contents b

(* ------------------------------------------------------------------ reading *)

let of_string s =
  let n = String.length s in
  let i = ref 0 in
  let fail m = raise (Parse_error (Printf.sprintf "%s at %d" m !i)) in
  let peek () = if !i < n then Some s.[!i] else None in
  let rec skip () =
    match peek () with
    | Some (' ' | '\t' | '\n' | '\r') -> incr i; skip ()
    | _ -> ()
  in
  let expect c = if !i < n && s.[!i] = c then incr i else fail (Printf.sprintf "expected %c" c) in
  let lit w v =
    let l = String.length w in
    if !i + l <= n && String.sub s !i l = w then (i := !i + l; v) else fail "bad literal"
  in
  let read_string () =
    expect '"';
    let b = Buffer.create 32 in
    let rec go () =
      if !i >= n then fail "unterminated string"
      else
        match s.[!i] with
        | '"' -> incr i
        | '\\' ->
            incr i;
            if !i >= n then fail "bad escape";
            (match s.[!i] with
             | 'n' -> Buffer.add_char b '\n'
             | 't' -> Buffer.add_char b '\t'
             | 'r' -> Buffer.add_char b '\r'
             | 'b' -> Buffer.add_char b '\b'
             | 'f' -> Buffer.add_char b '\012'
             | '/' -> Buffer.add_char b '/'
             | '"' -> Buffer.add_char b '"'
             | '\\' -> Buffer.add_char b '\\'
             | 'u' ->
                 (* Only the BMP range editors actually send; anything above
                    is passed through as a replacement rather than guessed. *)
                 if !i + 4 >= n then fail "bad \\u";
                 let hex = String.sub s (!i + 1) 4 in
                 i := !i + 4;
                 let code = int_of_string ("0x" ^ hex) in
                 if code < 0x80 then Buffer.add_char b (Char.chr code)
                 else if code < 0x800 then (
                   Buffer.add_char b (Char.chr (0xC0 lor (code lsr 6)));
                   Buffer.add_char b (Char.chr (0x80 lor (code land 0x3F))))
                 else (
                   Buffer.add_char b (Char.chr (0xE0 lor (code lsr 12)));
                   Buffer.add_char b (Char.chr (0x80 lor ((code lsr 6) land 0x3F)));
                   Buffer.add_char b (Char.chr (0x80 lor (code land 0x3F))))
             | c -> Buffer.add_char b c);
            incr i; go ()
        | c -> Buffer.add_char b c; incr i; go ()
    in
    go ();
    Buffer.contents b
  in
  let read_number () =
    let start = !i in
    if peek () = Some '-' then incr i;
    let isf = ref false in
    let rec go () =
      match peek () with
      | Some ('0' .. '9') -> incr i; go ()
      | Some ('.' | 'e' | 'E' | '+' | '-') -> isf := true; incr i; go ()
      | _ -> ()
    in
    go ();
    let text = String.sub s start (!i - start) in
    if !isf then Float (float_of_string text) else Int (int_of_string text)
  in
  let rec value () =
    skip ();
    match peek () with
    | None -> fail "unexpected end"
    | Some '"' -> Str (read_string ())
    | Some '{' ->
        incr i; skip ();
        if peek () = Some '}' then (incr i; Obj [])
        else
          let rec members acc =
            skip ();
            let k = read_string () in
            skip (); expect ':';
            let v = value () in
            skip ();
            match peek () with
            | Some ',' -> incr i; members ((k, v) :: acc)
            | Some '}' -> incr i; Obj (List.rev ((k, v) :: acc))
            | _ -> fail "expected , or }"
          in
          members []
    | Some '[' ->
        incr i; skip ();
        if peek () = Some ']' then (incr i; List [])
        else
          let rec items acc =
            let v = value () in
            skip ();
            match peek () with
            | Some ',' -> incr i; items (v :: acc)
            | Some ']' -> incr i; List (List.rev (v :: acc))
            | _ -> fail "expected , or ]"
          in
          items []
    | Some 't' -> lit "true" (Bool true)
    | Some 'f' -> lit "false" (Bool false)
    | Some 'n' -> lit "null" Null
    | Some _ -> read_number ()
  in
  let v = value () in
  v

(* ---------------------------------------------------------------- accessors *)

let member k = function Obj kvs -> (try List.assoc k kvs with Not_found -> Null) | _ -> Null
let to_string_opt = function Str s -> Some s | _ -> None
let to_int_opt = function Int n -> Some n | Float f -> Some (int_of_float f) | _ -> None
