(* An effect performed from a finaliser. No handler anywhere can catch it. *)
type _ Effect.t += Log : unit Effect.t
let () = Gc.finalise (fun _ -> Effect.perform Log) (ref 0)
let () =
  (* Even wrapping the whole program in a handler cannot help. *)
  match Gc.full_major () with
  | () -> print_endline "finaliser ran without crashing"
  | effect Log, k -> Effect.Deep.continue k ()
