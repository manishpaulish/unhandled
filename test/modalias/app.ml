(* Called through a local module alias. The path is "W.run", which matched no
   summary before aliases were resolved, so the effect went unseen. *)
module W = Worker
let () = W.run ()
