structure utilsLib :> utilsLib =
struct

open HolKernel boolLib bossLib
open state_transformerTheory
open wordsLib integer_wordLib bitstringLib

val ERR = Feedback.mk_HOL_ERR "utilsLib"
val WARN = Feedback.HOL_WARNING "utilsLib"

(* ------------------------------------------------------------------------- *)

fun cache size cmp f =
   let
      val d = ref (Redblackmap.mkDict cmp)
      val k = ref []
      val finite = 0 < size
   in
      fn v =>
         case Redblackmap.peek (!d, v) of
            SOME r => r
          | NONE =>
               let
                  val r = f v
               in
                  if finite
                     then (k := !k @ [v]
                           ; if size < Redblackmap.numItems (!d)
                                then case List.getItem (!k) of
                                        SOME (h, t) =>
                                          (d := fst (Redblackmap.remove (!d, h))
                                           ; k := t)
                                      | NONE => raise ERR "cache" "empty"
                              else ())
                  else ()
                  ; d := Redblackmap.insert (!d, v, r)
                  ; r
               end
   end

(* ------------------------------------------------------------------------- *)

fun partitions [] = []
  | partitions [x] = [[[x]]]
  | partitions (h::t) =
      let
         val ps = partitions t
      in
         List.concat
           (List.map
              (fn p =>
                  List.tabulate
                     (List.length p,
                      fn i =>
                         Lib.mapi (fn j => fn l =>
                                      if i = j then h :: l else l) p)) ps) @
          List.map (fn l => [h] :: l) ps
      end

(* ------------------------------------------------------------------------- *)

val save_as = Lib.curry Theory.save_thm
fun usave_as s = save_as s o Drule.UNDISCH
fun ustore_thm (s, t, tac) = usave_as s (Q.prove (t, tac))

fun padLeft c n l = List.tabulate (n - List.length l, fn _ => c) @ l
(* fun padRight c n l = l @ List.tabulate (n - List.length l, fn _ => c) *)

fun pick [] l2 = (WARN "pick" "not picking"; l2)
  | pick l1 l2 =
      let
         val l = Lib.zip l1 l2
      in
         List.mapPartial (fn (a, b) => if a then SOME b else NONE) l
      end

type cover = {redex: term frag list, residue: term} list list

fun augment (v, l1) l2 =
   List.concat (List.map (fn x => List.map (fn c => ((v |-> x) :: c)) l2) l1)

fun zipLists f =
   let
      fun loop a l =
         if List.null (hd l) then List.map f (List.rev a)
         else loop (List.map List.hd l::a) (List.map List.tl l)
   in
      loop []
   end

fun list_mk_wordii w = List.map (fn i => wordsSyntax.mk_wordii (i, w))

fun tab_fixedwidth m w =
   List.tabulate (m, fn n => bitstringSyntax.padded_fixedwidth_of_int (n, w))

local
   fun liftSplit f = (Substring.string ## Substring.string) o f o Substring.full
in
   fun splitAtChar P = liftSplit (Substring.splitl (not o P))
   fun splitAtPos n = liftSplit (fn s => Substring.splitAt (s, n))
end

val lowercase = String.map Char.toLower
val uppercase = String.map Char.toUpper

val long_term_to_string =
   Lib.with_flag (Globals.linewidth, 1000) Hol_pp.term_to_string

val lhsc = boolSyntax.lhs o Thm.concl
val rhsc = boolSyntax.rhs o Thm.concl
val eval = rhsc o bossLib.EVAL
val dom = fst o Type.dom_rng
val rng = snd o Type.dom_rng

val get_function =
   fst o boolSyntax.strip_comb o boolSyntax.lhs o
   snd o boolSyntax.strip_forall o List.hd o boolSyntax.strip_conj o Thm.concl

fun vacuous thm =
   let
      val (h, c) = Thm.dest_thm thm
   in
      c = boolSyntax.T orelse List.exists (Lib.equal boolSyntax.F) h
   end

fun add_to_rw_net f (thm: thm, n) = LVTermNet.insert (n, ([], f thm), thm)

fun mk_rw_net f = List.foldl (add_to_rw_net f) LVTermNet.empty

fun find_rw net tm =
   case LVTermNet.match (net, tm) of
      [] => raise ERR "find_rw" "not found"
    | l => List.map snd l: thm list

(* ---------------------------- *)

local
   val cmp = reduceLib.num_compset ()
   val () = computeLib.add_thms
              [pairTheory.UNCURRY, combinTheory.o_THM,
               state_transformerTheory.FOR_def,
               state_transformerTheory.BIND_DEF,
               state_transformerTheory.UNIT_DEF] cmp
   val FOR_CONV = computeLib.CBV_CONV cmp
   fun term_frag_of_int i = [QUOTE (Int.toString i)]: term frag list
in
   fun for_thm (h, l) =
      state_transformerTheory.FOR_def
      |> Conv.CONV_RULE (Conv.DEPTH_CONV Conv.FUN_EQ_CONV)
      |> Q.SPECL [term_frag_of_int h, term_frag_of_int l, `a`, `s`]
      |> Conv.RIGHT_CONV_RULE FOR_CONV
      |> Drule.GEN_ALL
end

(* ---------------------------- *)

(* Variant of UNDISCH
   [..] |- T ==> t    |->   [..] |- t
   [..] |- F ==> t    |->   [..] |- T
   [..] |- p ==> t    |->   [.., p] |- t
*)

local
   val thms = Drule.CONJUNCTS (Q.SPEC `t` boolTheory.IMP_CLAUSES)
   val T_imp = Drule.GEN_ALL (hd thms)
   val F_imp = Drule.GEN_ALL (List.nth (thms, 2))
   val NT_imp = DECIDE ``(~F ==> t) = t``
   fun dest_neg_occ_var tm1 tm2 =
      case Lib.total boolSyntax.dest_neg tm1 of
         SOME v => if Term.is_var v andalso not (Term.var_occurs v tm2)
                      then SOME v
                   else NONE
       | NONE => NONE
in
   fun ELIM_UNDISCH thm =
      case Lib.total boolSyntax.dest_imp (Thm.concl thm) of
         SOME (l, r) =>
            if l = boolSyntax.T
               then Conv.CONV_RULE (Conv.REWR_CONV T_imp) thm
            else if l = boolSyntax.F
               then Conv.CONV_RULE (Conv.REWR_CONV F_imp) thm
            else if Term.is_var l andalso not (Term.var_occurs l r)
               then Conv.CONV_RULE (Conv.REWR_CONV T_imp)
                       (Thm.INST [l |-> boolSyntax.T] thm)
            else (case dest_neg_occ_var l r of
                     SOME v => Conv.CONV_RULE (Conv.REWR_CONV NT_imp)
                                  (Thm.INST [v |-> boolSyntax.F] thm)
                   | NONE => Drule.UNDISCH thm)
       | NONE => raise ERR "ELIM_UNDISCH" ""
end

fun LIST_DISCH tms thm = List.foldl (Lib.uncurry Thm.DISCH) thm tms

(* ---------------------------- *)

local
   val rl =
      REWRITE_RULE [boolTheory.NOT_CLAUSES, GSYM boolTheory.AND_IMP_INTRO,
                    boolTheory.DE_MORGAN_THM]
   val pats = [``~ ~a: bool``, ``a /\ b``, ``~(a \/ b)``]
   fun mtch tm = List.exists (fn p => Lib.can (Term.match_term p) tm) pats
in
   fun HYP_CANON_RULE thm =
      let
         val hs = List.filter mtch (Thm.hyp thm)
      in
         List.foldl
           (fn (h, t) => repeat ELIM_UNDISCH (rl (Thm.DISCH h t))) thm hs
      end
end

(* Apply rule to hyphothesis tm *)

fun HYP_RULE r tm = ELIM_UNDISCH o r o Thm.DISCH tm

(* Apply rule to hyphotheses satisfying P *)

fun PRED_HYP_RULE r P thm =
   List.foldl (Lib.uncurry (HYP_RULE r)) thm (List.filter P (Thm.hyp thm))

(* Apply rule to hyphotheses matching pat *)

fun MATCH_HYP_RULE r pat = PRED_HYP_RULE r (Lib.can (Term.match_term pat))

(* Apply conversion c to all hyphotheses *)

fun ALL_HYP_RULE r = PRED_HYP_RULE r (K true)

local
   fun LAND_RULE c = Conv.CONV_RULE (Conv.LAND_CONV c)
in
   fun HYP_CONV_RULE c = HYP_RULE (LAND_RULE c)
   fun PRED_HYP_CONV_RULE c = PRED_HYP_RULE (LAND_RULE c)
   fun MATCH_HYP_CONV_RULE c = MATCH_HYP_RULE (LAND_RULE c)
   fun ALL_HYP_CONV_RULE c = ALL_HYP_RULE (LAND_RULE c)
   fun FULL_CONV_RULE c = ALL_HYP_CONV_RULE c o Conv.CONV_RULE c
end

(* ---------------------------- *)

(* CBV_CONV but fail if term unchanged *)
fun CHANGE_CBV_CONV cmp = Conv.CHANGED_CONV (computeLib.CBV_CONV cmp)

local
   val alpha_rwts =
        [boolTheory.COND_ID, wordsTheory.WORD_SUB_RZERO,
         wordsTheory.WORD_ADD_0, wordsTheory.WORD_MULT_CLAUSES,
         wordsTheory.WORD_AND_CLAUSES, wordsTheory.WORD_OR_CLAUSES,
         wordsTheory.WORD_XOR_CLAUSES, wordsTheory.WORD_EXTRACT_ZERO2,
         wordsTheory.w2w_0, wordsTheory.WORD_SUB_REFL]
in
   val WALPHA_CONV = REWRITE_CONV alpha_rwts
   val WGROUND_CONV =
      Conv.DEPTH_CONV (wordsLib.WORD_GROUND_CONV false)
      THENC PURE_REWRITE_CONV alpha_rwts
end

fun NCONV n conv = Lib.funpow n (Lib.curry (op THENC) conv) Conv.ALL_CONV
fun SRW_CONV thms = SIMP_CONV (srw_ss()) thms
val EXTRACT_CONV = SIMP_CONV (srw_ss()++wordsLib.WORD_EXTRACT_ss) []
val SET_CONV = SIMP_CONV (bool_ss++pred_setLib.PRED_SET_ss) []
fun SRW_RULE thms = Conv.CONV_RULE (SRW_CONV thms)
val SET_RULE = Conv.CONV_RULE SET_CONV
val o_RULE   = REWRITE_RULE [combinTheory.o_THM]

fun qm l = Feedback.trace ("metis", 0) (metisLib.METIS_PROVE l)
fun qm_tac l = Feedback.trace ("metis", 0) (metisLib.METIS_TAC l)

local
   val f = Term.rator o lhsc o Drule.SPEC_ALL
   fun g tm =
      let
         val ty = dom (dom (Term.type_of tm))
         val v = Term.mk_var ("v", ty)
         val kv = boolSyntax.mk_icomb (combinSyntax.K_tm, v)
      in
         Term.mk_comb (tm, Term.inst [Type.beta |-> ty] kv)
      end
in
   fun accessor_fns ty = List.map f (TypeBase.accessors_of ty)
   fun update_fns ty = List.map (g o Term.rator o f) (TypeBase.updates_of ty)
end

fun map_conv (cnv: conv) = Drule.LIST_CONJ o List.map cnv

val mk_cond_rand_thms =
   map_conv
      (fn tm => Drule.GEN_ALL (o_RULE (Drule.ISPEC tm boolTheory.COND_RAND)))

local
   val COND_UPDATE = Q.prove(
      `!f b v1 v2 s1 s2.
         (if b then f (K v1) s1 else f (K v2) s2) =
         f (K (if b then v1 else v2)) (if b then s1 else s2)`,
      Cases_on `b` THEN REWRITE_TAC [])
   val COND_UPDATE2 = Q.prove(
      `!b a x y f.
         (if b then (a =+ x) f else (a =+ y) f) =
         (a =+ if b then x else y) f`,
      Cases THEN REWRITE_TAC [])
   fun cond_update_thms ty =
      let
         val {Thy, Tyop, ...} = Type.dest_thy_type ty
         val component_equality = DB.fetch Thy (Tyop ^ "_component_equality")
      in
         List.map
           (fn (t1, t2) =>
              let
                 val thm = Drule.ISPEC (boolSyntax.rator t2) COND_UPDATE
                 val thm0 = Drule.SPEC_ALL thm
                 val v = hd (Term.free_vars t2)
                 val (v1, v2, s1, s2) =
                    case boolSyntax.strip_forall (Thm.concl thm) of
                       ([_, v1, v2, s1, s2], _) => (v1, v2, s1, s2)
                     | _ => raise ERR "mk_cond_update_thms" ""
                 val s1p = Term.mk_comb (t1, s1)
                 val s2p = Term.mk_comb (t1, s2)
                 val id_thm =
                    Tactical.prove(
                       boolSyntax.mk_eq
                          (Term.subst [v |-> s1p] (Term.mk_comb (t2, s1)), s1),
                       SRW_TAC [] [component_equality])
                 val rule = Drule.GEN_ALL o REWRITE_RULE [id_thm]
                 val thm1 = rule (Thm.INST [v1 |-> s1p] thm0)
                 val thm2 = rule (Thm.INST [v2 |-> s2p] thm0)
              in
                 [thm, thm1, thm2]
              end)
           (ListPair.zip (accessor_fns ty, update_fns ty))
           |> List.concat
      end
in
   fun mk_cond_update_thms l =
      [boolTheory.COND_ID, COND_UPDATE2] @
      List.concat (List.map cond_update_thms l)
end

(* Substitution allowing for type match *)

local
   fun match_residue {redex = a, residue = b} =
      let
         val m = Type.match_type (Term.type_of b) (Term.type_of a)
      in
         a |-> Term.inst m b
      end
in
   fun match_subst s = Term.subst (List.map match_residue s)
end

(*
fun match_mk_eq (a, b) =
   let
      val m = Type.match_type (Term.type_of b) (Term.type_of a)
   in
      boolSyntax.mk_eq (a, Term.inst m b)
   end

fun mk_eq_contexts (a, l) = List.map (fn b => [match_mk_eq (a, b)]) l
*)

fun avoid_name_clashes tm2 tm1 =
   let
      val v1 = Term.free_vars tm1
      val v2 = Term.free_vars tm2
      val ns = List.map (fst o Term.dest_var) v2
      val (l, r) =
         List.partition (fn v => Lib.mem (fst (Term.dest_var v)) ns) v1
      val v2 = v2 @ r
      val sb = List.foldl
                  (fn (v, (sb, avoids)) =>
                     let
                        val v' = Lib.with_flag (Globals.priming, SOME "_")
                                    (Term.variant avoids) v
                     in
                        ((v |-> v') :: sb, v' :: avoids)
                     end) ([], v2) l
   in
      Term.subst (fst sb) tm1
   end

local
   fun mk_fupd s f = s ^ "_" ^ f ^ "_fupd"
   val name = fst o Term.dest_const o fst o Term.dest_comb
in
   fun mk_state_id_thm eqthm =
      let
         val ty = Term.type_of (fst (boolSyntax.dest_forall (Thm.concl eqthm)))
         fun mk_thm l =
            let
               val {Tyop, Thy, ...} = Type.dest_thy_type ty
               val mk_f = mk_fupd Tyop
               val fns = update_fns ty
               fun get s = List.find (fn f => name f = mk_f s) fns
               val l1 = List.mapPartial get l
               val s = Term.mk_var ("s", ty)
               val h = hd l1
               val id = Term.prim_mk_const {Thy = Thy, Name = Tyop ^ "_" ^ hd l}
               val id =
                  Term.subst [hd (Term.free_vars h) |-> Term.mk_comb (id, s)] h
               val after = List.foldr
                              (fn (f, tm) =>
                                 let
                                    val f1 = avoid_name_clashes tm f
                                 in
                                    Term.mk_comb (f1, tm)
                                 end) s (tl l1)
               val goal = boolSyntax.mk_eq (Term.mk_comb (id, after), after)
            in
               Drule.GEN_ALL (Tactical.prove (goal, bossLib.SRW_TAC [] [eqthm]))
            end
      in
         Drule.LIST_CONJ o List.map mk_thm
      end
end

(* ---------------------------- *)

(* Rewrite tm using theorem thm, instantiating free variables from hypotheses
   as required *)

local
   fun TRY_EQ_FT thm =
      if boolSyntax.is_eq (Thm.concl thm)
         then thm
      else (Drule.EQF_INTRO thm handle HOL_ERR _ => Drule.EQT_INTRO thm)
in
   fun INST_REWRITE_CONV1 thm =
      let
         val mtch = Term.match_term (boolSyntax.lhs (Thm.concl thm))
      in
         fn tm => PURE_REWRITE_CONV [Drule.INST_TY_TERM (mtch tm) thm] tm
                  handle HOL_ERR _ => raise ERR "INST_REWRITE_CONV1" ""
      end
   fun INST_REWRITE_CONV l =
      let
         val thms =
            l |> List.map (Drule.CONJUNCTS o Drule.SPEC_ALL)
              |> List.concat
              |> List.map (TRY_EQ_FT o Drule.SPEC_ALL)
         val net = List.partition (List.null o Thm.hyp) o
                   find_rw (mk_rw_net lhsc thms)
      in
         Conv.REDEPTH_CONV
           (fn tm =>
               case net tm of
                  ([], []) => raise Conv.UNCHANGED
                | (thm :: _, _) => Conv.REWR_CONV thm tm
                | ([], thm :: _) => INST_REWRITE_CONV1 thm tm)
      end
   fun INST_REWRITE_RULE thm = Conv.CONV_RULE (INST_REWRITE_CONV thm)
end

(* ---------------------------- *)

local
   fun base t =
      case Lib.total boolSyntax.dest_neg t of
         SOME s => base s
       | NONE =>
          (case Lib.total boolSyntax.lhs t of
              SOME s => s
            | NONE => t)
   fun find_occurance r t =
      Lib.can (HolKernel.find_term (Lib.equal (base t))) r
   val modified = ref 0
   fun specialize (conv, tms) thm =
      let
         val hs = Thm.hyp thm
         val hs = List.filter (fn h => List.exists (find_occurance h) tms) hs
         val sthm = thm |> LIST_DISCH hs
                        |> REWRITE_RULE (List.map ASSUME tms)
                        |> Conv.CONV_RULE conv
                        |> Drule.UNDISCH_ALL
      in
         if vacuous sthm then NONE else (Portable.inc modified; SOME sthm)
      end handle Conv.UNCHANGED => SOME thm
in
   fun specialized msg ctms thms =
      let
         val sz = Int.toString o List.length
         val () = print ("Specializing " ^ msg ^ ": " ^ sz thms ^ " -> ")
         val () = modified := 0
         val r = List.mapPartial (specialize ctms) thms
      in
         print (sz r ^ "(" ^ Int.toString (!modified) ^ ")\n"); r
      end
end

(* ---------------------------- *)

(* case split theorem. For example: split_conditions applied to

     |- q = if b then x else y

   gives theorems

     [[~b] |- q = y, [b] |- q = x]
*)

local
   val split_x = Q.prove(
      `b ==> ((if b then x else y) = x: 'a)`, RW_TAC bool_ss [])
      |> Drule.UNDISCH
   val split_y = Q.prove(
      `~b ==> ((if b then x else y) = y: 'a)`, RW_TAC bool_ss [])
      |> Drule.UNDISCH
   val split_z = Q.prove(
      `b ==> ((if ~b then x else y) = y: 'a)`, RW_TAC bool_ss [])
      |> Drule.UNDISCH
   val vb = Term.mk_var ("b", Type.bool)
   fun REWR_RULE thm = Conv.CONV_RULE (Conv.RHS_CONV (Conv.REWR_CONV thm))
   fun cond_true b = Thm.INST [vb |-> b] split_x
   fun cond_false b = Thm.INST [vb |-> b] split_y
in
   val split_conditions =
      let
         fun loop a t =
            case Lib.total boolSyntax.dest_cond (rhsc t) of
               SOME (b, x, y) =>
                  let
                     val ty = Term.type_of x
                     val vx = Term.mk_var ("x", ty)
                     val vy = Term.mk_var ("y", ty)
                     fun s cb = Drule.INST_TY_TERM
                                 ([vb |-> cb, vx |-> x, vy |-> y],
                                  [Type.alpha |-> ty])
                     val (split_yz, nb) =
                        case Lib.total boolSyntax.dest_neg b of
                           SOME nb => (split_z, nb)
                         | NONE => (split_y, b)
                  in
                     loop (loop a (REWR_RULE (s b split_x) t))
                                  (REWR_RULE (s nb split_yz) t)
                  end
             | NONE => t :: a
      in
         loop []
      end
   fun paths [] = []
     | paths (h :: t) =
         [[cond_false h]] @ (List.map (fn p => cond_true h :: p) (paths t))
end

(* ---------------------------- *)

val can_match = Lib.can o Lib.C Term.match_term

fun avoid_exception tm =
   let
      val ty = Term.type_of tm
      val ety = dom ty
      val sty = dom (rng ty)
      val et = Term.mk_comb (tm, Term.mk_var ("e", ety))
      val et = Term.mk_comb (et, Term.mk_var ("s", sty))
      val l = [pairSyntax.mk_fst et, pairSyntax.mk_snd et, et]
      fun is_raise tm = List.exists (can_match tm) l
      fun check thm =
         (not (Lib.can (HolKernel.find_term is_raise) (rhsc thm))
          orelse (Parse.print_thm thm
                  ; print "\n"
                  ; raise ERR "avoid_exception" "failed to avoid")
          ; thm)
      fun avoids thm =
         let
            fun iter a tm =
               case Lib.total boolSyntax.dest_cond tm of
                  SOME (b, t, e) =>
                   Lib.union
                     (iter (b :: a) t)
                     (iter (boolSyntax.mk_neg b :: a) e)
                | NONE =>
                   if is_raise tm
                      then [a]
                   else (case Lib.total Term.dest_comb tm of
                            SOME (l, r) => Lib.union (iter a l) (iter a r)
                          | NONE => [])
         in
            thm
            |> Thm.concl
            |> iter []
            |> Lib.mk_set
            |> List.filter (not o List.null)
            |> List.map List.rev
         end
   in
      fn thm =>
         case avoids thm of
            [] => [check thm]
          | [ps] =>
              List.map
                (fn p => HYP_CANON_RULE (check (PURE_REWRITE_RULE p thm)))
                (paths ps)
          | _ => (Parse.print_thm thm
                  ; print "\n"
                  ; raise ERR "avoid_exception" "too many raise points")
   end

(* ---------------------------- *)

(* Support for rewriting/evaluation *)

val basic_rewrites =
   [state_transformerTheory.FOR_def,
    state_transformerTheory.BIND_DEF,
    combinTheory.APPLY_UPDATE_THM,
    combinTheory.K_o_THM,
    combinTheory.K_THM,
    combinTheory.o_THM,
    pairTheory.FST,
    pairTheory.SND,
    pairTheory.pair_case_thm,
    optionTheory.option_case_compute,
    optionTheory.IS_SOME_DEF,
    optionTheory.THE_DEF]

local
   fun in_conv conv tm =
      case Lib.total pred_setSyntax.dest_in tm of
         SOME (a1, a2) =>
            if pred_setSyntax.is_set_spec a2
               then pred_setLib.SET_SPEC_CONV tm
            else pred_setLib.IN_CONV conv tm
       | NONE => raise ERR "in_conv" "not an IN term";
in
   fun add_base_datatypes cmp =
      let
         val cnv = computeLib.CBV_CONV cmp
      in
         computeLib.add_thms basic_rewrites cmp
         ; List.app (fn x => computeLib.add_conv x cmp)
             [(pred_setSyntax.in_tm, 2, in_conv cnv),
              (pred_setSyntax.insert_tm, 2, pred_setLib.INSERT_CONV cnv)]
      end
end

local
   (* Taken from src/datatype/EnumType.sml *)
   fun gen_triangle l =
      let
         fun gen_row i [] acc = acc
           | gen_row i (h::t) acc = gen_row i t ((i,h)::acc)
         fun doitall [] acc = acc
           | doitall (h::t) acc = doitall t (gen_row h t acc)
      in
         List.rev (doitall l [])
      end
   fun datatype_rewrites1 ty =
      case TypeBase.simpls_of ty of
        {convs = [], rewrs = r} => r
      | {convs = {conv = c, name = n, ...} :: _, rewrs = r} =>
            if String.isSuffix "const_eq_CONV" n
               then let
                       val neq = Drule.EQF_ELIM o
                                 c (K Conv.ALL_CONV) [] o
                                 boolSyntax.mk_eq
                       val l = ty |> TypeBase.constructors_of
                                  |> gen_triangle
                                  |> List.map neq
                                  |> Drule.LIST_CONJ
                    in
                       [l, GSYM l] @ r
                    end
            else r
in
   fun datatype_rewrites thy l =
      let
         fun typ name = Type.mk_thy_type {Thy = thy, Args = [], Tyop = name}
      in
         List.drop (basic_rewrites, 2) @
         List.concat (List.map (datatype_rewrites1 o typ) l)
      end
end

local
   fun fetch1 thy name =
      case Lib.total (DB.fetch thy) name of
         SOME thm => [thm]
       | NONE => []
   val err = ERR "enum_eq_CONV" "Equality not between constants"
   fun add_datatype cmp ty =
      let
         val (thy, name) = case Type.dest_thy_type ty of
                              {Thy = thy, Args = [], Tyop = name} => (thy, name)
                            | _ => raise ERR "add_datatype" "Not 0-ary type"
         val ftch = fetch1 thy
         val ty2num = ftch (name ^ "2num_thm")
         val num2ty = ftch ("num2" ^ name ^ "_thm")
         fun add r = computeLib.add_thms (r @ ty2num @ num2ty) cmp
      in
         (case Lib.total TypeBase.case_const_of ty of
             SOME tm => computeLib.set_skip cmp tm NONE
           | NONE => ())
         ; case TypeBase.simpls_of ty of
              {convs = [], rewrs = r} => add r
            | {convs = {name = n, ...} :: _, rewrs = r} =>
              (add r
               ; if String.isSuffix "const_eq_CONV" n (* enumerated *)
                    then case (ftch (name ^ "_EQ_" ^ name), ty2num) of
                            ([eq_elim_thm], [_]) =>
                            let
                               val cnv =
                                  Conv.REWR_CONV eq_elim_thm
                                  THENC PURE_REWRITE_CONV ty2num
                                  THENC reduceLib.REDUCE_CONV
                               fun ecnv tm =
                                  let
                                     val (l, r) = boolSyntax.dest_eq tm
                                     val _ =
                                        Term.is_const l andalso Term.is_const r
                                        orelse raise err
                                  in
                                     cnv tm
                                  end
                            in
                               computeLib.add_conv
                                  (boolSyntax.equality, 2, ecnv) cmp
                            end
                          | _ => ()
                 else ())
      end
in
   fun add_datatypes l cmp = List.app (add_datatype cmp) l
end

type inventory = {C: string list, N: int list, T: string list, Thy: string}

fun theory_types (i: inventory)  =
   let
      val {Thy = thy, T = l, ...} = i
   in
      List.map (fn t => Type.mk_thy_type {Thy = thy, Args = [], Tyop = t}) l
   end

fun filter_inventory names ({Thy = thy, C = l, N = n, T = t}: inventory) =
   let
      val es = List.map (fn s => s ^ "_def") names
   in
      {Thy = thy, C = List.filter (fn t => not (Lib.mem t es)) l, N = n, T = t}
   end

local
   fun bool_bit_thms i =
      let
         val s = Int.toString i
         val b = "boolify" ^ s
      in
         ["bitify" ^ s ^ "_def", b ^ "_n2w", b ^ "_v2w"]
      end
   val get_name = fst o Term.dest_const o fst o HolKernel.strip_comb o
                  boolSyntax.lhs o snd o boolSyntax.strip_forall o
                  List.hd o boolSyntax.strip_conj o Thm.concl
in
   fun theory_rewrites (thms, i: inventory) =
      let
         val thm_names = List.map get_name thms
         val {Thy = thy, C = l, N = n, ...} = filter_inventory thm_names i
         val m = List.concat (List.map bool_bit_thms n)
      in
         List.map (fn t => DB.fetch thy t) (l @ m) @ thms
      end
end

fun add_theory (x as (_, i)) cmp =
   (add_datatypes (theory_types i) cmp
    ; computeLib.add_thms (theory_rewrites x) cmp)

fun add_to_the_compset x = computeLib.add_funs (theory_rewrites x)

fun theory_compset x =
   let
      val cmp = wordsLib.words_compset ()
   in
      add_base_datatypes cmp; add_theory x cmp; cmp
   end

(* ---------------------------- *)

local
   val dom = fst o Type.dom_rng o Term.type_of
   fun is_def thy tm =
      let
         val name = fst (Term.dest_const tm)
      in
         Lib.can Term.prim_mk_const {Thy = thy, Name = "dfn'" ^ name}
      end
   fun buildAst thy ty =
      let
         val cs = TypeBase.constructors_of ty
         val (t0, n) = List.partition (Lib.equal ty o Term.type_of) cs
         val (t1, n) = List.partition (is_def thy) n
         val t1 =
            List.map (fn t => Term.mk_comb (t, Term.mk_var ("x", dom t))) t1
         val n =
            List.map (fn t =>
                        let
                           val l = buildAst thy (dom t)
                        in
                           List.map (fn x => Term.mk_comb (t, x)
                           handle HOL_ERR {origin_function = "mk_comb", ...} =>
                             (Parse.print_term t; print "\n";
                              Parse.print_term x; raise ERR "buildAst" "")) l
                        end) n
      in
         t0 @ t1 @ List.concat n
      end
   fun is_call x tm =
      case Lib.total Term.rand tm of
        SOME y => x = y
      | NONE => false
   fun leaf tm =
      case Lib.total Term.rand tm of
        SOME y => leaf y
      | NONE => tm
   fun run_thm0 thy ast =
      let
         val tac = SIMP_TAC (srw_ss()) [DB.fetch thy "Run_def"]
         val f = Term.prim_mk_const
                   {Thy = thy, Name = "dfn'" ^ fst (Term.dest_const (leaf ast))}
      in
         if Term.type_of f = oneSyntax.one_ty
            then Q.prove (`!s. Run ^ast s = (^f, s)`, tac)
         else Q.prove (`!s. Run ^ast s = ^f s`, tac)
      end
   fun run_thm thy ast =
      let
         val tac = SIMP_TAC (srw_ss()) [DB.fetch thy "Run_def"]
         val x = hd (Term.free_vars ast)
         val tm = Term.rator (HolKernel.find_term (is_call x) ast)
         val f = Term.prim_mk_const
                   {Thy = thy, Name = "dfn'" ^ fst (Term.dest_const tm)}
      in
         Q.prove (`!s. Run ^ast s = ^f ^x s`, tac)
      end
   fun run_rwts thy =
      let
         val ty = Type.mk_thy_type {Thy = thy, Args = [], Tyop = "instruction"}
         val (arg0, args) =
            List.partition (List.null o Term.free_vars) (buildAst thy ty)
      in
         List.map (run_thm0 thy) arg0 @ List.map (run_thm thy) args
      end
   fun run_tm thy = Term.prim_mk_const {Thy = thy, Name = "Run"}
in
   fun mk_run (thy, st) = fn ast => Term.list_mk_comb (run_tm thy, [ast, st])
   fun Run_CONV (thy, st) =
      Thm.GEN st o PURE_REWRITE_CONV (run_rwts thy) o mk_run (thy, st)
end

(* ---------------------------- *)

local
   val rwts = [pairTheory.UNCURRY, combinTheory.o_THM, combinTheory.K_THM]
   val no_hyp = List.partition (List.null o Thm.hyp)
   val add_word_eq =
      computeLib.add_conv (``$= :'a word -> 'a word -> bool``, 2,
                           bitstringLib.word_eq_CONV)
   fun context_subst tm =
      let
         val f = Parse.parse_in_context (Term.free_vars tm)
      in
         List.map (List.map (fn {redex, residue} => f redex |-> residue))
      end
   val step_conv = ref Conv.ALL_CONV
in
   fun resetStepConv () = step_conv := Conv.ALL_CONV
   fun setStepConv c = step_conv := c
   fun STEP (datatype_thms, st) =
      let
         val DATATYPE_CONV = REWRITE_CONV (datatype_thms [])
         fun fix_datatype tm = rhsc (Conv.QCONV DATATYPE_CONV tm)
         val SAFE_ASSUME = Thm.ASSUME o fix_datatype
      in
         fn l => fn ctms => fn s => fn tm =>
            let
               val (nh, h) = no_hyp l
               val c = INST_REWRITE_CONV h
               val cmp = reduceLib.num_compset ()
               val () = computeLib.add_thms (rwts @ nh) cmp
               val () = add_word_eq cmp
               fun cnv rwt =
                  Conv.REPEATC
                    (Conv.TRY_CONV (CHANGE_CBV_CONV cmp)
                     THENC REWRITE_CONV (datatype_thms (rwt @ h))
                     THENC (!step_conv)
                     THENC c)
               val stm = Term.mk_comb (tm, st)
               val sbst = context_subst stm s
               fun cnvs rwt =
                  case sbst of
                     [] => [cnv rwt stm]
                   | l => List.map (fn sub => cnv rwt (match_subst sub stm)) l
               val ctxts = List.map (List.map SAFE_ASSUME) ctms
            in
               case ctxts of
                  [] => cnvs []
                | _ => List.map (fn r => cnvs r) ctxts |> List.concat
            end
      end
end

end
