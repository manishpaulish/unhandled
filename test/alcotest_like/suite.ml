(* A test body that performs an effect with no handler: the exact shape of the
   crash recorded in bench/RETROACTIVE.md as R1. *)
type _ Effect.t += Needs_runtime : unit Effect.t
let body () = Effect.perform Needs_runtime
let () =
  Alcotest.run "suite" [ ("group", [ Alcotest.test_case "t" `Quick body ]) ]
