type _ Effect.t += Job : unit Effect.t
let run () = Effect.perform Job
