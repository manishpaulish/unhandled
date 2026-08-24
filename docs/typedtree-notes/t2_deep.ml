(* Probe 2: non-syntactic handler via Effect.Deep.try_with, with a
   forwarding wildcard. The wildcard must NOT count as "handled". *)
type _ Effect.t += A : unit Effect.t
type _ Effect.t += B : unit Effect.t

let comp () = Effect.perform A; Effect.perform B

let only_handles_a () =
  Effect.Deep.try_with comp ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | A -> Some (fun (k : (c, _) Effect.Deep.continuation) ->
                       Effect.Deep.continue k ())
        | _ -> None) }
