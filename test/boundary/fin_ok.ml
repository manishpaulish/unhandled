(* A finaliser that performs nothing is fine. *)
let () = Gc.finalise (fun _ -> print_string "") (ref 0)
let () = Gc.full_major ()
