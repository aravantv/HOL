(* Functions to invoke the Yices SMT solver *)

structure Yices = struct

  (* computes the eta-long form of a term (i.e., every variable/constant is
     applied to sufficiently many arguments, as determined by its type),
     recursively descending into subterms *)
  fun eta_long tm =
    Feedback.Raise (Feedback.mk_HOL_ERR "Yices" "eta_long"
      "not implemented yet")

  (* translation of HOL terms into Yices' input syntax -- currently, all types
     except 'bool', 'num', 'int', 'real' and 'fun' and all terms except the
     usual Boolean connectives, certain numeric literals and arithmetic
     operators, and function application are treated as uninterpreted *)
  fun term_to_Yices tm =
  let
    val _ = if Term.type_of tm <> Type.bool then
        Feedback.Raise (Feedback.mk_HOL_ERR "Yices" "term_to_Yices"
          "term supplied is not of type bool")
      else ()
    (* returns a dictionary (possibly) expanded with new (subterm, var)
       assignments, the next "fresh" index, and a string list that, when
       concatenated, gives the Yices representation of 'tm' -- 'acc' is of type
       '(term, term) Redblackmap.dict * int' *)
    fun translate (acc, tm) =
      (* Boolean connectives *)
      if Term.same_const tm boolSyntax.T then
        (acc, ["true"])
      else if Term.same_const tm boolSyntax.F then
        (acc, ["false"])
      else if boolSyntax.is_eq tm then
        let val (t1, t2) = boolSyntax.dest_eq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(= " :: s1 @ " " :: s2 @ [")"])
        end
      else if boolSyntax.is_imp_only tm then
        let val (t1, t2) = boolSyntax.dest_imp_only tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(=> " :: s1 @ " " :: s2 @ [")"])
        end
      else if boolSyntax.is_conj tm then
        let val ts = boolSyntax.strip_conj tm
            val (acc', sss) = Lib.foldl_map translate (acc, ts)
        in
          (acc', "(and " :: Lib.separate " " (List.concat sss) @ [")"])
        end
      else if boolSyntax.is_disj tm then
        let val ts = boolSyntax.strip_disj tm
            val (acc', sss) = Lib.foldl_map translate (acc, ts)
        in
          (acc', "(or " :: Lib.separate " " (List.concat sss) @ [")"])
        end
      else if boolSyntax.is_neg tm then
        let val t = boolSyntax.dest_neg tm
            val (acc', s) = translate (acc, t)
        in
          (acc', "(not " :: s @ [")"])
        end
      else if boolSyntax.is_cond tm then
        let val (t1, t2, t3) = boolSyntax.dest_cond tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
            val (a3, s3) = translate (a2, t3)
        in
          (a3, "(ite " :: s1 @ " " :: s2 @ " " :: s3 @ [")"])
        end
      else if boolSyntax.is_bool_case tm then
        let val (t1, t2, t3) = boolSyntax.dest_bool_case tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
            val (a3, s3) = translate (a2, t3)
        in
          (* note that the argument order is different from the 'is_cond'
             case above *)
          (a3, "(ite " :: s3 @ " " :: s1 @ " " :: s2 @ [")"])
        end
      (* numerals *)
      else if numSyntax.is_numeral tm then
        let val n = numSyntax.dest_numeral tm
        in
          (acc, [Arbnum.toString n])
        end
      else if intSyntax.is_int_literal tm then
        let val i = intSyntax.int_of_term tm
            val s = Arbint.toString i
        in
          (acc, [String.substring (s, 0, String.size s - 1)])
        end
      else if realSyntax.is_real_literal tm then
        let val i = realSyntax.int_of_term tm
            val s = Arbint.toString i
        in
          (acc, [String.substring (s, 0, String.size s - 1)])
        end
      (* Yices 1.0.18 only supports linear arithmetic; we could check for
         linearity below (but Yices will check again anyway) *)
      (* arithmetic operators: +, -, *, /, div, mod *)
      (* num *)
      else if numSyntax.is_plus tm then
        let val (t1, t2) = numSyntax.dest_plus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(+ " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_minus tm then
        let val (t1, t2) = numSyntax.dest_minus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(- " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_mult tm then
        let val (t1, t2) = numSyntax.dest_mult tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(* " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_div tm then
        let val (t1, t2) = numSyntax.dest_div tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(div " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_mod tm then
        let val (t1, t2) = numSyntax.dest_mod tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(mod " :: s1 @ " " :: s2 @ [")"])
        end
      (* int *)
      else if intSyntax.is_negated tm then
        let val t = intSyntax.dest_negated tm
            val (acc', s) = translate (acc, t)
        in
          (acc', "(- 0 " :: s @ [")"])
        end
      else if intSyntax.is_plus tm then
        let val (t1, t2) = intSyntax.dest_plus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(+ " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_minus tm then
        let val (t1, t2) = intSyntax.dest_minus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(- " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_mult tm then
        let val (t1, t2) = intSyntax.dest_mult tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(* " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_div tm then
        let val (t1, t2) = intSyntax.dest_div tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(div " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_mod tm then
        let val (t1, t2) = intSyntax.dest_mod tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(mod " :: s1 @ " " :: s2 @ [")"])
        end
      (* real *)
      else if realSyntax.is_negated tm then
        let val t = realSyntax.dest_negated tm
            val (acc', s) = translate (acc, t)
        in
          (acc', "(- 0 " :: s @ [")"])
        end
      else if realSyntax.is_plus tm then
        let val (t1, t2) = realSyntax.dest_plus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(+ " :: s1 @ " " :: s2 @ [")"])
        end
      else if realSyntax.is_minus tm then
        let val (t1, t2) = realSyntax.dest_minus tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(- " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_mult tm then
        let val (t1, t2) = intSyntax.dest_mult tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(* " :: s1 @ " " :: s2 @ [")"])
        end
      else if realSyntax.is_div tm then
        let val (t1, t2) = realSyntax.dest_div tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (* note that Yices uses '/' for division on reals, not 'div' *)
          (a2, "(/ " :: s1 @ " " :: s2 @ [")"])
        end
      (* arithmetic inequalities: <, <=, >, >= *)
      (* num *)
      else if numSyntax.is_less tm then
        let val (t1, t2) = numSyntax.dest_less tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(< " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_leq tm then
        let val (t1, t2) = numSyntax.dest_leq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(<= " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_greater tm then
        let val (t1, t2) = numSyntax.dest_greater tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(> " :: s1 @ " " :: s2 @ [")"])
        end
      else if numSyntax.is_geq tm then
        let val (t1, t2) = numSyntax.dest_geq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(>= " :: s1 @ " " :: s2 @ [")"])
        end
      (* int *)
      else if intSyntax.is_less tm then
        let val (t1, t2) = intSyntax.dest_less tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(< " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_leq tm then
        let val (t1, t2) = intSyntax.dest_leq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(<= " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_great tm then
        let val (t1, t2) = intSyntax.dest_great tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(> " :: s1 @ " " :: s2 @ [")"])
        end
      else if intSyntax.is_geq tm then
        let val (t1, t2) = intSyntax.dest_geq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(>= " :: s1 @ " " :: s2 @ [")"])
        end
      (* real *)
      else if realSyntax.is_less tm then
        let val (t1, t2) = realSyntax.dest_less tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(< " :: s1 @ " " :: s2 @ [")"])
        end
      else if realSyntax.is_leq tm then
        let val (t1, t2) = realSyntax.dest_leq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(<= " :: s1 @ " " :: s2 @ [")"])
        end
      else if realSyntax.is_great tm then
        let val (t1, t2) = realSyntax.dest_great tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(> " :: s1 @ " " :: s2 @ [")"])
        end
      else if realSyntax.is_geq tm then
        let val (t1, t2) = realSyntax.dest_geq tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(>= " :: s1 @ " " :: s2 @ [")"])
        end
      (* function application *)
      else if Term.is_comb tm then
        (* Yices considers "-> X Y Z" and "-> X (-> Y Z)" different types. We
           use the latter only. Moreover, Yices does not support partial
           function application. *)
        (* TODO: call eta_long *)
        let val (t1, t2) = Term.dest_comb tm
            val (a1, s1) = translate (acc, t1)
            val (a2, s2) = translate (a1, t2)
        in
          (a2, "(" :: s1 @ " " :: s2 @ [")"])
        end
      else (* replace all other terms with a variable *)
        (* we even replace variables, to make sure there are no name clashes
           with either (i) variables generated by us, or (ii) reserved Yices
           names *)
        let val (dict, fresh) = acc
        in
          case Redblackmap.peek (dict, tm) of
            SOME var => (acc, [Lib.fst (Term.dest_var var)])
          | NONE => let val name = "v" ^ Int.toString fresh
                        val var = Term.mk_var (name, Term.type_of tm)
                    in
                      ((Redblackmap.insert (dict, tm, var), fresh + 1), [name])
                    end
        end
    val empty_dict = Redblackmap.mkDict Term.compare
    val ((dict, _), ss_tm) = translate ((empty_dict, 0), tm)
    (* we need to declare the variables in 'dict' to Yices, and for that, we
       need to declare their types to Yices first ... so here we go: *)
    (* similar to 'translate', but for types; we map these to a string
       directly, rather than to a type variable *)
    fun translate_type (acc, ty) =
    let
      fun uninterpreted_type ((ty_dict, fresh), ty) =
        case Redblackmap.peek (ty_dict, ty) of
          SOME s => ((ty_dict, fresh), s)
        | NONE => let val s = "t" ^ Int.toString fresh
                  in
                    ((Redblackmap.insert (ty_dict, ty, s), fresh + 1), s)
                  end
    in
      if Type.is_type ty then
        let val {Thy, Tyop, Args} = Type.dest_thy_type ty
        in
          if ty = Type.bool then
            (acc, "bool")
          else if ty = numSyntax.num then
            (acc, "nat")
          else if ty = intSyntax.int_ty then
            (acc, "int")
          else if ty = realSyntax.real_ty then
            (acc, "real")
          else if Thy = "min" andalso Tyop = "fun" then
            (* Yices considers "-> X Y Z" and "-> X (-> Y Z)" different types.
               We use the latter only. *)
            (* 'fun' is expected to have arity 2 *)
            let val ty1 = hd Args
                val ty2 = hd (tl Args)
                val (a1, s1) = translate_type (acc, ty1)
                val (a2, s2) = translate_type (a1, ty2)
            in
              (a2, "(-> " ^ s1 ^ " " ^ s2 ^ ")")
            end
          else uninterpreted_type (acc, ty)
        end
      else uninterpreted_type (acc, ty)
    end
    val empty_ty_dict = Redblackmap.mkDict Type.compare
    (* slightly tricky: we collect all variable definitions in 'defs', and
       while doing so we build the type dictionary 'ty_dict' *)
    val ((ty_dict, _), defs) = Redblackmap.foldr (fn (_, var, (ty_acc, defs)) =>
      let val (name, ty) = Term.dest_var var
          val (ty_acc', ty_name) = translate_type (ty_acc, ty)
      in
        (ty_acc', "(define " ^ name ^ "::" ^ ty_name ^ ")\n" :: defs)
      end) ((empty_ty_dict, 0), []) dict
    (* now add all type definitions to the collection of definitions *)
    val all_defs = Redblackmap.foldr (fn (_, s, all_defs) =>
      "(define-type " ^ s ^ ")\n" :: all_defs) defs ty_dict
  in
    (* The order of variable and type definitions depends on the order of terms
       and types in 'dict' and 'ty_dict', respectively (because of the use of
       'Redblackmap.foldr' above), and thus may seem arbitrary in the Yices
       file (except that type definitions always come before variable
       definitions). *)
    all_defs @ "(assert " :: ss_tm @ [")\n(check)\n"]
  end

  (* returns true if Yices reported "sat", false if Yices reported "unsat" *)
  fun is_sat path =
    let val instream = TextIO.openIn path
        val line     = TextIO.inputLine instream
    in
      TextIO.closeIn instream;
      if line = "sat\n" then
        true
      else if line = "unsat\n" then
        false
      else
        Feedback.Raise (Feedback.mk_HOL_ERR "Yices" "is_sat"
          "satisfiability unknown (solver not installed/problem too hard?)")
    end

  (* Yices 1.0.18 *)
  local val infile = "input.yices"
        val outfile = "output.yices"
  in
    val YicesOracle = SolverSpec.make_solver
      ("Yices 1.0.18",
       "yices " ^ infile ^ " > " ^ outfile,
       term_to_Yices,
       infile,
       [outfile],
       (fn () => is_sat outfile),
       NONE,  (* no models *)
       NONE)  (* no proofs *)
  end

end
