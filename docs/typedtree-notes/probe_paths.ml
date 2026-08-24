open Typedtree
let () =
  let cmt = Cmt_format.read_cmt Sys.argv.(1) in
  match cmt.cmt_annots with
  | Implementation str ->
      let it = { Tast_iterator.default_iterator with
        expr = (fun sub e ->
          (match e.exp_desc with
           | Texp_ident (p, _, _) ->
               Printf.printf "IDENT      %s\n" (Path.name p)
           | Texp_construct (_, cd, _) ->
               (match cd.cstr_tag with
                | Types.Cstr_extension (p, _) ->
                    Printf.printf "EXTCONSTR  %-28s name=%s\n" (Path.name p) cd.cstr_name
                | _ -> Printf.printf "CONSTR     %s\n" cd.cstr_name)
           | _ -> ());
          Tast_iterator.default_iterator.expr sub e) } in
      it.structure it str
  | _ -> prerr_endline "not an implementation"
