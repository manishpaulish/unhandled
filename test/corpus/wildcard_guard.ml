(* EXPECT: clean *)
(* A catch-all exception case catches Effect.Unhandled along with everything
   else, so the program does not die. picos does exactly this and explains why
   in a comment: the exception's identity depends on the OCaml version, so
   they deliberately do not name it.

     lib/picos_std.finally/picos_std_finally.ml:47
     | exception _exn ->
         (* This should only happen when not running under a scheduler. *)
         release x

   Requiring the name Effect.Unhandled reported all three picos escapes as
   crashes that cannot happen. This program is in the corpus rather than the
   scenarios so the runtime confirms it: it prints and exits 0. *)
type _ Effect.t += Ping : unit Effect.t

let risky () = Effect.perform Ping

let () =
  match risky () with
  | () -> print_endline "handled"
  | exception _ -> print_endline "no scheduler, carrying on"
