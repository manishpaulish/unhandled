(* Observed in the wild: guard against running outside the scheduler.
   The effect does escape; the author has handled the consequence. *)
type _ Effect.t += Lock : unit Effect.t
let acquire () = Effect.perform Lock
let () =
  try acquire () with Effect.Unhandled _ -> print_endline "fell back"
