(* Same shape without the guard: still a real finding. *)
type _ Effect.t += Lock : unit Effect.t
let acquire () = Effect.perform Lock
let () = acquire ()
