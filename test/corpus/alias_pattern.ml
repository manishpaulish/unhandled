(* EXPECT: clean *)
(* An effect case may bind its pattern with [as]. The handler still discharges
   the effect, so anything that fails to look through [Tpat_alias] reports a
   false escape here. This is a regression test for the compat shim: 5.3 and
   5.4 give [Tpat_alias] different arities, so the match lives in [Compat] and
   nothing else in the tree would notice if it started returning [None]. *)
type _ Effect.t += Ping : unit Effect.t

let ping () = Effect.perform Ping

let () =
  match ping () with
  | () -> print_endline "done"
  | effect (Ping as _e), k -> Effect.Deep.continue k ()
