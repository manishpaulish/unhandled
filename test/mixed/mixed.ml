(* A known effect escapes AND there is a call we cannot resolve. The old
   domain collapsed to Top and reported only the warning, hiding the escape. *)
type _ Effect.t += Emit : unit Effect.t
let leak () = Effect.perform Emit
let opaque f = f ()
let () = leak (); ignore (opaque (fun () -> 1))
