(* Eio does exactly this: re-export the effect under a public name. *)
module Effects = struct
  type _ Effect.t += Fork = Orig.Fork
end
