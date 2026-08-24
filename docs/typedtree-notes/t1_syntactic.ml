(* Probe 1: 5.3+ syntactic effect handler. *)
type _ Effect.t += Xchg : int -> int Effect.t

let comp () = Effect.perform (Xchg 0) + Effect.perform (Xchg 1)

let handled () =
  match comp () with
  | v -> v
  | effect (Xchg n), k -> Effect.Deep.continue k (n + 1)
