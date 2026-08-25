(* Stands in for a wrapped library submodule as dune names it: the file is
   eio__Mutex.ml, so the module is Eio__Mutex, exactly as `eio` is built. *)
let use_rw _ f = f ()
