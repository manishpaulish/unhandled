(* The guard may bind the exception with [as] and still be a guard. Keeps the
   directory at exactly one finding, so a broken [Tpat_alias] shim shows up as
   a second error rather than as silence. *)
type _ Effect.t += Fetch : unit Effect.t
let fetch () = Effect.perform Fetch
let () =
  try fetch () with Effect.Unhandled _ as _e -> print_endline "fell back"
