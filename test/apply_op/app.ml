(* The shape of forester's bin/forester/main.ml, which produced three of the
   six escapes that survived every earlier fix:

     let () =
       ...
       let@ env = Eio_main.run in
       let@ () = Forester_core.Reporter.easy_run in
       exit @@ Cmd.eval ~catch:false @@ cmd ~env

   `let@` is application spelled as an operator. picos declares the same one:

     external ( let@ ) : ('a -> 'b) -> 'a -> 'b = "%apply"

   so `let@ env = Eio_main.run in body` is `( let@ ) Eio_main.run (fun env ->
   body)`. Leave the operator opaque and the head of that application is the
   operator rather than Eio_main.run: the scheduler boundary is missed and
   everything in the body looks like it runs with no runtime.

   test/eio_api asserts the opposite case, where the same call really does have
   no runtime above it, so the pair pins both directions.

   Expected: clean. *)
external ( let@ ) : ('a -> 'b) -> 'a -> 'b = "%apply"

let helper () = Eio.Mutex.use_rw () (fun () -> ())

let () =
  let@ _env = Eio_main.run in
  helper ()
