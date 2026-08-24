type _ Effect.t += E0 : unit Effect.t
type _ Effect.t += E1 : unit Effect.t
type _ Effect.t += E2 : unit Effect.t
type _ Effect.t += E3 : unit Effect.t
let taken = ref true
let f0 () =
  (Effect.perform E2)
let () =
  (match
    (if !taken then
      (if !taken then
        (f0 ())
       else
        (f0 ())
      )
     else
      (List.iter (fun _ ->
        (Effect.perform E0)
      ) [(); ()])
    )
   with
   | () -> ()
   | effect E2, k -> Effect.Deep.continue k ()
  )
