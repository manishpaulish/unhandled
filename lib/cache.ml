(* Per-module cache, keyed by the digest of the .cmt file.

   The expensive part of a run is reading typed trees and building summaries;
   the fixpoint itself is cheap. Caching the built facts therefore turns a
   re-check of an unchanged project into approximately no work, which is what
   makes on-save use realistic.

   Correctness detail: alias registration is a side effect of building, so a
   cached entry has to carry the aliases its module contributed and replay them
   on a hit. Otherwise the second run would resolve fewer names than the first
   and silently report different findings. *)

type entry = {
  e_facts : Builder.module_facts;
  e_source : string option;
  e_effect_aliases : (string * string) list;
  e_module_aliases : (string * string) list;
}

(* Bump when anything in the cached types changes shape. A stale entry read
   back at the wrong type is a segfault, not an error. *)
let version = "unhandled-cache-v2"

let dir = ref ".unhandled-cache"
let set_dir d = dir := d

let enabled = ref true
let set_enabled b = enabled := b

let key_of_file file =
  try Some (Digest.to_hex (Digest.file file)) with _ -> None

let path_of key = Filename.concat !dir (key ^ ".bin")

let load file =
  if not !enabled then None
  else
  match key_of_file file with
  | None -> None
  | Some key -> (
      let p = path_of key in
      if not (Sys.file_exists p) then None
      else
        try
          let ic = open_in_bin p in
          let v : string = Marshal.from_channel ic in
          if v <> version then (close_in ic; None)
          else
            let e : entry = Marshal.from_channel ic in
            close_in ic;
            (* Replay the aliases this module contributed. *)
            List.iter
              (fun (alias, target) -> Effect_id.register_alias ~alias ~target)
              e.e_effect_aliases;
            List.iter
              (fun (k, target) -> Builder.register_module_alias_raw k target)
              e.e_module_aliases;
            Some e
        with _ -> None)

let store file (e : entry) =
  if not !enabled then ()
  else
  match key_of_file file with
  | None -> ()
  | Some key -> (
      try
        if not (Sys.file_exists !dir) then
          ignore (Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote !dir)));
        let oc = open_out_bin (path_of key) in
        Marshal.to_channel oc version [];
        Marshal.to_channel oc e [ Marshal.No_sharing ];
        close_out oc
      with _ -> ())
