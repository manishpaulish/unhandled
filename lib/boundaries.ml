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
  [ { path = "Stdlib.Gc.finalise"; callback_arg = 0; why = "a finaliser" };
    { path = "Stdlib.Gc.finalise_last"; callback_arg = 0; why = "a finaliser" };
    { path = "Stdlib.Gc.create_alarm"; callback_arg = 0; why = "a GC alarm" };
    { path = "Stdlib.Sys.signal"; callback_arg = 1; why = "a signal handler" };
    { path = "Stdlib.Sys.set_signal"; callback_arg = 1; why = "a signal handler" };
    { path = "Stdlib.Callback.register"; callback_arg = 1;
      why = "a callback invoked from C" };
    { path = "Stdlib.Gc.Memprof.start"; callback_arg = 2;
      why = "a memprof callback" } ]

let find path = List.find_opt (fun r -> String.equal r.path path) registrars
