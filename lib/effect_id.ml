(* Identity of an effect, i.e. of an extension constructor of [_ Effect.t].

   Empirical note (see docs/TYPEDTREE-NOTES.md): for an effect declared in the
   module under analysis, [Path.name] of the [Cstr_extension] path is the bare
   constructor name ("Emit"), because it is a [Pident]. Two modules can each
   declare [Emit]; those are *different* effects. We therefore qualify bare
   paths with the defining module name. Paths that are already qualified
   ([Pdot]) are global and used as-is. *)

type t = { id : string; short : string }

let compare a b = String.compare a.id b.id
let equal a b = String.equal a.id b.id
let to_string t = t.id
let short t = t.short

let of_path ~modname (p : Path.t) =
  let name = Path.name p in
  let id = match p with Path.Pident _ -> modname ^ "." ^ name | _ -> name in
  { id; short = name }

let of_string id =
  let short =
    match String.rindex_opt id '.' with
    | Some i -> String.sub id (i + 1) (String.length id - i - 1)
    | None -> id
  in
  { id; short }

module Set = Set.Make (struct
  type nonrec t = t
  let compare = compare
end)

module Map = Map.Make (struct
  type nonrec t = t
  let compare = compare
end)
