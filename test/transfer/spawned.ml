(* The handler encloses the spawn site, not the spawned code. Domain.spawn
   starts a fresh stack, so Work escapes inside the new domain even though a
   handler is visibly wrapped around the call. *)
type _ Effect.t += Work : unit Effect.t
let job () = Effect.perform Work
let () =
  match Domain.join (Domain.spawn job) with
  | () -> ()
  | effect Work, k -> Effect.Deep.continue k ()
