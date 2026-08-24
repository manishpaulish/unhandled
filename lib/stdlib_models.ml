(* Effect-polymorphic summaries for higher-order library functions.

   [List.iter f xs] performs exactly the effects of calling [f]. Without this,
   every idiomatic OCaml program degrades to "unknown effects" and the tool is
   useless on real code. Each entry lists the argument positions that the
   combinator applies. Values here are checked by test/corpus. *)

let combinators : (string * int list) list =
  [ ("Stdlib.List.iter", [ 0 ]); ("Stdlib.List.iteri", [ 0 ]);
    ("Stdlib.List.map", [ 0 ]); ("Stdlib.List.mapi", [ 0 ]);
    ("Stdlib.List.filter", [ 0 ]); ("Stdlib.List.filter_map", [ 0 ]);
    ("Stdlib.List.fold_left", [ 0 ]); ("Stdlib.List.fold_right", [ 0 ]);
    ("Stdlib.List.exists", [ 0 ]); ("Stdlib.List.for_all", [ 0 ]);
    ("Stdlib.List.concat_map", [ 0 ]); ("Stdlib.List.find_opt", [ 0 ]);
    ("Stdlib.Array.iter", [ 0 ]); ("Stdlib.Array.iteri", [ 0 ]);
    ("Stdlib.Array.map", [ 0 ]); ("Stdlib.Array.fold_left", [ 0 ]);
    ("Stdlib.Seq.iter", [ 0 ]); ("Stdlib.Seq.map", [ 0 ]);
    ("Stdlib.Option.iter", [ 0 ]); ("Stdlib.Option.map", [ 0 ]);
    ("Stdlib.Result.map", [ 0 ]); ("Stdlib.Fun.protect", [ 0 ]);
    ("Stdlib.Domain.spawn", [ 0 ]); ("Stdlib.Lazy.force", []);
    ("Stdlib.Hashtbl.iter", [ 0 ]); ("Stdlib.String.iter", [ 0 ]) ]

let is_combinator p = List.assoc_opt p combinators

(* Functions known to perform no effects: avoids Top for ubiquitous calls.
   Deliberately conservative and short; anything absent is treated as unknown. *)
let pure_prefixes =
  [ "Stdlib.+"; "Stdlib.-"; "Stdlib.*"; "Stdlib./"; "Stdlib.="; "Stdlib.<>";
    "Stdlib.<"; "Stdlib.>"; "Stdlib.<="; "Stdlib.>="; "Stdlib.^";
    "Stdlib.@"; "Stdlib.!"; "Stdlib.:="; "Stdlib.ref"; "Stdlib.incr";
    "Stdlib.decr"; "Stdlib.not"; "Stdlib.fst"; "Stdlib.snd";
    "Stdlib.string_of_int"; "Stdlib.int_of_string"; "Stdlib.print_endline";
    "Stdlib.print_string"; "Stdlib.prerr_endline"; "Stdlib.raise";
    "Stdlib.failwith"; "Stdlib.ignore"; "Stdlib.succ"; "Stdlib.pred";
    "Stdlib.List.length"; "Stdlib.List.rev"; "Stdlib.List.append";
    "Stdlib.List.nth"; "Stdlib.List.hd"; "Stdlib.List.tl";
    "Stdlib.String.length"; "Stdlib.String.concat"; "Stdlib.String.sub";
    "Stdlib.Printf.printf"; "Stdlib.Printf.sprintf"; "Stdlib.Format.printf";
    "Stdlib.Effect.Deep.continue"; "Stdlib.Effect.Deep.discontinue";
    "Stdlib.Effect.Shallow.fiber" ]

let is_known_pure p = List.mem p pure_prefixes
