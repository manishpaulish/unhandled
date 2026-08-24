(* B3: contexts where performing an effect is always fatal.

   The OCaml manual (Effect handlers, "Limitations") documents two of these:

     "It is not possible to perform an effect asynchronously from a signal
      handler, a finaliser, a memprof callback, or a GC alarm, and catch it
      from the main part of the code. Instead, this would result in an
      Effect.Unhandled exception."

     "effects are incompatible with the use of callbacks from C to OCaml. It
      is not possible for an effect to cross a call to caml_callback."

   Both are statically detectable: find the registration site, look at the
   callback, ask whether it can perform anything. No handler anywhere in the
   program can rescue these, so an escaping effect here is unconditional. *)

type registrar = {
  path : string;
  callback_arg : int;   (* 0-based index of the callback argument *)
  why : string;
}

let registrars =
  [ { path = "Stdlib.Gc.finalise"; callback_arg = 0; why = "a finaliser, where no handler can ever catch it" };
    { path = "Stdlib.Gc.finalise_last"; callback_arg = 0; why = "a finaliser, where no handler can ever catch it" };
    { path = "Stdlib.Gc.create_alarm"; callback_arg = 0; why = "a GC alarm, where no handler can ever catch it" };
    { path = "Stdlib.Sys.signal"; callback_arg = 1; why = "a signal handler, where no handler can ever catch it" };
    { path = "Stdlib.Sys.set_signal"; callback_arg = 1; why = "a signal handler, where no handler can ever catch it" };
    { path = "Stdlib.Callback.register"; callback_arg = 1;
      why = "a callback invoked from C, which an effect cannot cross" };
    { path = "Stdlib.Gc.Memprof.start"; callback_arg = 2;
      why = "a memprof callback, where no handler can ever catch it" };

    (* Handler-scope transfers.

       An effect handler is installed on one fiber's stack. Moving execution to
       a different domain or a systhread leaves that stack behind, so handlers
       enclosing the *spawn site* do not enclose the spawned code. The retro
       corpus made this concrete: the masc fixes read "wrap tests in
       Eio.Switch.run", "Eio work runs on a bare systhread", "guard
       Domain_pool_ref submits against non-Eio callers". Every one is a
       dynamic context transfer rather than a missing handler in the call
       graph, and we caught none of them until this was modelled.

       Domain.spawn was previously treated as a combinator, attributing the
       spawned function's effects to its caller, which is precisely backwards. *)
    { path = "Stdlib.Domain.spawn"; callback_arg = 0;
      why = "a new domain, where the spawn site's handlers do not apply" };
    { path = "Stdlib.Thread.create"; callback_arg = 0;
      why = "a new systhread, where the spawn site's handlers do not apply" };
    { path = "Thread.create"; callback_arg = 0;
      why = "a new systhread, where the spawn site's handlers do not apply" };
    { path = "Eio_unix.run_in_systhread"; callback_arg = 0;
      why = "a systhread, where the Eio runtime's handlers do not apply" };
    { path = "Eio_unix.Private.run_in_systhread"; callback_arg = 0;
      why = "a systhread, where the Eio runtime's handlers do not apply" };
    { path = "Eio_unix.Thread_pool.run_in_systhread"; callback_arg = 0;
      why = "a systhread, where the Eio runtime's handlers do not apply" } ]

let find path = List.find_opt (fun r -> String.equal r.path path) registrars
