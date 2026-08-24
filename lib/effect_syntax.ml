(* Recognisers for the effect-related shapes of the typed tree.

   Every shape here was confirmed empirically against OCaml 5.3.0 with
   [ocamlc -dtypedtree]; see docs/TYPEDTREE-NOTES.md. Do not "simplify" these
   by matching on printed names: [Path.name] is the contract, the -dtypedtree
   rendering (which inserts '!') is not. *)

open Typedtree

(* What a handler discharges. [All] arises from a wildcard effect case, which
   genuinely handles every effect; [Only s] from explicit constructors. *)
type handled = All | Only of Effect_id.Set.t

let handled_join a b =
  match (a, b) with
  | All, _ | _, All -> All
  | Only x, Only y -> Only (Effect_id.Set.union x y)

let handled_empty = Only Effect_id.Set.empty

let subtract_handled set = function
  | All -> Effect_set.empty
  | Only h -> Effect_set.subtract set h

(* ------------------------------------------------------------------ perform *)

let perform_paths =
  [ "Stdlib.Effect.perform"; "Stdlib__Effect.perform"; "Effect.perform" ]

let is_perform (p : Path.t) = List.mem (Path.name p) perform_paths

(* Identity of the effect being performed, if it is a literal constructor.
   [None] means the effect value came from somewhere we cannot see, which the
   caller must turn into [Effect_set.top] rather than into "no effect". *)
let effect_of_expr ~modname (e : expression) =
  match e.exp_desc with
  | Texp_construct (_, cd, _) -> (
      match cd.cstr_tag with
      | Types.Cstr_extension (p, _) -> Some (Effect_id.of_path ~modname p)
      | _ -> None)
  | _ -> None

(* ------------------------------------------------------- effect-case patterns *)

let rec effect_of_pattern :
    type k. modname:string -> k general_pattern -> handled =
 fun ~modname p ->
  match p.pat_desc with
  | Tpat_construct (_, cd, _, _) -> (
      match cd.cstr_tag with
      | Types.Cstr_extension (path, _) ->
          Only (Effect_id.Set.singleton (Effect_id.of_path ~modname path))
      | _ -> handled_empty)
  | Tpat_any | Tpat_var _ -> All
  | Tpat_or (a, b, _) ->
      handled_join (effect_of_pattern ~modname a) (effect_of_pattern ~modname b)
  | Tpat_alias (p, _, _, _) -> effect_of_pattern ~modname p
  | Tpat_value p -> effect_of_pattern ~modname (p :> value general_pattern)
  | _ -> handled_empty

(* [Texp_match (e, computation_cases, effect_cases, _)] and
   [Texp_try (e, exn_cases, effect_cases)]: in 5.3 the effect cases live in
   their own list. A naive Tast_iterator walk cannot distinguish them from
   ordinary cases, which is why we override [expr] instead of using [case]. *)
let handled_of_effect_cases ~modname cases =
  List.fold_left
    (fun acc c -> handled_join acc (effect_of_pattern ~modname c.c_lhs))
    handled_empty cases

(* ------------------------------------------------ Effect.Deep / Effect.Shallow *)

(* Calls that install a handler, and the 0-based index of the handler-record
   argument. Deep.try_with comp arg h / match_with comp arg h /
   Shallow.continue_with k v h. *)
let handler_installers =
  [ ("Stdlib.Effect.Deep.try_with", 2);
    ("Stdlib.Effect.Deep.match_with", 2);
    ("Stdlib.Effect.Shallow.continue_with", 2);
    ("Stdlib.Effect.Shallow.discontinue_with", 2);
    ("Effect.Deep.try_with", 2);
    ("Effect.Deep.match_with", 2);
    ("Effect.Shallow.continue_with", 2) ]

let handler_arg_index (p : Path.t) =
  List.assoc_opt (Path.name p) handler_installers

let is_some_constructor (e : expression) =
  match e.exp_desc with
  | Texp_construct (_, cd, _) -> String.equal cd.cstr_name "Some"
  | _ -> false

let is_none_constructor (e : expression) =
  match e.exp_desc with
  | Texp_construct (_, cd, _) -> String.equal cd.cstr_name "None"
  | _ -> false

(* Which effects does an [effc] function actually handle?

   Idiomatic shape (confirmed on 5.3):
     fun (type c) (eff : c Effect.t) ->
       match eff with
       | A -> Some (fun k -> ...)     <- handled
       | _ -> None                    <- FORWARDED to the outer handler

   The wildcard arm returning [None] is the trap: it looks like a catch-all but
   handles nothing. Treating it as "handles everything" would make the analyser
   silently blind. Arms we cannot classify are treated as *not* handled, which
   can cost precision but never hides a bug. *)
let rec handled_of_effc ~modname (e : expression) =
  match e.exp_desc with
  | Texp_function (_, Tfunction_body body) -> handled_of_effc ~modname body
  | Texp_function (_, Tfunction_cases { cases; _ }) ->
      List.fold_left
        (fun acc c -> handled_join acc (classify_arm ~modname c))
        handled_empty cases
  | Texp_match (_, cases, _, _) ->
      List.fold_left
        (fun acc c -> handled_join acc (classify_arm ~modname c))
        handled_empty cases
  | Texp_let (_, _, body) -> handled_of_effc ~modname body
  | _ -> handled_empty

and classify_arm : type k. modname:string -> k case -> handled =
 fun ~modname c ->
  if is_some_constructor c.c_rhs then effect_of_pattern ~modname c.c_lhs
  else if is_none_constructor c.c_rhs then handled_empty
  else handled_empty

(* The handler argument is a record literal; find its [effc] field. *)
let handled_of_handler_record ~modname (e : expression) =
  match e.exp_desc with
  | Texp_record { fields; _ } ->
      Array.fold_left
        (fun acc (lbl, def) ->
          if String.equal lbl.Types.lbl_name "effc" then
            match def with
            | Overridden (_, ex) -> handled_join acc (handled_of_effc ~modname ex)
            | Kept _ -> acc
          else acc)
        handled_empty fields
  | _ -> handled_empty
