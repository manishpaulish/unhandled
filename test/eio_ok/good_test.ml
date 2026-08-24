let helper () = Eio.Mutex.use_rw () (fun () -> ())
let () = Eio_main.run (fun _env -> helper ())
