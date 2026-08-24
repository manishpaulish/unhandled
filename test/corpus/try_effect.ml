(* EXPECT: clean *)
(* try ... with effect: Texp_try carries its own effect-case list. *)
type _ Effect.t += A : unit Effect.t
let comp () = Effect.perform A
let () = try comp () with effect A, k -> Effect.Deep.continue k ()
