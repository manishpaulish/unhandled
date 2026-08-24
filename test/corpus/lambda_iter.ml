(* EXPECT: crash Emit *)
(* Anonymous lambda passed through a combinator. *)
type _ Effect.t += Emit : int -> unit Effect.t
let () = List.iter (fun x -> Effect.perform (Emit x)) [1; 2; 3]
