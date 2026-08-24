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

(* Extension constructors can be re-exported by rebinding:

     module Effects = struct type _ Effect.t += Fork = Fiber.Fork end

   Both names denote the same runtime effect, but the typed tree reports the
   path actually written, and the uid differs too (verified: Orig.0 versus
   Reexport.0). Eio does exactly this, so without canonicalisation a handler
   written against one name would not be seen to discharge a perform written
   against the other, and every such program would be a false positive.

   The map is filled by a pre-pass over all units before any analysis runs. *)
let aliases : (string, string) Hashtbl.t = Hashtbl.create 32

let register_alias ~alias ~target =
  if not (String.equal alias target) then Hashtbl.replace aliases alias target

let canon id =
  let rec go id n =
    if n > 16 then id  (* defensive: a rebinding cycle cannot occur, but do not hang *)
    else match Hashtbl.find_opt aliases id with
      | Some t when not (String.equal t id) -> go t (n + 1)
      | _ -> id
  in
  go id 0

let of_path ~modname (p : Path.t) =
  let name = Path.name p in
  let id = match p with Path.Pident _ -> modname ^ "." ^ name | _ -> name in
  let id = canon id in
  let short =
    match String.rindex_opt id '.' with
    | Some i -> String.sub id (i + 1) (String.length id - i - 1)
    | None -> id
  in
  { id; short }

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
