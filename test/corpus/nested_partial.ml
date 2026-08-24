(* EXPECT: crash B *)
type _ Effect.t += A : unit Effect.t
type _ Effect.t += B : unit Effect.t
let comp () = Effect.perform A; Effect.perform B
let inner () =
  Effect.Deep.try_with comp ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | A -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) }
let () = inner ()
