(* A library module: initialisation is clean, but the API leaks an effect. *)
type _ Effect.t += Ping : string -> unit Effect.t
let service msg = Effect.perform (Ping msg)
let run_all xs = List.iter service xs
