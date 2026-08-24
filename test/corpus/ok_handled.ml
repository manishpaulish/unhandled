(* EXPECT: clean *)
type _ Effect.t += Emit : string -> unit Effect.t
let log msg = Effect.perform (Emit msg)
let () =
  match log "hello" with
  | () -> ()
  | effect (Emit _), k -> Effect.Deep.continue k ()
