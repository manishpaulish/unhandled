module Mutex = struct
  let use_rw _ f = f ()
end
