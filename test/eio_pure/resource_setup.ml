(* Regression test for the first three escapes this tool ever reported on
   third-party code. All three were false positives, all in cohttp-eio, all
   this shape: a library module initialiser building a resource.

     cohttp-eio/src/body.ml:20   let of_string =
                                   let ops = Eio.Flow.Pi.source (module S) in
                                   fun s -> Eio.Resource.T (S.create s, ops)

   The call really does run at module initialisation, so the analyser was
   right about *when*. It was wrong about *what*: Pi.source builds a vtable
   from a first-class module and Stream.create allocates a queue. Neither
   suspends, so neither needs a runtime, and the api prefix rule saying
   "anything under Eio. requires Eio" was too blunt.

   Expected: clean. test/eio_api covers the opposite case, where an Eio
   operation that genuinely does suspend is called with no runtime, so the two
   fixtures together pin both directions of the rule. *)

let of_string =
  let ops = Eio.Flow.Pi.source "String_source" in
  fun s -> (s, ops)

let side_channel = Eio.Stream.create 1

let () =
  ignore (of_string "witness");
  ignore side_channel
