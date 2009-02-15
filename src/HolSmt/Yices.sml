(* Copyright (c) 2009 Tjark Weber. All rights reserved. *)

(* Functions to invoke the Yices SMT solver *)

structure Yices = struct

  (* computes the eta-long form of a term (i.e., every variable/constant is
     applied to sufficiently many arguments, as determined by its type),
     recursively descending into subterms *)
  fun eta_long tm =
    Feedback.Raise (Feedback.mk_HOL_ERR "Yices" "eta_long"
      "not implemented yet")

  (* Yices 1.0.18 only supports linear arithmetic; we do not check for
     linearity (Yices will check again anyway) *)

  (* translation of HOL terms into Yices' input syntax -- currently, all types
     and terms except the following are treated as uninterpreted:
     - types: 'bool', 'num', 'int', 'real', 'fun', 'prod'
     - terms: Boolean connectives (T, F, ==>, /\, \/, ~, if-then-else,
              bool-case), quantifiers (!, ?), numeric literals, arithmetic
              operators (SUC, +, -, *, /, ~, DIV, MOD, ABS, MIN, MAX), function
              application, lambda abstraction, tuple selectors FST and SND *)

  val Yices_types = [
    (("min", "bool"), "bool", ""),
    (("num", "num"), "nat", ""),
    (("integer", "int"), "int", ""),
    (("realax", "real"), "real", ""),
    (* Yices considers "-> X Y Z" and "-> X (-> Y Z)" different types. We use
       the latter only. *)
    (("min", "fun"), "->", ""),
    (* Likewise, we only use tuples of arity 2. *)
    (("pair", "prod"), "tuple", "")
  ]

  (* many HOL operators can be translated by simply mapping them to the
     corresponding Yices operator, or to a function that we define in Yices
     ourselves (the last component of each tuple is the function's
     definition) *)
  val Yices_operator_terms = [
    (boolSyntax.T, "true", ""),
    (boolSyntax.F, "false", ""),
    (boolSyntax.equality, "=", ""),
    (boolSyntax.implication, "=>", ""),
    (boolSyntax.conjunction, "and", ""),
    (boolSyntax.disjunction, "or", ""),
    (boolSyntax.negation, "not", ""),
    (boolSyntax.conditional, "ite", ""),
    (numSyntax.suc_tm, "+ 1", ""),
    (numSyntax.plus_tm, "+", ""),
    (* in HOL, 's1 < s2' implies 's1 - s2 = 0' for naturals; Yices however
       would consider 's1 - s2' a negative integer *)
    (numSyntax.minus_tm, "hol_num_minus",
       "(define hol_num_minus::(-> nat nat nat) " ^
         "(lambda (x::nat y::nat) (ite (< x y) 0 (- x y))))"),
    (numSyntax.mult_tm, "*", ""),
    (* 'x div 0' and 'x mod 0' are unspecified in HOL, but not type-correct in
       Yices and, therefore, treated quite weirdly: Yices claims that, e.g.,
       'x = 42 div 0' is unsatisfiable. Similar for div/mod on integers. *)
    (numSyntax.div_tm, "hol_num_div",
       "(define hol_num_div0::(-> nat nat))\n" ^
         "(define hol_num_div::(-> nat nat nat) (lambda (x::nat y::nat) " ^
         "(ite (= y 0) (hol_num_div0 x) (div x y))))"),
    (numSyntax.mod_tm, "hol_num_mod",
       "(define hol_num_mod0::(-> nat nat))\n" ^
         "(define hol_num_mod::(-> nat nat nat) (lambda (x::nat y::nat) " ^
         "(ite (= y 0) (hol_num_mod0 x) (mod x y))))"),
    (numSyntax.min_tm, "hol_num_min",
       "(define hol_num_min::(-> nat nat nat) (lambda (x::nat y::nat) " ^
         "(ite (< x y) x y)))"),
    (numSyntax.max_tm, "hol_num_max",
       "(define hol_num_max::(-> nat nat nat) (lambda (x::nat y::nat) " ^
         "(ite (< x y) y x)))"),
    (numSyntax.less_tm, "<", ""),
    (numSyntax.leq_tm, "<=", ""),
    (numSyntax.greater_tm, ">", ""),
    (numSyntax.geq_tm, ">=", ""),
    (intSyntax.negate_tm, "- 0", ""),
    (intSyntax.absval_tm, "hol_int_abs",
       "(define hol_int_abs::(-> int int) (lambda (x::int) " ^
         "(ite (< x 0) (- 0 x) x)))"),
    (intSyntax.plus_tm, "+", ""),
    (intSyntax.minus_tm, "-", ""),
    (intSyntax.mult_tm, "*", ""),
    (intSyntax.div_tm, "hol_int_div",
       "(define hol_int_div0::(-> int int))\n" ^
         "(define hol_int_div::(-> int int int) (lambda (x::int y::int) " ^
         "(ite (= y 0) (hol_int_div0 x) (div x y))))"),
    (intSyntax.mod_tm, "hol_int_mod",
       "(define hol_int_mod0::(-> int int))\n" ^
         "(define hol_int_mod::(-> int int int) (lambda (x::int y::int) " ^
         "(ite (= y 0) (hol_int_mod0 x) (mod x y))))"),
    (intSyntax.min_tm, "hol_int_min",
       "(define hol_int_min::(-> int int int) (lambda (x::int y::int) " ^
         "(ite (< x y) x y)))"),
    (intSyntax.max_tm, "hol_int_max",
       "(define hol_int_max::(-> int int int) (lambda (x::int y::int) " ^
         "(ite (< x y) y x)))"),
    (intSyntax.less_tm, "<", ""),
    (intSyntax.leq_tm, "<=", ""),
    (intSyntax.great_tm, ">", ""),
    (intSyntax.geq_tm, ">=", ""),
    (realSyntax.negate_tm, "- 0", ""),
    (realSyntax.absval_tm, "hol_real_abs",
       "(define hol_real_abs::(-> real real) (lambda (x::real) " ^
         "(ite (< x 0) (- 0 x) x)))"),
    (realSyntax.plus_tm, "+", ""),
    (realSyntax.minus_tm, "-", ""),
    (realSyntax.mult_tm, "*", ""),
    (* note that Yices uses '/' for division on reals, not 'div'; Yices will
       fail if the second argument is 0 or not a numeral *)
    (realSyntax.div_tm, "/", ""),
    (realSyntax.min_tm, "hol_real_min",
       "(define hol_real_min::(-> real real real) (lambda (x::real y::real) " ^
         "(ite (< x y) x y)))"),
    (realSyntax.max_tm, "hol_real_max",
       "(define hol_real_max::(-> real real real) (lambda (x::real y::real) " ^
         "(ite (< x y) y x)))"),
    (realSyntax.less_tm, "<", ""),
    (realSyntax.leq_tm, "<=", ""),
    (realSyntax.great_tm, ">", ""),
    (realSyntax.geq_tm, ">=", ""),
    (pairSyntax.comma_tm, "mk-tuple", "")
  ]

  (* binders need to be treated differently from the operators in
     'Yices_operator_terms' *)
  val Yices_binder_terms = [
    (boolSyntax.strip_forall, "forall"),
    (boolSyntax.strip_exists, "exists"),
    (* Yices considers "-> X Y Z" and "-> X (-> Y Z)" different types. We use
       the latter only. *)
    (fn t => let val (var, body) = Term.dest_abs t
             in
               ([var], body)
             end handle Feedback.HOL_ERR _ => ([], t), "lambda")
  ]

  (* ty_dict: dictionary that maps types to names
     fresh: next fresh index to generate a new type name
     defs: list of auxiliary Yices definitions *)
  fun translate_type (acc, ty) =
    let
      fun uninterpreted_type (acc as (ty_dict, fresh, defs), ty) =
        case Redblackmap.peek (ty_dict, ty) of
          SOME s => (acc, s)
        | NONE => let val name = "t" ^ Int.toString fresh
                      val ty_dict' = Redblackmap.insert (ty_dict, ty, name)
                      val defs' = "(define-type " ^ name ^ ")" :: defs
                  in
                    ((ty_dict', fresh + 1, defs'), name)
                  end
    in
      if Type.is_type ty then
        (* check table of types *)
        let val {Thy, Tyop, Args} = Type.dest_thy_type ty
        in
          case List.find (fn ((thy, tyop), _, _) =>
                 thy = Thy andalso tyop = Tyop) Yices_types of
            SOME (_, name, def) =>
            let val ((ty_dict, fresh, defs), yices_Args) = Lib.foldl_map
                  translate_type (acc, Args)
                val defs' = if def = "" orelse Lib.mem def defs then defs else
                  def :: defs
                val yices_Args' = String.concat (Lib.separate " " yices_Args)
            in
              ((ty_dict, fresh, defs'),
               if yices_Args = [] then name
               else "(" ^ name ^ " " ^ yices_Args' ^ ")")
            end
          | NONE =>
            uninterpreted_type (acc, ty)
        end
      else uninterpreted_type (acc, ty)
    end

  (* dict: dictionary that maps terms to names
     fresh: next fresh index to generate a new name
     ty_dict: cf. translate_type
     ty_fresh: cf. translate_type
     defs: list of auxiliary Yices definitions *)
  fun translate_term (acc, tm) =
    (* numerals *)
    if numSyntax.is_numeral tm then
      let val n = numSyntax.dest_numeral tm
      in
        (acc, Arbnum.toString n)
      end
    else if intSyntax.is_int_literal tm then
      let val i = intSyntax.int_of_term tm
          val s = Arbint.toString i
      in
        (acc, String.substring (s, 0, String.size s - 1))
      end
    else if realSyntax.is_real_literal tm then
      let val i = realSyntax.int_of_term tm
          val s = Arbint.toString i
      in
        (acc, String.substring (s, 0, String.size s - 1))
      end
    (* bool_case *)
    (* cannot be defined as a function in Yices because it is polymorphic *)
    else if boolSyntax.is_bool_case tm then
      let val (t1, t2, t3) = boolSyntax.dest_bool_case tm
          val (acc, s1) = translate_term (acc, t1)
          val (acc, s2) = translate_term (acc, t2)
          val (acc, s3) = translate_term (acc, t3)
      in
        (acc, "(ite " ^ s3 ^ " " ^ s1 ^ " " ^ s2 ^ ")")
      end
    (* FST *)
    (* cannot be defined as a function in Yices because it is polymorphic *)
    else if pairSyntax.is_fst tm then
      let val t1 = pairSyntax.dest_fst tm
          val (acc, s1) = translate_term (acc, t1)
      in
        (acc, "(select " ^ s1 ^ " 1)")
      end
    (* SND *)
    (* cannot be defined as a function in Yices because it is polymorphic *)
    else if pairSyntax.is_snd tm then
      let val t1 = pairSyntax.dest_snd tm
          val (acc, s1) = translate_term (acc, t1)
      in
        (acc, "(select " ^ s1 ^ " 2)")
      end
    (* binders *)
    else
      case Lib.get_first (fn (strip_fn, name) =>
        case strip_fn tm of
          ([], _) => NONE (* not this binder *)
        | (vars, body) =>
          let val typs = List.map Term.type_of vars
              (* We must gather Yices definitions for all types, and for all
                 terms in the body with the exception of bound vars. Still,
                 bound vars must not be mapped to names used elsewhere (to
                 avoid accidental capture). Also note that not all bound vars
                 need to occur in the body. *)
              val (dict, fresh, ty_dict, ty_fresh, defs) = acc
              (* translate types of bound variables separately, because we
                 don't want to discard their definitions *)
              val (ty_acc, yices_typs) = Lib.foldl_map translate_type
                ((ty_dict, ty_fresh, defs), typs)
              val (ty_dict, ty_fresh, defs) = ty_acc
              (* translate bound variables; make sure they are mapped to fresh
                 names; their types have just been translated already  *)
              val empty_dict = Redblackmap.mkDict Term.compare
              val (bound_acc, yices_vars) = Lib.foldl_map translate_term
                ((empty_dict, fresh, ty_dict, ty_fresh, []), vars)
              val (bound_dict, fresh, _, _, _) = bound_acc
              (* translate the body, with bound variables mapped properly *)
              fun union dict1 dict2 =
                Redblackmap.foldl (fn (t, s, d) => Redblackmap.insert (d, t, s))
                  dict1 dict2
              val acc = (union dict bound_dict, fresh, ty_dict, ty_fresh, defs)
              val (acc, yices_body) = translate_term (acc, body)
              val (body_dict, fresh, ty_dict, ty_fresh, defs) = acc
              (* discard the mapping of bound variables, but keep other term
                 mappings that result from translation of the body *)
              fun diff dict1 dict2 =
                Redblackmap.foldl (fn (t, _, d) =>
                  (Lib.fst o Redblackmap.remove) (d, t)) dict1 dict2
              val dict = union dict (diff body_dict bound_dict)
              val yices_bounds = String.concat (Lib.separate " " (List.map
                (fn (v, t) => v ^ "::" ^ t) (Lib.zip yices_vars yices_typs)))
            in
              SOME ((dict, fresh, ty_dict, ty_fresh, defs),
                "(" ^ name ^ " (" ^ yices_bounds ^ ") " ^ yices_body ^ ")")
            end) Yices_binder_terms of
        SOME result => result
      | NONE =>
    (* operators *)
      let val (rator, rands) = boolSyntax.strip_comb tm
      in
        case List.find (fn (t, _, _) => Term.same_const t rator)
            Yices_operator_terms of
          SOME (_, name, def) =>
          let val (acc', yices_rands) = Lib.foldl_map
                translate_term (acc, rands)
              val (dict, fresh, ty_dict, ty_fresh, defs) = acc'
              val defs' = if def = "" orelse Lib.mem def defs then defs else
                def :: defs
              val yices_rands' = String.concat (Lib.separate " " yices_rands)
          in
            ((dict, fresh, ty_dict, ty_fresh, defs'),
             if yices_rands = [] then name
             else "(" ^ name ^ " " ^ yices_rands' ^ ")")
          end
        | NONE =>
          (* function application *)
          if Term.is_comb tm then
          (* Yices considers "-> X Y Z" and "-> X (-> Y Z)" different types. We
             use the latter only. *)
            let val (t1, t2) = Term.dest_comb tm
                val (acc, s1) = translate_term (acc, t1)
                val (acc, s2) = translate_term (acc, t2)
            in
              (acc, "(" ^ s1 ^ " " ^ s2 ^ ")")
            end
          else (* replace all other terms with a variable *)
          (* we even replace variables, to make sure there are no name clashes
             with either (i) variables generated by us, or (ii) reserved Yices
             names *)
            let val (dict, fresh, ty_dict, ty_fresh, defs) = acc
            in
              case Redblackmap.peek (dict, tm) of
                SOME s => (acc, s)
              | NONE =>
                let val name = "v" ^ Int.toString fresh
                    val dict = Redblackmap.insert (dict, tm, name)
                    (* also collect type definitions *)
                    val ((ty_dict, ty_fresh, defs), ty_name) = translate_type
                      ((ty_dict, ty_fresh, defs), Term.type_of tm)
                    val defs = "(define " ^ name ^ "::" ^ ty_name ^ ")" :: defs
                in
                  ((dict, fresh + 1, ty_dict, ty_fresh, defs), name)
                end
            end
      end

  fun term_to_Yices tm =
  let
    val _ = if Term.type_of tm <> Type.bool then
        Feedback.Raise (Feedback.mk_HOL_ERR "Yices" "term_to_Yices"
          "term supplied is not of type bool")
      else ()
    (* TODO: val tm = eta_long tm *)
    val empty = Redblackmap.mkDict Term.compare
    val empty_ty = Redblackmap.mkDict Type.compare
    val ((_, _, _, _, defs), yices_tm) = translate_term
      ((empty, 0, empty_ty, 0, []), tm)
    val defs' = List.map (fn s => s ^ "\n") (List.rev defs)
  in
    defs' @ ["(assert " ^ yices_tm ^ ")\n(check)\n"]
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