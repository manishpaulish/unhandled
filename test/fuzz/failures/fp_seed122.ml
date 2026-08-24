type _ Effect.t += E0 : unit Effect.t
type _ Effect.t += E1 : unit Effect.t
type _ Effect.t += E2 : unit Effect.t
type _ Effect.t += E3 : unit Effect.t
let taken = ref true
let f0 () =
  (match
    (Effect.perform E3)
   with
   | () -> ()
   | effect E1, k -> Effect.Deep.continue k ()
   | effect E3, k -> Effect.Deep.continue k ()
  )
let f1 () =
  (match
    (Effect.perform E3)
   with
   | () -> ()
   | effect E1, k -> Effect.Deep.continue k ()
  )
let f2 () =
  (if !taken then
    (f0 ())
   else
    (Effect.perform E0)
  )
let () =
  (if !taken then
    (Effect.Deep.try_with (fun () ->
      (List.iter (fun _ ->
        (Effect.perform E0)
      ) [(); ()])
    ) ()
      { effc = (fun (type c) (eff : c Effect.t) ->
          match eff with
          | E0 -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
          | E2 -> Some (fun (k : (c, _) Effect.Deep.continuation) -> Effect.Deep.continue k ())
          | _ -> None) })
   else
    (match
      (List.iter (fun _ ->
        (Effect.perform E3)
      ) [(); ()])
     with
     | () -> ()
     | effect E1, k -> Effect.Deep.continue k ()
     | effect E2, k -> Effect.Deep.continue k ()
    )
  )
