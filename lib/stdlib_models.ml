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
    ("Stdlib.Hashtbl.iter", [ 0 ]); ("Stdlib.String.iter", [ 0 ]);
    (* Third-party combinators, added because the first ecosystem sweep named
       them as the dominant cause of blindness: Alcotest.test_case and
       Alcotest.run accounted for roughly 79 of 107 unknown-effect warnings.
       Every test executable was opaque, and test code is exactly where the
       documented crashes live.

       The test body is attributed where the case is constructed rather than
       where the suite runs. Both happen during the same module
       initialisation, so the total for the module is right, and it is what
       makes the body visible at all. *)
    ("Alcotest.test_case", [ 2 ]);
    ("Alcotest.test_case_sync", [ 2 ]);
    ("Alcotest.run", []);
    ("Alcotest.run_with_args", []);
    ("Alcotest.testable", []);
    ("Alcotest.check", []);
    ("Alcotest.check'", []);
    ("Alcotest.fail", []);
    ("Alcotest.failf", []) ]

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
    "Stdlib.Effect.Shallow.fiber";
    (* Domain is excluded from the blanket stdlib rule because spawn runs
       caller code; the rest of the module does not. *)
    "Stdlib.Domain.join"; "Stdlib.Domain.self"; "Stdlib.Domain.cpu_relax";
    "Stdlib.Domain.recommended_domain_count"; "Stdlib.Domain.is_main_domain";
    "Stdlib.Thread.join"; "Stdlib.Thread.self"; "Thread.join"; "Thread.self" ]

(* Modules whose functions can run caller-supplied code, and therefore can
   perform caller effects. Everything else in the standard library performs no
   *user-defined* effect, which is what we are tracking. This assumption is
   what keeps ordinary code from degrading to "unknown effects" on every call
   to Printf or Gc; it is stated in docs/LIMITATIONS.md. *)
let may_run_user_code = [ "Stdlib.Effect."; "Stdlib.Lazy."; "Stdlib.Domain." ]

(* Third-party libraries that transform data and never call back into
   caller-supplied code, so they cannot perform a caller's effect. Kept short
   and explicit: this is an assumption about someone else's library, and a
   wrong entry here hides bugs rather than merely adding noise. *)
let pure_library_prefixes =
  [ "Yojson."; "Re."; "Fmt."; "Astring."; "Uutf."; "Sexplib0.";
    (* Unix dominated the blindness list on the second sweep (rmdir, mkdir,
       waitpid, gettimeofday, sleepf, kill, environment, close, openfile).
       These are syscall wrappers: they do not call back into caller-supplied
       code, so they cannot perform a caller's effect. *)
    "Unix."; "Str."; "Ptime." ]

let starts_with pre s =
  String.length s >= String.length pre && String.sub s 0 (String.length pre) = pre

let is_known_pure p =
  List.mem p pure_prefixes
  || List.exists (fun m -> starts_with m p) pure_library_prefixes
  || (starts_with "Stdlib." p
      && (not (List.exists (fun m -> starts_with m p) may_run_user_code))
      && is_combinator p = None)
