(* The masc shape: a test helper calls into Eio with no runtime installed. *)
let helper () = Eio.Mutex.use_rw () (fun () -> ())
let () = helper ()
