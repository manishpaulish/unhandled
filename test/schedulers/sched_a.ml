(* A mock scheduler, standing in for Eio. *)
type _ Effect.t += Yield : unit Effect.t
let yield () = Effect.perform Yield
let run f =
  Effect.Deep.try_with f ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | Yield -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) }
