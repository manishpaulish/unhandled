type _ Effect.t += Ping : unit Effect.t
let () = Sys.set_signal Sys.sigusr1 (Sys.Signal_handle (fun _ -> Effect.perform Ping))
