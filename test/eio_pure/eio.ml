(* Enough of Eio's shape to reproduce the call paths. Only the paths matter:
   the analyser resolves these by name against the scheduler model, exactly as
   it does for the real library, which ships no .cmt. *)
module Flow = struct
  module Pi = struct
    let source x = ignore x; "ops"
  end
end

module Stream = struct
  let create n = ref n
  let add t v = t := v
  let take t = !t
end

module Mutex = struct
  let use_rw _ f = f ()
end
