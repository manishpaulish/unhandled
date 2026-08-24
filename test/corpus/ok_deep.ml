(* EXPECT: clean *)
type _ Effect.t += A : unit Effect.t
let comp () = Effect.perform A
let run () =
  Effect.Deep.try_with comp ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | A -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) }
let () = run ()
