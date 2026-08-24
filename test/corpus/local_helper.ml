(* EXPECT: crash Ping *)
type _ Effect.t += Ping : unit Effect.t
let outer () =
  let helper () = Effect.perform Ping in
  helper ()
let () = outer ()
