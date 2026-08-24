(* Performs via the alias, handles via the original. Runs cleanly. *)
let () =
  match Effect.perform Reexport.Effects.Fork with
  | () -> ()
  | effect Orig.Fork, k -> Effect.Deep.continue k ()
