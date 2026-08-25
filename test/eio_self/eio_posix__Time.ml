(* The file name gives this the module name Eio_posix__Time, exactly as dune
   names a wrapped submodule of the eio_posix library.

   It calls Eio.Mutex.use_rw at module initialisation, which is deliberately
   NOT on the pure list: the same call from a module that is not part of eio
   is an error, and test/eio_api asserts that. The only thing making this one
   clean is the self rule, so the two fixtures isolate it.

   The rule: the api model says "you called an Eio operation, so you need an
   Eio runtime". That describes a client. eio does not need an Eio runtime in
   order to define itself, and its own modules build resources at
   initialisation as a matter of course. Applying the client model to the
   implementation produced all 21 findings in the eio repository.

   Expected: clean. *)
let guarded () = Eio.Mutex.use_rw () (fun () -> ())

let () = guarded ()
