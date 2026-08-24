(* Looks fine. Compiles fine. Guaranteed crash: A's effect under B's runtime. *)
let () = Sched_b.run (fun () -> Sched_a.yield ())
