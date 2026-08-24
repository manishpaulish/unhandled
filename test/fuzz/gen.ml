(* Random effectful-program generator for differential testing.

   The point is not to guess what the analyser should say. The *runtime is the
   oracle*: we generate a program, ask the analyser whether any effect escapes,
   then run the program and see whether it actually crashes. Any disagreement
   is a genuine bug in the analyser.

   Generated programs are deliberately branch-free. A conditional would make
   the analyser join both arms and legitimately over-approximate, which is
   known-by-design imprecision that would swamp real defects. Branching is a
   separate experiment. *)

let neffects = 4

type expr =
  | Perform of int
  | Call of int
  | Seq of expr * expr
  | Iter of expr                      (* List.iter (fun _ -> e) [();()] *)
  | HandleSyn of int list * expr      (* match .. with effect Ei, k *)
  | HandleDeep of int list * expr     (* Effect.Deep.try_with, with _ -> None *)

let rec gen_expr depth nfuns =
  let leaf () =
    if nfuns > 0 && Random.bool () then Call (Random.int nfuns)
    else Perform (Random.int neffects)
  in
  if depth <= 0 then leaf ()
  else
    match Random.int 6 with
    | 0 -> leaf ()
    | 1 -> Seq (gen_expr (depth - 1) nfuns, gen_expr (depth - 1) nfuns)
    | 2 -> Iter (gen_expr (depth - 1) nfuns)
    | 3 | 4 ->
        let n = 1 + Random.int 2 in
        let hs = List.init n (fun _ -> Random.int neffects) in
        HandleSyn (hs, gen_expr (depth - 1) nfuns)
    | _ ->
        let n = 1 + Random.int 2 in
        let hs = List.init n (fun _ -> Random.int neffects) in
        HandleDeep (hs, gen_expr (depth - 1) nfuns)

let buf = Buffer.create 4096
let p fmt = Printf.ksprintf (Buffer.add_string buf) fmt

let uniq l = List.sort_uniq compare l

let rec emit ind e =
  let pad = String.make ind ' ' in
  match e with
  | Perform i -> p "%s(Effect.perform E%d)" pad i
  | Call i -> p "%s(f%d ())" pad i
  | Seq (a, b) ->
      p "%s(\n" pad; emit (ind + 2) a; p ";\n"; emit (ind + 2) b; p "\n%s)" pad
  | Iter a ->
      p "%s(List.iter (fun _ ->\n" pad; emit (ind + 2) a;
      p "\n%s) [(); ()])" pad
  | HandleSyn (hs, a) ->
      p "%s(match\n" pad; emit (ind + 2) a; p "\n%s with\n" pad;
      p "%s | () -> ()\n" pad;
      List.iter (fun i ->
          p "%s | effect E%d, k -> Effect.Deep.continue k ()\n" pad i)
        (uniq hs);
      p "%s)" pad
  | HandleDeep (hs, a) ->
      p "%s(Effect.Deep.try_with (fun () ->\n" pad; emit (ind + 2) a;
      p "\n%s) ()\n" pad;
      p "%s  { effc = (fun (type c) (eff : c Effect.t) ->\n" pad;
      p "%s      match eff with\n" pad;
      List.iter (fun i ->
          p "%s      | E%d -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())\n" pad i)
        (uniq hs);
      (* The forwarding wildcard: looks like a catch-all, handles nothing. *)
      p "%s      | _ -> None) })" pad

let () =
  let seed = int_of_string Sys.argv.(1) in
  Random.init seed;
  let nfuns = 1 + Random.int 3 in
  for i = 0 to neffects - 1 do
    p "type _ Effect.t += E%d : unit Effect.t\n" i
  done;
  (* Functions may only call functions defined before them: no recursion, so
     every generated program terminates. *)
  for i = 0 to nfuns - 1 do
    p "let f%d () =\n" i;
    emit 2 (gen_expr (1 + Random.int 2) i);
    p "\n";
  done;
  p "let () =\n";
  emit 2 (gen_expr (2 + Random.int 2) nfuns);
  p "\n";
  print_string (Buffer.contents buf)
