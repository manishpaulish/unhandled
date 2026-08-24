(* EXPECT: crash Tick *)
type _ Effect.t += Tick : unit Effect.t
let rec countdown n = if n = 0 then () else (Effect.perform Tick; countdown (n - 1))
let () = countdown 3
