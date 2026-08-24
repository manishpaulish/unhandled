type _ Effect.t += E0 : unit Effect.t
type _ Effect.t += E1 : unit Effect.t
type _ Effect.t += E2 : unit Effect.t
type _ Effect.t += E3 : unit Effect.t
let taken = ref true
let f0 () =
  (Effect.perform E0)
let f1 () =
  (Effect.Deep.try_with (fun () ->
    (Effect.perform E0)
  ) ()
    { effc = (fun (type c) (eff : c Effect.t) ->
        match eff with
        | E1 -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
        | _ -> None) })
let f2 () =
  (
    (if !taken then
      (Effect.perform E0)
     else
      (f1 ())
    );
    (
      (f1 ());
      (Effect.perform E2)
    )
  )
let () =
  (if !taken then
    (Effect.Deep.try_with (fun () ->
      (if !taken then
        (Effect.perform E1)
       else
        (Effect.perform E0)
      )
    ) ()
      { effc = (fun (type c) (eff : c Effect.t) ->
          match eff with
          | E1 -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
          | _ -> None) })
   else
    (match
      (if !taken then
        (Effect.perform E3)
       else
        (f2 ())
      )
     with
     | () -> ()
     | effect E1, k -> Effect.Deep.continue k ()
     | effect E3, k -> Effect.Deep.continue k ()
    )
  )
