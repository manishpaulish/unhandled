(* EXPECT: crash B *)
(* The handler discharges A only; the `_ -> None` arm FORWARDS, it does not
   handle. B must be reported. *)
type _ Effect.t += A : unit Effect.t
type _ Effect.t += B : unit Effect.t
let comp () = Effect.perform A; Effect.perform B
let run () =
  Effect.Deep.try_with comp ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | A -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) }
let () = run ()
