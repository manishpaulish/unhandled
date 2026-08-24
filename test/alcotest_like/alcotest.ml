(* Stand-in with the same shape as the real Alcotest API, so the model can be
   exercised without the dependency. *)
type speed = [ `Quick | `Slow ]
type 'a test_case = string * speed * ('a -> unit)
let test_case n s f : 'a test_case = (n, s, f)
let run (_ : string) (_ : (string * 'a test_case list) list) = ()
