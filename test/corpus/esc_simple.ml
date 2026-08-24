(* EXPECT: crash Emit *)
type _ Effect.t += Emit : string -> unit Effect.t
let log msg    = Effect.perform (Emit msg)
let process xs = List.iter log xs
let () = process ["a"; "b"]
