(* A different, incompatible scheduler, standing in for Riot. *)
type _ Effect.t += Tick : unit Effect.t
let tick () = Effect.perform Tick
let run f =
  Effect.Deep.try_with f ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | Tick -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) }
