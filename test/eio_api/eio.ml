module Mutex = struct let use_rw _ f = f () end
module Switch = struct let run f = f () end
