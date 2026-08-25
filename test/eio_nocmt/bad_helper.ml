(* The shape of the real fixes in jeong-sik/masc, e.g.

     fix(test): wrap coverage test helpers in Eio context (#3396)
     fix(ci):   wrap Eio-dependent tests in Eio context (#3349)

   A helper reaches into Eio with no runtime installed anywhere above it. The
   program compiles and dies at run time.

   This scenario deletes the Eio .cmt files before checking, because that is
   the condition every real run works under: a dependency installed from opam
   ships no typed trees. The detection therefore cannot come from analysing
   Eio; it comes from the API model in models/schedulers.conf, which says that
   calling Eio.* at all requires an Eio runtime.

   The retroactive batch caught 0 of 6 crashes of exactly this shape, and this
   fixture is here to keep the two explanations apart. If it passes, the
   detector fires on the bug class under the conditions of that run, and the
   0 of 6 is about which files compiled, not about what we can see. *)
let helper () = Eio.Mutex.use_rw () (fun () -> ())

let () = helper ()
