structure smallfootLib :> smallfootLib =
struct

(*
quietdec := true;
loadPath := 
            (concat [Globals.HOLDIR, "/examples/separationLogic/src"]) :: 
            (concat [Globals.HOLDIR, "/examples/separationLogic/src/smallfoot"]) :: 
            !loadPath;

map load ["finite_mapTheory", "relationTheory", "congLib", "sortingTheory",
   "rich_listTheory", "generalHelpersTheory", "latticeTheory", "separationLogicTheory",
   "stringTheory",
   "vars_as_resourceTheory", "stringLib", "listLib", "smallfootTheory"];
show_assums := true;
*)

open HolKernel Parse boolLib bossLib

open generalHelpersTheory 
open    finite_mapTheory relationTheory pred_setTheory congLib sortingTheory
  listTheory rich_listTheory arithmeticTheory operatorTheory
optionTheory latticeTheory separationLogicTheory separationLogicLib
vars_as_resourceTheory stringTheory smallfootTheory;

open smallfootSyntax smallfootParser smallfoot_pp_print BoolExtractShared
   ConseqConv;

(*
quietdec := false;
*)






fun COND_REWR_CONV___with_match thm =
  if (is_imp (concl thm)) then
     if (is_eq (snd (dest_imp (concl thm)))) then
        (UNDISCH o (PART_MATCH (lhs o snd o dest_imp) thm),
	 (lhs o snd o dest_imp o concl) thm)
     else
        (EQT_INTRO o UNDISCH o (PART_MATCH (snd o dest_imp) thm),
         (snd o dest_imp o concl) thm)
  else
     if (is_eq (concl thm)) then
        (PART_MATCH lhs thm, 
         (lhs o concl) thm)
     else
        (EQT_INTRO o PART_MATCH I thm,
	 concl thm)


fun COND_REWR_CONV thm =
    fst (COND_REWR_CONV___with_match thm);




fun COND_REWRITE_CONV thmL =
   let
     val thmL' = flatten (map BODY_CONJUNCTS thmL);
     val conv_termL = map COND_REWR_CONV___with_match thmL';
     val net = foldr (fn ((conv,t),net) => Net.insert (t,conv) net) Net.empty conv_termL;
   in     
     REPEATC (fn t =>    
        let
	  val convL = Net.match t net;	    	
	in
          FIRST_CONV convL t
	end)
   end


fun GUARDED_COND_REWRITE_CONV p thmL =
   let
      val conv = COND_REWRITE_CONV thmL
   in
      fn t => if p t then conv t else NO_CONV t
   end





















val LIST_UNROLE_GIVEN_ELEMENT_NAMES_term = ``LIST_UNROLE_GIVEN_ELEMENT_NAMES``;

fun LIST_UNROLE_GIVEN_ELEMENT_NAMES_CONV t =
let
   val (fun_term, argL) = strip_comb t;
   val _ = if (same_const fun_term LIST_UNROLE_GIVEN_ELEMENT_NAMES_term) andalso
	      (length argL = 2) then () else raise UNCHANGED;
   val (arg1, arg2) = (el 1 argL, el 2 argL);
   val thm = ONCE_REWRITE_CONV [LIST_UNROLE_GIVEN_ELEMENT_NAMES___UNROLL] t;
   val rhs_term = rhs (concl thm);
in
   if (not (is_exists rhs_term)) then thm else
   let 
       val new_name = stringLib.fromHOLstring (fst (listLib.dest_cons arg2));
       val thm2 = (RENAME_VARS_CONV [new_name] THENC
		  DEPTH_CONV LIST_UNROLE_GIVEN_ELEMENT_NAMES_CONV THENC
      	          DEPTH_CONV RIGHT_AND_EXISTS_CONV THENC
		  DEPTH_CONV Unwind.UNWIND_EXISTS_CONV)
		  rhs_term;      
   in
       TRANS thm thm2
   end
end;



(*
val _ = temp_add_smallfoot_pp();
val _ = use_smallfoot_pretty_printer := false;
val _ = use_smallfoot_pretty_printer := true;
*)





fun FASL_PROGRAM_ABSTRACTION_REFL_CONV xenv penv t =
   (ISPECL [xenv,penv,t] FASL_PROGRAM_IS_ABSTRACTION___REFL)

fun FASL_PROGRAM_ABSTRACTION_CONV_int [] sys xenv penv asm p =
    (ISPECL [xenv,penv,p] FASL_PROGRAM_IS_ABSTRACTION___REFL)
| FASL_PROGRAM_ABSTRACTION_CONV_int (c1::L) sys xenv penv asm p =
  (c1 sys xenv penv asm p) handle UNCHANGED => FASL_PROGRAM_ABSTRACTION_CONV_int L sys xenv penv asm p;

fun FASL_PROGRAM_ABSTRACTION_CONV L xenv penv asm p =
    (FASL_PROGRAM_ABSTRACTION_CONV_int L (FASL_PROGRAM_ABSTRACTION_CONV L) xenv penv asm p);


fun Raise_MSG_UNCHANGED m =
    (print m;print "\n";Raise UNCHANGED);




val FEVERY_FUPDATE_IMP = store_thm ("FEVERY_FUPDATE_IMP",
``!P f. (P (x,y) /\
        FEVERY P f) ==>
       FEVERY P (f |+ (x,y))``,

SIMP_TAC std_ss [FEVERY_DEF, FDOM_FEMPTY, FDOM_FUPDATE,
		 NOT_IN_EMPTY, IN_INSERT, DISJ_IMP_THM,
		 FORALL_AND_THM, FAPPLY_FUPDATE_THM] THEN
REPEAT STRIP_TAC THEN
Cases_on `x' = x` THEN 
ASM_SIMP_TAC std_ss[]);




(*
val t = `` FEVERY
       (\x.
          SMALLFOOT_AE_USED_VARS_SUBSET
            (SET_OF_BAG
               (BAG_UNION {|smallfoot_var "z"; smallfoot_var "x"|} {| |}))
            (SND x)) (FEMPTY |+ (smallfoot_tag "c",smallfoot_ae_const 4) 
                             |+ (smallfoot_tag "c",smallfoot_ae_const 9))``;
*)



fun FEVERY_CONSEQ_CONV t =
   let
      val (P,f) = dest_FEVERY t handle HOL_ERR _ => raise UNCHANGED;
   in
      if (same_const f FEMPTY_tm) then 
	  REWRITE_CONV [FEVERY_FEMPTY] t
      else
          HO_PART_MATCH (snd o dest_imp) FEVERY_FUPDATE_IMP t
   end;




(*This function tries to prove preconditions of rewrites that
  occure during the verification. Mostly it is concerned with
  proving that bags / sets are disjoint, values are not contained 
  in them, lists are of some length etc.
*)






val smallfoot_ap_imps = flatten (map BODY_CONJUNCTS [SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___points_to,
	        		 SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___compare,
				 SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___list_seg,
				 SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___list,
				 SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___bintree]);



val precond_cs = reduceLib.num_compset ();
val _ = computeLib.add_thms [pairTheory.FST, 
			     pairTheory.SND, 
			     LENGTH,
                             MAP,
                             listTheory.ALL_DISTINCT,
                             SMALLFOOT_AE_USED_VARS_SUBSET___EVAL,
			     bagTheory.BAG_IN_BAG_INSERT,
			     bagTheory.NOT_IN_EMPTY_BAG,
			     BAG_ALL_DISTINCT_THM,
  			     ALL_DISTINCT, MEM,
                             SMALLFOOT_PP_USED_VARS_THM, optionTheory.THE_DEF,
			     SMALLFOOT_PE_USED_VARS___REWRITE,
			     IS_SOME___SMALLFOOT_AE_USED_VARS___EVAL,
	 		     smallfoot_var_11,
	 		     smallfoot_tag_11,
		             UNION_SUBSET, 
                             IN_UNIV,			     
			     EMPTY_SUBSET,
			     INSERT_SUBSET,
			     DE_MORGAN_THM,
              		     FEVERY_FEMPTY,
			     IN_UNION,
			     BAG_EVERY_THM,
			     IN_DIFF,
			     IN_INSERT,
                             EVERY_DEF,
			     FDOM_FUPDATE,
			     FDOM_FEMPTY,
			     NOT_IN_EMPTY,
			     FAPPLY_FUPDATE_THM,
			     smallfoot_prop___WEAK_COND___REWRITE,
			     BAG_DISJOINT___BAG_INSERT,
			     bagTheory.BAG_DISJOINT_EMPTY,
			     bagTheory.IN_SET_OF_BAG,
			     bagTheory.SET_OF_BAG_UNION,
			     bagTheory.SET_OF_BAG_INSERT,
			     SET_OF_BAG_EMPTY,
			     bagTheory.BAG_IN_BAG_UNION,
			     bagTheory.NOT_IN_EMPTY_BAG,
			     SET_OF_BAG_MERGE,
			     SMALLFOOT_P_EXPRESSION_EVAL_def,
                             bagTheory.BAG_IN_BAG_INSERT] precond_cs;



(*
val t_ref = ref T;
val sys = smallfoot_precondition_prove m 
*)



val smallfoot_precondition_prove_internal___USED_VARS_cache_ref = ref (Net.empty: thm Net.net);

local
   val internal_conv =
                 CONJ_ASSUMPTIONS_DEPTH_CONSEQ_CONV 
                    (FIRST_CONSEQ_CONV [
                     COND_REWRITE_CONV smallfoot_ap_imps,
                     REWRITE_CONV [SMALLFOOT_AE_USED_VARS_SUBSET___EVAL],
                     FEVERY_CONSEQ_CONV]);
in

fun smallfoot_precondition_prove_internal___USED_VARS___STRENGTEN_CONV t =
    let 
      val thms = Net.match t (!smallfoot_precondition_prove_internal___USED_VARS_cache_ref) 
      val thm_opt = SOME (tryfind (fn thm => PART_MATCH (snd o dest_imp) thm t) thms) 
		 handle HOL_ERR _ => NONE
    in
      if isSome thm_opt then
         valOf thm_opt
      else
         let
	     val (vs, p) = dest_SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS t;
	     val vs_var = mk_var ("vs", smallfoot_var_type --> bool)
             val t' = mk_SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS vs_var p
             val thm = internal_conv t'
             val _ = smallfoot_precondition_prove_internal___USED_VARS_cache_ref := Net.insert (t',thm) (!smallfoot_precondition_prove_internal___USED_VARS_cache_ref)
	 in
             PART_MATCH (snd o dest_imp) thm t
	 end
   end;

end


val precond_derived_net_ref = ref (Net.empty:thm Net.net);
val precond_bool_cs = computeLib.bool_compset ();



fun smallfoot_precondition_prove_internal___IS_POST_PROCESS_TERM t =
    pred_setSyntax.is_in t;

fun smallfoot_precondition_prove_internal___GET_POST_PROCESS_THM_TERM t =
    let
       val (v, s) = pred_setSyntax.dest_in t;
       val v_var = genvar (type_of v);
       val t' = pred_setSyntax.mk_in (v_var, s)
    in
       t'
    end;

val not_found_HOL_ERR = mk_HOL_ERR "smallfootLib" "smallfoot_precondition_prove_internal___REWRITE_CONV" "not found";



fun smallfoot_precondition_prove_internal___REWRITE_CONV t =
let
   val thms = (Net.match t (!precond_derived_net_ref));

   val thm_done_opt = SOME (tryfind (fn thm => if (lhs (concl thm) = t) then
				       (thm, true) else raise not_found_HOL_ERR) thms) 
		 handle HOL_ERR _ => 
                 SOME (tryfind (fn thm => (PART_MATCH lhs thm t, false)) thms) 
		 handle HOL_ERR _ => NONE

   val (thm,done) = if isSome thm_done_opt then (valOf thm_done_opt) else (REFL t, false);
in
   if done then thm else
   if (smallfoot_precondition_prove_internal___IS_POST_PROCESS_TERM t andalso
       not (isSome thm_done_opt)) then
         let
            val t' = smallfoot_precondition_prove_internal___GET_POST_PROCESS_THM_TERM t;            
            val thm = CHANGED_CONV 
	               (computeLib.CBV_CONV precond_cs THENC
                        TRY_CONV (DEPTH_CONV stringLib.string_EQ_CONV THENC
		                 computeLib.CBV_CONV precond_bool_cs)) t'
                   handle HOL_ERR _ => raise UNCHANGED;
            val _ = precond_derived_net_ref := Net.insert (t',thm) (!precond_derived_net_ref)
         in
            smallfoot_precondition_prove_internal___REWRITE_CONV t (*now a rewrite is present*)
         end
   else
      let
            val thm1 = CONV_RULE (RHS_CONV
	               (TRY_CONV (computeLib.CBV_CONV precond_cs) THENC
                        TRY_CONV (DEPTH_CONV stringLib.string_EQ_CONV THENC
		                 computeLib.CBV_CONV precond_bool_cs))) thm
                   handle HOL_ERR _ => raise UNCHANGED;
            val _ = precond_derived_net_ref := Net.insert (t,thm1) (!precond_derived_net_ref)
      in
            thm1
      end
   end;


fun smallfoot_precondition_prove_internal___imps [] t = 
    if t = T then TRUTH else raise UNCHANGED
  | smallfoot_precondition_prove_internal___imps (pre_cond::L) t =
    if t = T then TRUTH else
    let
        val pre_cond_thm = smallfoot_precondition_prove_internal___REWRITE_CONV pre_cond handle UNCHANGED => REFL t;


        val new_t = mk_imp (pre_cond, t);

        val imp_thm0 = SIMP_CONV std_ss [pre_cond_thm] new_t handle UNCHANGED => REFL new_t;
        val imp_thm1 = smallfoot_precondition_prove_internal___imps L 
			(rhs (concl imp_thm0));

	val imp_thm = EQ_MP (GSYM imp_thm0) imp_thm1
    in
        UNDISCH imp_thm
    end;


fun smallfoot_precondition_prove_internal imps t =
   if (is_conj t) then
      let val (t1,t2) = dest_conj t in
      CONJ (smallfoot_precondition_prove_internal imps t1)
	   (smallfoot_precondition_prove_internal imps t2)
      end
   else if (is_BAG_EVERY t) then
      let 
         val thm = smallfoot_precondition_prove_internal___REWRITE_CONV t;
         val t2 = rhs (concl thm)
         val thm2 = smallfoot_precondition_prove_internal imps t2

         val thm3 = EQ_MP (GSYM thm) thm2
      in
         thm3         
      end
   else if (is_SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS t) then
      let
         val thm = smallfoot_precondition_prove_internal___USED_VARS___STRENGTEN_CONV t
	 val (imp_term,_) = dest_imp (concl thm);
         val _ = if (imp_term = t) then raise UNCHANGED else ()
	 val imp_thm = smallfoot_precondition_prove_internal imps imp_term;
      in
	 MP thm imp_thm
      end 
   else
      let      
          val thm = smallfoot_precondition_prove_internal___REWRITE_CONV t handle UNCHANGED => REFL t;
	  val r = rhs (concl thm);
      in
	  if (r = T) then
             EQT_ELIM thm
          else 
	     let
		val thm0 = smallfoot_precondition_prove_internal___imps imps r
		val thm2 = EQ_MP (GSYM thm) thm0
             in
                thm2
             end
      end;


val tref = ref T;

(*
val t' = !tref
val m = NONE
val asm = []
*)


fun smallfoot_precondition_prove m asm t' =
    ((
    let
       val (imps', t) = strip_imp_only t';
       val imps = rev imps';
       val thm = smallfoot_precondition_prove_internal (imps@asm) t;
       val thm1 = foldr (fn (a,thm) => DISCH a (ADD_ASSUM a thm)) thm imps;
    in
       thm1
    end)
    handle UNCHANGED => raise (mk_HOL_ERR "smallfootLib" "smallfoot_precondition_prove" "UNCHANGED"))
    handle HOL_ERR e => (tref := t';if not (isSome m) then raise (HOL_ERR e) else
	                (print (valOf m);print "\n"; Raise (HOL_ERR e)));








fun smallfoot_precondition_prove___CLEAR_CACHE () =
let
   val _ = smallfoot_precondition_prove_internal___USED_VARS_cache_ref := Net.empty;
   val _ = precond_derived_net_ref := Net.empty;
in
  ()
end;


(*
smallfoot_precondition_prove___CLEAR_CACHE ();
map (fn a => smallfoot_precondition_prove_imp "XXX" a) (List.drop (prove_list,10))


dropn 200
val t = el 40 prove_list
!thms_ref;
DEPTH_CONSEQ_CONV FIRST_CONV []

val (t',asm_opt) = !failed_ref;

*)






fun smallfoot_HYP_PROVE m asms thm = 
    foldr (fn (t,thm) => if (mem t asms) then thm else
                         PROVE_HYP (smallfoot_precondition_prove (SOME ("smallfoot_HYP_PROVE "^m)) asms t) thm) thm (hyp thm);



fun smallfoot_precondition_prove_RULE m asms thm =
let
  val (imp_term,_) = dest_imp (concl thm);
  val imp_thm = smallfoot_precondition_prove (SOME m) asms imp_term;
  val thm1 = MP thm imp_thm;
in
  thm1
end;














fun SMALLFOOT_PROGAM_ABSTRACTION_CONV___val_arg sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_prog_val_arg p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val (v,body,arg) = dest_smallfoot_prog_val_arg p;
      val b_thm = sys xenv penv asm body;
      val b_thm2 = GEN_ASSUM v b_thm;

      val thm = ISPECL [xenv, penv, arg] FASL_PROGRAM_IS_ABSTRACTION___smallfoot_prog_val_arg;
      val thm2 = HO_MATCH_MP thm b_thm2;
   in
      thm2
   end;


fun SMALLFOOT_PROGAM_ABSTRACTION_CONV___local_var sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_prog_local_var p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val (v,body) = dest_smallfoot_prog_local_var p;
      val b_thm = sys xenv penv asm body;
      val b_thm2 = GEN_ASSUM v b_thm;

      val thm = ISPECL [xenv, penv] FASL_PROGRAM_IS_ABSTRACTION___smallfoot_prog_local_var;
      val thm2 = HO_MATCH_MP thm b_thm2;
   in
      thm2
   end;


(*
val mp_term_ref = ref T;
val p_ref = ref T;

val args_ref = ref (T,T,[TRUTH],T);
val (xenv,penv,asm, p) = !args_ref;
args_ref := (xenv,penv,asm,p);
*)

fun SMALLFOOT_PROGAM_ABSTRACTION_CONV___proc_call sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_prog_procedure_call p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val (pname,ref_args,val_args) = dest_smallfoot_prog_procedure_call p;
      val spec_thm = first (fn thm => let
				         val (penv', _, pname', _, _, _, _) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl thm) 
			 	      in
                                         (penv = penv') andalso (pname = pname')
                                      end handle HOL_ERR _ => false)
                           asm handle HOL_ERR _ => raise UNCHANGED;
      val (_, pre, _, post, a1, a2, a3) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl spec_thm);

      val thm = ISPECL [penv, pre, pname, post, a1, a2, a3, ref_args,
		        val_args]
		       FASL_PROGRAM_IS_ABSTRACTION___smallfoot_proc_call___quant;

      val (mp_term,_) = dest_imp (concl thm);
      val mp_thm = prove (mp_term, REWRITE_TAC [spec_thm, LENGTH]) handle HOL_ERR _ => 
		   (Raise_MSG_UNCHANGED ("SMALLFOOT_PROGAM_ABSTRACTION_CONV___proc_call, prove of mp_thm failed"));
      val thm2 = MP thm mp_thm;
   in
      thm2
   end;


fun SMALLFOOT_PROGAM_ABSTRACTION_CONV___parallel_proc_call sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_prog_parallel_procedure_call p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val (pname1,ref_args1,val_args1,
	   pname2,ref_args2,val_args2) = dest_smallfoot_prog_parallel_procedure_call p;

      val spec1_thm = first (fn thm => let
				         val (penv', _, pname', _, _, _, _) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl thm) 
			 	      in
                                         (penv = penv') andalso (pname1 = pname')
                                      end handle HOL_ERR _ => false)
                           asm handle HOL_ERR _ => raise UNCHANGED;
      val spec2_thm = first (fn thm => let
				         val (penv', _, pname', _, _, _, _) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl thm) 
			 	      in
                                         (penv = penv') andalso (pname2 = pname')
                                      end handle HOL_ERR _ => false)
                           asm handle HOL_ERR _ => raise UNCHANGED;

      val (_, pre1, _, post1, a11, a21, a31) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl spec1_thm);
      val (_, pre2, _, post2, a12, a22, a32) = dest_SMALLFOOT_SING_PROCEDURE_SPEC (concl spec2_thm);

      val thm = ISPECL [penv, pre1, pname1, post1, a11, a21, a31, ref_args1, val_args1,
                              pre2, pname2, post2, a12, a22, a32, ref_args2, val_args2]
		       FASL_PROGRAM_IS_ABSTRACTION___smallfoot_parallel_proc_call___quant;

      val (mp_term,_) = dest_imp (concl thm);
      val mp_thm = prove (mp_term, REWRITE_TAC [spec1_thm, spec2_thm, LENGTH]) handle HOL_ERR _ => 
          Raise_MSG_UNCHANGED "SMALLFOOT_PROGAM_ABSTRACTION_CONV___parallel_proc_call, prove of mp_thm failed!";
      val thm2 = MP thm mp_thm;
   in
      thm2
   end;




fun FASL_PROGRAM_ABSTRACTION_CONV___block sys xenv penv asm p =
   let      
      val _ = if (is_fasl_prog_block p) then () else raise UNCHANGED;
      val bodyL = dest_fasl_prog_block p;
      val (h,restBodyL) = listLib.dest_cons bodyL handle HOL_ERR _ => raise UNCHANGED;


      val thm_h = sys xenv penv asm h;
      val thm_rest = sys xenv penv asm (mk_fasl_prog_block restBodyL);


      val (_, _, _, p1) = dest_FASL_PROGRAM_IS_ABSTRACTION (concl thm_h);
      val (_, _, _, p2) = dest_FASL_PROGRAM_IS_ABSTRACTION (concl thm_rest);

      val (thm_rest', pL) = if (is_fasl_prog_block p2) then (thm_rest, dest_fasl_prog_block p2) else
                            let
                               val pL = listLib.mk_list ([p2], type_of p2);
                               val thm_rest' = ONCE_REWRITE_RULE [GSYM FASL_PROGRAM_IS_ABSTRACTION___block_intro] thm_rest; 
		            in
                               (thm_rest', pL)
                            end;
      val thm = ISPECL [xenv, penv, h, restBodyL,p1,pL] FASL_PROGRAM_IS_ABSTRACTION___block; 
      val thm1 = MP thm thm_h
      val thm2 = MP thm1 thm_rest'
   in
      thm2
   end;



fun FASL_PROGRAM_ABSTRACTION_CONV___cond sys xenv penv asm p =
   let      
      val _ = if (is_fasl_prog_cond p) then () else raise UNCHANGED;
      val (c,p1,p2) = dest_fasl_prog_cond p;

      val p1_thm = sys xenv penv asm p1;
      val p2_thm = sys xenv penv asm p2;
      
      val (_,_,_,p1') = dest_FASL_PROGRAM_IS_ABSTRACTION (concl p1_thm);
      val (_,_,_,p2') = dest_FASL_PROGRAM_IS_ABSTRACTION (concl p2_thm);


      val thm = ISPECL [xenv, penv, c, p1,p1',p2,p2'] FASL_PROGRAM_IS_ABSTRACTION___cond; 
      val thm1 = MP thm p1_thm
      val thm2 = MP thm1 p2_thm
   in
      thm2
   end;


fun FASL_PROGRAM_ABSTRACTION_CONV___while sys xenv penv asm p =
   let      
      val _ = if (is_fasl_prog_while_with_invariant p) then () else raise UNCHANGED;
      val (i,c,p) = dest_fasl_prog_while_with_invariant p;

      val thm = ISPECL [xenv, penv, i, c,p] FASL_PROGRAM_IS_ABSTRACTION___fasl_prog_while_with_invariant; 
      val thm1 = UNDISCH_ALL thm;
   in
      thm1
   end;




(*
val copy_refs = ref (T, T, [], T);
val (xenv,penv,asm,p) = !copy_refs
*)
fun SMALLFOOT_PROGRAM_ABSTRACTION_CONV___while sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_prog_while_with_invariant p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val (i,c,prog) = dest_smallfoot_prog_while_with_invariant p;
      val (wp,rp,d,pL,P) = dest_smallfoot_prop_internal_ap i;
	  
      val thm = ISPECL [penv, wp, rp, d, c, pL, P, prog]
		FASL_PROGRAM_IS_ABSTRACTION___smallfoot_prog_while_with_invariant2; 

      val thm1 = smallfoot_precondition_prove_RULE "SMALLFOOT_PROGRAM_ABSTRACTION_CONV___while" [] thm;
      val thm2 = UNDISCH thm1;
   in
      thm2
   end;




fun FASL_PROGRAM_ABSTRACTION_CONV___wrapper rewrite_thms conv sys xenv penv asm p =
   let
       val p' = rhs (concl (REWRITE_CONV rewrite_thms p));
       val thm = conv sys xenv penv asm p'
       val hypL = hyp thm;
       val thm1 = DISCH_ALL thm;
       val thm2 = REWRITE_RULE (map GSYM rewrite_thms) thm1;
       val thm3 = foldr (fn (_,thm) => UNDISCH thm) thm2 hypL;
       val (xenv', penv', p', _) = dest_FASL_PROGRAM_IS_ABSTRACTION (concl thm3);
       val _ = if (xenv = xenv') andalso (penv = penv') andalso (p' = p) then () else
	        Raise_MSG_UNCHANGED "FASL_PROGRAM_ABSTRACTION_CONV_wrapper discovered UNCHANGED!\n";
   in
       thm3
   end handle UNCHANGED => conv sys xenv penv asm p;



val smallfoot_progam_abstraction_convs = [
    SMALLFOOT_PROGAM_ABSTRACTION_CONV___val_arg,
    SMALLFOOT_PROGAM_ABSTRACTION_CONV___local_var,
    SMALLFOOT_PROGAM_ABSTRACTION_CONV___proc_call,
    SMALLFOOT_PROGAM_ABSTRACTION_CONV___parallel_proc_call,
    FASL_PROGRAM_ABSTRACTION_CONV___wrapper [smallfoot_prog_block_def] FASL_PROGRAM_ABSTRACTION_CONV___block,
    FASL_PROGRAM_ABSTRACTION_CONV___wrapper [smallfoot_prog_cond_def] FASL_PROGRAM_ABSTRACTION_CONV___cond,
    SMALLFOOT_PROGRAM_ABSTRACTION_CONV___while]





fun FASL_PROGRAM_HOARE_TRIPLE___CONSEQ_CONV L asm t =
   let
     val _ = if (is_FASL_PROGRAM_HOARE_TRIPLE t) then () else raise UNCHANGED;
     val (xenv, penv, pre, body, post) = dest_FASL_PROGRAM_HOARE_TRIPLE t;
     
     val thm = FASL_PROGRAM_ABSTRACTION_CONV L xenv penv asm body;

     val thm2 = ISPECL [xenv, penv, pre, body, post] FASL_PROGRAM_HOARE_TRIPLE_ABSTRACTION___INTRO;
     val thm3 = MATCH_MP thm2 thm;
   in
     thm3
   end;






fun SMALLFOOT_COND_HOARE_TRIPLE___CONSEQ_CONV L asm t =
   let
     val (penv, pre, body, post) = (dest_SMALLFOOT_COND_HOARE_TRIPLE t) 
	                           handle HOL_ERR _ => raise UNCHANGED;

     val thm = FASL_PROGRAM_ABSTRACTION_CONV L smallfoot_xenv_term penv asm body;
     val (_,_,p1,p2) = dest_FASL_PROGRAM_IS_ABSTRACTION (concl thm);
     val _ = if (p1 = p2) then raise UNCHANGED else ();
     val _ = if (p1 = body) then () else raise UNCHANGED;

     val thm2 = ISPECL [penv, pre, body, post, p2] SMALLFOOT_COND_HOARE_TRIPLE_ABSTRACTION___INTRO;
     val thm3 = MP thm2 thm;
   in
     thm3
   end;


fun SMALLFOOT_PROGRAM_HOARE_TRIPLE___prog_val_arg_CONSEQ_CONV t =
   (HO_PART_MATCH (snd o dest_imp) (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_val_arg) t) 
   handle HOL_ERR _ => raise UNCHANGED;

fun SMALLFOOT_PROGRAM_HOARE_TRIPLE___prog_local_var_CONSEQ_CONV t =
   (HO_PART_MATCH (snd o dest_imp) (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_local_var) t) 
   handle HOL_ERR _ => raise UNCHANGED;




(*
val L = smallfoot_progam_abstraction_convs;
val asm = imp_ante_thms;
val conv = DEPTH_CONSEQ_CONV (FASL_PROGRAM_HOARE_TRIPLE___CONSEQ_CONV L asm);
val preserve_hyps = (flatten (map hyp asm));
val t = imp_cons;
*)



fun DEPTH_FASL_PROGRAM_HOARE_TRIPLE___CONSEQ_CONV L asm = 
  let val hyps = flatten (map hyp asm) in
  CONJ_ASSUMPTIONS_CONSEQ_CONV 
      (DEPTH_CONSEQ_CONV (FASL_PROGRAM_HOARE_TRIPLE___CONSEQ_CONV L asm))
      (fn t => mem t hyps) end;




fun post_process_for_PROVE_HYP t NONE = NONE
  | post_process_for_PROVE_HYP t (SOME thm) = 
    if (concl thm = t) then (SOME thm) else
    if (is_eq(concl thm) andalso
	(lhs (concl thm) = t)) then
       (if (rhs (concl thm) = T) then SOME (EQT_ELIM thm) else
         SOME (UNDISCH (snd (EQ_IMP_RULE thm)))
       )
    else NONE;



fun prove_hyps pr thm =
   let
       val hyp_thms_opt = map (fn t => post_process_for_PROVE_HYP t (pr t) handle HOL_ERR _ => NONE) (hyp thm);
       val hyp_thms = map valOf (filter isSome hyp_thms_opt);
       val thm' = foldr (fn (thm_hyp, thm) => PROVE_HYP thm_hyp thm) thm hyp_thms
   in
       thm'
   end;


fun strip_conj_ASSUME t =
let
    val l = strip_conj t;
    val thms = map ASSUME l;
in
    EQT_ELIM (REWRITE_CONV thms t)
end;


val conj_strip_hyps =
   prove_hyps (fn t => if (is_conj t) then SOME (strip_conj_ASSUME t) else NONE);





fun RHS_CONV_RULE conv thm = 
((CONV_RULE (RHS_CONV conv)) thm) handle UNCHANGED => thm;






(*
use_smallfoot_pretty_printer := false
val thm_XXX = thm8;
val thm_YYY = IMP_CONV_RULE (DEPTH_CONV smallfoot_prop_internal_CONV) thm_XXX;

val t = !tref;

val t = ``
smallfoot_prop_internal ({| |},{| |})
  ({r},{smallfoot_var "_tf"; smallfoot_var "_b"}) T [] {| |}
  (smallfoot_ap_star
     (smallfoot_ap_star
        (smallfoot_ap_points_to (smallfoot_ae_var r)
           (FEMPTY |+
            (smallfoot_tag "tl",
             smallfoot_ae_var (smallfoot_var "_tf"))))
        (smallfoot_ap_list_seg (smallfoot_tag "tl")
           (smallfoot_ae_var (smallfoot_var "_tf"))
           (smallfoot_ae_var (smallfoot_var "_b"))))
     (smallfoot_ap_points_to (smallfoot_ae_var (smallfoot_var "_b"))
        (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_var r))))``

*)

local
    val conv1 = COND_REWRITE_CONV [smallfoot_prop_internal___VARS_TO_BAGS];
    val conv2 = COND_REWR_CONV smallfoot_prop_internal___VARS_TO_BAGS___END;
    val conv3 = COND_REWRITE_CONV [smallfoot_prop_internal___PROP_TO_BAG];
    val conv4 = COND_REWR_CONV smallfoot_prop_internal___PROP_TO_BAG___END;
    val conv5 = COND_REWRITE_CONV [smallfoot_prop_internal___PROG_PROP_TO_BAG];
    val conv6 = REWRITE_CONV [SMALLFOOT_P_PROPOSITION_EVAL___REWRITES,
		              SMALLFOOT_P_EXPRESSION_EVAL_def];
    val conv7 = REWRITE_CONV [GSYM smallfoot_prop_def]
in

fun smallfoot_prop_internal_CONV t =
    let
        val _ = if (is_smallfoot_prop_internal t) then () else raise UNCHANGED;

        val thm1 = (conv1 t) handle UNCHANGED => REFL t;
        val thm2 = RHS_CONV_RULE conv2 thm1
                   handle HOL_ERR _ => thm1;

        val thm4 = RHS_CONV_RULE conv3 thm2;
        val (_,_,_,_,_,_,_,p) = dest_smallfoot_prop_internal (rhs (concl thm4))              
        val thm5 = if (p = smallfoot_ap_emp_term) then thm4 else
                   RHS_CONV_RULE conv4 thm4;

        val thm8 = RHS_CONV_RULE conv5 thm5;
        val thm9 = RHS_CONV_RULE conv6 thm8;

        val thm11 = RHS_CONV_RULE conv7 thm9;
        val thm12 = smallfoot_HYP_PROVE "smallfoot_prop_internal_CONV" [] thm11; 
    in
	thm12
    end handle HOL_ERR e => 
	let
          val _ = print "Could not convert term:\n";
          val _ = print_term t;
          val _ = print "\n\n---------------------------------------\n\n";
	in 
	  raise (HOL_ERR e)
        end;	   
end;

(*
val t = ``
smallfoot_prop_internal
  (({| |} :smallfoot_var -> num),({| |} :smallfoot_var -> num))
  ({smallfoot_var "x"; smallfoot_var "z"},({} :smallfoot_var -> bool))
  (ALL_DISTINCT ([] :smallfoot_var list))
  ([] :smallfoot_p_proposition list)
  ({| |} :smallfoot_a_proposition -> num)
  (smallfoot_ap_star
     (smallfoot_ap_points_to (smallfoot_ae_var (smallfoot_var "x"))
        ((FEMPTY :smallfoot_tag |-> smallfoot_a_expression) |+
         (smallfoot_tag "c",smallfoot_ae_const (4 :num))))
     (smallfoot_ap_points_to (smallfoot_ae_var (smallfoot_var "z"))
        ((FEMPTY :smallfoot_tag |-> smallfoot_a_expression) |+
         (smallfoot_tag "c",smallfoot_ae_const (5 :num)))))``;
*)




val extract_common_antecedent_THM = prove (``(!x. (c x /\ p1 x) ==> p2 x) ==>
		              ((!x. (c x ==> p1 x)) ==>
			      (!x. (c x ==> p2 x)))``, PROVE_TAC[]);
val remove_second_precond_THM = prove (``!c d e.
					 (((!x. c x ==> d x) ==> e) ==>
				         ((!x. d x) ==> e))``,
				       SIMP_TAC std_ss [])





fun IMP_CONV_RULE c = CONV_RULE (RATOR_CONV (RAND_CONV c));





fun smallfoot_prog_best_local_action___CONV t =
let
   val _ = if (is_smallfoot_prog_best_local_action t) then () else raise UNCHANGED;
   val thm = ONCE_REWRITE_CONV [smallfoot_prog_best_local_action___COND_CHOOSE_REWRITE] t
in
  thm
end;


fun smallfoot_proc_call_abstraction___CONV t =
let
   val _ = if (is_smallfoot_proc_call_abstraction t) then () else raise UNCHANGED;
   val thm = (SIMP_CONV list_ss [smallfoot_proc_call_abstraction_def,
	                         smallfoot_choose_const_best_local_action___COND_CHOOSE_REWRITE]) t
in
  thm
end;


fun smallfoot_parallel_proc_call_abstraction___CONV t =
let
   val _ = if (is_smallfoot_parallel_proc_call_abstraction t) then () else raise UNCHANGED;
   val thm = (SIMP_CONV list_ss [smallfoot_parallel_proc_call_abstraction_def,
	                         smallfoot_choose_const_best_local_action___COND_CHOOSE_REWRITE___cond_star]) t
in
  thm
end;






fun SMALLFOOT_PROGRAM_ABSTRACTION_CONV___smallfoot_cond_choose_const___smallfoot_cond_star sys xenv penv asm p =
   let      
      val _ = if (is_smallfoot_cond_choose_const_best_local_action p) then () else raise UNCHANGED;
      val _ = if (xenv = smallfoot_xenv_term) then () else raise UNCHANGED;
      val thm1 = (HO_PART_MATCH (rand o rator)
                 (SPEC_ALL FASL_PROGRAM_IS_ABSTRACTION___smallfoot_cond_choose_const_best_local_action___smallfoot_cond_star) p)
                 handle HOL_ERR _ => raise UNCHANGED;
   in
      thm1
   end;






val smallfoot_choose_const_best_local_action___CONV =
    (CHANGED_CONV smallfoot_proc_call_abstraction___CONV) ORELSEC
    (CHANGED_CONV smallfoot_prog_best_local_action___CONV) ORELSEC
    (CHANGED_CONV smallfoot_parallel_proc_call_abstraction___CONV);






val precond_cond_cs = reduceLib.num_compset ();
val _ = listSimps.list_rws precond_cond_cs;
val _ = computeLib.add_thms [SMALLFOOT_HOARE_TRIPLE_def,
		   smallfoot_prop_input_ap_distinct___internal_REWRITE] precond_cond_cs


val SMALLFOOT_INPUT_FILE___PRECOND_CONV1 =
REWRITE_CONV [EVERY_DEF] THENC
DEPTH_CONV pairLib.PAIRED_BETA_CONV THENC
REWRITE_CONV [GSYM SMALLFOOT_SING_PROCEDURE_SPEC_def] THENC
REWRITE_CONV [SMALLFOOT_HOARE_TRIPLE_INST_def,                  
              SMALLFOOT_INFERENCE_smallfoot_input_preserve_names_wrapper] THENC

DEPTH_CONV LIST_UNROLE_GIVEN_ELEMENT_NAMES_CONV THENC
REDEPTH_CONV (RIGHT_AND_EXISTS_CONV ORELSEC
              LEFT_AND_EXISTS_CONV) THENC
REDEPTH_CONV LEFT_IMP_EXISTS_CONV THENC
DEPTH_CONV Unwind.UNWIND_FORALL_CONV THENC
DEPTH_CONV pairLib.PAIRED_BETA_CONV THENC
computeLib.CBV_CONV precond_cond_cs;




(*
val t = Pprogram2term (parse file);
use_smallfoot_pretty_printer := true;
use_smallfoot_pretty_printer := false;


val examplesDir = concat Globals.HOLDIR "/examples/separationLogic/src/smallfoot/EXAMPLES/"
val file = concat examplesDir "list.sf";
val t = parse_smallfoot_file file; 
*)




val time_ref = ref (Time.now());
fun time_step_init () = time_ref := (Time.now());
fun time_step m =
   let
      val d_time = Time.- (Time.now(), !time_ref);
      val _ = print m;
      val _ = print ": ";
      val _ = print (Time.toString d_time);
      val _ = print "\n";       
   in
      ()
   end;


fun SMALLFOOT_INPUT_FILE___CONSEQ_CONV t =
let
   (*Eliminate Recursion*)
   val p_specs_term = dest_SMALLFOOT_INPUT_FILE t;
   val thm1 = ISPEC p_specs_term SMALLFOOT_INPUT_FILE___INFERENCE;

   (*Ensure that all used procedure names are different*)
   val thm2 = CONV_RULE ANTE_CONJ_CONV thm1; 
   val thm3 = smallfoot_precondition_prove_RULE "SMALLFOOT_INPUT_FILE___CONSEQ_CONV" [] thm2;


   val thm4 = IMP_CONV_RULE SMALLFOOT_INPUT_FILE___PRECOND_CONV1 thm3;

   (*replace function calls and loops*)
   val (imp_term,_) = dest_imp (concl thm4);
   val (v, imp_body) = dest_forall imp_term;
   val (imp_ante, imp_cons) = dest_imp imp_body;
   val imp_ante_thms = map ASSUME (strip_conj imp_ante);
   val imp_cons_thm = DEPTH_FASL_PROGRAM_HOARE_TRIPLE___CONSEQ_CONV smallfoot_progam_abstraction_convs imp_ante_thms imp_cons;
   val imp_thm_term = let
                         val org_term = imp_term;
			 val (new_term_concl,_) = dest_imp (concl imp_cons_thm);
                         val new_term_body = mk_imp (imp_ante, new_term_concl);
			 val new_term = mk_forall (v, new_term_body)
		      in
                         mk_imp (new_term, org_term)
		      end;

   val imp_thm = prove (imp_thm_term,
(*			set_goal ([], imp_thm_term)*)
			HO_MATCH_MP_TAC extract_common_antecedent_THM THEN
			GEN_TAC THEN STRIP_TAC THEN
			MP_TAC (DISCH_ALL imp_cons_thm) THEN
			ASM_REWRITE_TAC[]);

   val thm5 = IMP_TRANS imp_thm thm4;


   (*get rid of now unneeded function specifications*)
   val thm6 = HO_MATCH_MP remove_second_precond_THM thm5;

   (*Simplify specification terms*)
   val thm7 = IMP_CONV_RULE (REWRITE_CONV [GSYM SMALLFOOT_HOARE_TRIPLE_def,
                      SMALLFOOT_COND_HOARE_TRIPLE_INTRO]) thm6;
   val thm8 = IMP_CONV_RULE (DEPTH_CONV smallfoot_choose_const_best_local_action___CONV) thm7;
   val thm9 = IMP_CONV_RULE (DEPTH_CONV smallfoot_prop_internal_CONV) thm8;

   val thm10= IMP_CONSEQ_CONV_RULE (
		  DEPTH_CONSEQ_CONV (SMALLFOOT_COND_HOARE_TRIPLE___CONSEQ_CONV
					(SMALLFOOT_PROGRAM_ABSTRACTION_CONV___smallfoot_cond_choose_const___smallfoot_cond_star::smallfoot_progam_abstraction_convs) [])) thm9;

   (*Eliminate local variables and call-by value parameters*)
   val thm11 = IMP_CONSEQ_CONV_RULE (DEPTH_CONSEQ_CONV
					(FIRST_CONSEQ_CONV [
					 SMALLFOOT_PROGRAM_HOARE_TRIPLE___prog_val_arg_CONSEQ_CONV,
					 SMALLFOOT_PROGRAM_HOARE_TRIPLE___prog_local_var_CONSEQ_CONV])) thm10
in
   thm11
end;


(*
temp_add_smallfoot_pp();
use_smallfoot_pretty_printer := true;

val examplesDir = concat Globals.HOLDIR "/examples/separationLogic/src/smallfoot/EXAMPLES/"

val file = concat examplesDir "list.sf";
val t = parse_smallfoot_file file; 
val t_initial_thm = SMALLFOOT_INPUT_FILE___CONSEQ_CONV t;


set_goal([], t);
CONSEQ_CONV_TAC SMALLFOOT_INPUT_FILE___CONSEQ_CONV


REPEAT STRIP_TAC

rotate 1


val (_, t) = top_goal()
quietdec := false

*)


fun smallfoot_ae_var___is_equals_const v t =
   let
      val (l,r) = dest_smallfoot_ap_equal t;
      val v' = dest_smallfoot_ae_var l;
      val c = dest_smallfoot_ae_const_null r;
   in
      if (v' = v) then SOME c else NONE
   end handle HOL_ERR _ => NONE;




fun find_first_num p ex n [] = NONE
  | find_first_num p ex n (e::es) =
    let
       val res = (if mem n ex then NONE else p n e) handle HOL_ERR _ => NONE;
    in
    if isSome res then
       SOME (n, e, valOf res)
    else
        find_first_num p ex (n+1) es
    end;




fun SMALLFOOT_COND_HOARE_TRIPLE___find_prop_in_precond p excluded t =
   let
      val (penv, pre, prog, post) = dest_SMALLFOOT_COND_HOARE_TRIPLE t;
      val (wpb,rpb,sfb) = dest_smallfoot_prop pre;
      val (sfs, _) = bagSyntax.dest_bag sfb;
   in
      find_first_num p excluded 0 sfs
   end

(*
val t = snd (top_goal())
val t = sfb;
DB.find "BAG_INSERT"
temp_add_smallfoot_pp()
use_smallfoot_pretty_printer := true

*)

fun BAG_RESORT___BRING_TO_FRONT_CONV 0 t = REFL t
  | BAG_RESORT___BRING_TO_FRONT_CONV n t =
    let
	val (t1,t2) = dest_comb t;
        val thm2 = BAG_RESORT___BRING_TO_FRONT_CONV (n-1) t2;
	val thm3 = AP_TERM t1 thm2;
        val t3 = rhs (concl thm3);
        val thm4 = PART_MATCH lhs bagTheory.BAG_INSERT_commutes t3
    in
        TRANS thm3 thm4
    end;


fun BAG_RESORT_CONV [] t = REFL t
|   BAG_RESORT_CONV [n] t = BAG_RESORT___BRING_TO_FRONT_CONV n t
|   BAG_RESORT_CONV (n::n2::ns) t = 
let
   val thm1 = BAG_RESORT___BRING_TO_FRONT_CONV n t;
  
   val (t1,t2) = dest_comb (rhs (concl thm1));
   val ns' = map (fn m => if (n < m) then m - 1 else m) (n2::ns);
   val thm2 = BAG_RESORT_CONV ns' t2;

   val thm3 = AP_TERM t1 thm2;
in
   TRANS thm1 thm3
end;


(*
fun SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV pre_conv t =
let
   val (penv, pre, prog, post) = dest_SMALLFOOT_COND_HOARE_TRIPLE t;
   val (wpb,rpb,sfb) = dest_smallfoot_prop pre;

   val thm0 = SPECL [penv,wpb,rpb,sfb,prog,post] SMALLFOOT_COND_HOARE_TRIPLE___COND_PROP

   val pre_cond = (fst o dest_imp o fst o dest_imp o snd o strip_forall) (concl thm0)
   val thm1 = pre_conv pre_cond sfb;
   val sfb' = rhs (concl thm1);
   val thm2 = DISCH pre_cond (ADD_ASSUM pre_cond thm1)

   val thm3 = MP (SPEC sfb' thm0) thm2;
in
   thm3
end;
*)



fun SMALLFOOT_COND_PROP___IMP___REFL_CONV t =
   ISPEC t SMALLFOOT_COND_PROP___IMP___REFL;

fun SMALLFOOT_COND_PROP___EQUIV___REFL_CONV t =
   ISPEC t SMALLFOOT_COND_PROP___EQUIV___REFL;


(*
   val thm5 = CONV_RULE (IMP_ANTE_CONV (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV 
                 smallfoot_ap_var_update___CONV)) thm4;

val t = (fst o dest_imp) (concl thm4)
val pre_conv = smallfoot_ap_var_update___CONV

*)



val SMALLFOOT_COND_HOARE_TRIPLE___EXISTS_ADD_COND_FALSE___REWRITE =
Ho_Rewrite.REWRITE_CONV [SMALLFOOT_COND_HOARE_TRIPLE___COND_EXISTS,
		  SMALLFOOT_COND_HOARE_TRIPLE___ADD_COND,
		  SMALLFOOT_COND_HOARE_TRIPLE___cond_prop_false] THENC
SIMP_CONV std_ss []



fun SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV pre_conv t =
let
   val (penv, pre, prog, post) = dest_SMALLFOOT_COND_HOARE_TRIPLE t;
   val thm0 = pre_conv pre;
   val term0 = concl thm0;
in
   if (is_eq term0) then
      let
         val thm1 = AP_TERM (mk_comb (SMALLFOOT_COND_HOARE_TRIPLE_term, penv)) thm0;
         val thm2 = AP_THM thm1 prog;
         val thm3 = AP_THM thm2 post;
         val thm4 = CONV_RULE (RHS_CONV SMALLFOOT_COND_HOARE_TRIPLE___EXISTS_ADD_COND_FALSE___REWRITE) thm3
      in
         thm4 
      end
   else if (is_SMALLFOOT_COND_PROP___IMP term0) then
      let
         val (p1,p2) = dest_SMALLFOOT_COND_PROP___IMP (concl thm0);
         val thm1 = SPECL [penv,p1,p2,prog,post] SMALLFOOT_COND_HOARE_TRIPLE___COND_PROP_IMP
         val thm2 = MP thm1 thm0;
         val thm3 = CONV_RULE (RATOR_CONV (RAND_CONV SMALLFOOT_COND_HOARE_TRIPLE___EXISTS_ADD_COND_FALSE___REWRITE)) thm2
      in
         thm3 
      end
   else if (is_SMALLFOOT_COND_PROP___EQUIV term0) then
      let
         val (p1,p2) = dest_SMALLFOOT_COND_PROP___EQUIV (concl thm0);
         val thm1 = SPECL [penv,p1,p2,prog,post] SMALLFOOT_COND_HOARE_TRIPLE___COND_PROP_EQUIV
         val thm2 = MP thm1 thm0;
         val thm3 = CONV_RULE (RHS_CONV SMALLFOOT_COND_HOARE_TRIPLE___EXISTS_ADD_COND_FALSE___REWRITE) thm2
      in
         thm3 
      end
   else raise UNCHANGED
end;


val IMP_ANTE_CONV = RATOR_CONV o RAND_CONV;


fun smallfoot_prop___COND_RESORT_CONV rl = RAND_CONV (BAG_RESORT_CONV rl);


fun SMALLFOOT_COND_HOARE_TRIPLE___resort_precond_CONV rl =
    SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___COND_RESORT_CONV rl)



val FINITE_BAG_EMPTY =  CONJUNCT1 bagTheory.FINITE_BAG_THM
val BAG_IMAGE_EMPTY = GEN_ALL bagTheory.BAG_IMAGE_EMPTY



fun BAG_IMAGE_CONV___FINITE t =
   let val (f,b) = dest_BAG_IMAGE t in
   if (is_EMPTY_BAG b) then
      let
         val bag_type = bagSyntax.base_type b
	 val finite_thm = INST_TYPE [alpha |-> bag_type] FINITE_BAG_EMPTY;
	 val bag_thm = ISPEC f BAG_IMAGE_EMPTY
      in
	 (finite_thm, bag_thm)
      end
   else
      let
         val (e,b') = bagSyntax.dest_insert b;
         val t' = mk_BAG_IMAGE f b'
         val (finite_thm, bag_thm) = BAG_IMAGE_CONV___FINITE t';
(*
         val finite_thm = mk_thm ([], ``FINITE_BAG ^b'``);
         val bag_thm = REFL t';
*)
	 val finite_thm2 = SPEC e (MP (ISPEC b' bagTheory.FINITE_BAG_INSERT) finite_thm);
	 val bag_thm' = MP (ISPECL [f,e,b']
	       (GEN_ALL bagTheory.BAG_IMAGE_FINITE_INSERT)) finite_thm
         val bag_thm2 = SUBST_MATCH bag_thm bag_thm'			   
      in
         (finite_thm2, bag_thm2)
      end
   end


val BAG_IMAGE_CONV = snd o BAG_IMAGE_CONV___FINITE;





val smallfoot_ap_var_update___THMS =
   BODY_CONJUNCTS smallfoot_ap_var_update___REWRITES;

val smallfoot_ae_var_update___THMS =
   BODY_CONJUNCTS smallfoot_ae_var_update_EVAL;



val smallfoot_ap_var_update___ASM_CONV = 
   REDEPTH_CONV (CHANGED_CONV (GUARDED_COND_REWRITE_CONV (fn t => is_smallfoot_ap_var_update t orelse
						 is_smallfoot_ae_var_update t)
				      [smallfoot_ap_var_update___REWRITES,
	                               smallfoot_ae_var_update_EVAL]) ORELSEC
                 CHANGED_CONV (REWRITE_CONV[FMAP_MAP_FEMPTY, FMAP_MAP_FUPDATE]))




fun SMALLFOOT_PROP___WEAK_COND___EQUIV_CONV pre_conv t = 
let
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val thm0 = SPECL [wpb,rpb,sfb] SMALLFOOT_COND_PROP___EQUIV___WEAK_COND_REWRITE
   val pre_cond = (fst o dest_imp o fst o dest_imp o snd o strip_forall) (concl thm0)
   val thm1 = pre_conv pre_cond sfb;
   val sfb' = rhs (concl thm1);
   val thm2 = DISCH pre_cond (ADD_ASSUM pre_cond thm1)
   val thm3 = MP (SPEC sfb' thm0) thm2;
in
   thm3
end;


fun smallfoot_ap_var_update___INTERNAL_CONV asm t = 
   let
      val thm1 = (DEPTH_CONV BAG_IMAGE_CONV THENC REWRITE_CONV [SMALLFOOT_P_EXPRESSION_EVAL_def]) t 
      val thm2 = CONV_RULE (RHS_CONV smallfoot_ap_var_update___ASM_CONV) thm1
      val thm3 = smallfoot_HYP_PROVE "smallfoot_ap_var_update___CONV" [asm] thm2
   in
      thm3
   end;


val smallfoot_ap_var_update___CONV = 
   SMALLFOOT_PROP___WEAK_COND___EQUIV_CONV smallfoot_ap_var_update___INTERNAL_CONV;



(*
val smallfoot_prop___COND_INTRO___EQUIV_CONV v t =
let
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val thm0 = ISPECL [v, wpb,rpb,sfb] smallfoot_prop___CONST_INTRO

in
end

*)










fun get_const_name_for_var v =
let
   val v_st = if is_smallfoot_var v then stringLib.fromHOLstring (dest_smallfoot_var v) else
              if is_var v then fst (dest_var v) else "c";
in
  v_st ^ "_const"
end;





fun SMALLFOOT_COND_HOARE_TRIPLE___CONST_INTRO v c_name_opt t =
let
   val foundOpt = SMALLFOOT_COND_HOARE_TRIPLE___find_prop_in_precond (K (smallfoot_ae_var___is_equals_const v)) [] t
in
   if isSome(foundOpt) then
       let
	   val (pos,_,_) = valOf foundOpt
       in
	   (false, SMALLFOOT_COND_HOARE_TRIPLE___resort_precond_CONV [pos] t)
       end
   else
      let
	  (*instantiate theorem*)
	  val thm0 = SPEC_ALL (SPEC v SMALLFOOT_COND_INFERENCE___CONST_INTRO)
	  val thm1 = PART_MATCH (lhs o snd o dest_imp) thm0 t

          (*remove precondition*)
	  val thm2 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_HOARE_TRIPLE___CONST_INTRO" [] thm1			              

	  (*use nice new constant name*)
	  val c_name = if (isSome c_name_opt) then valOf c_name_opt else
		       get_const_name_for_var v;
          val thm3 = CONV_RULE (RHS_CONV (RENAME_VARS_CONV [c_name])) thm2
      in
	  (true, thm3)
      end
end



fun dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t = 
let
   val (_, _, prog, _) = dest_SMALLFOOT_COND_HOARE_TRIPLE t;
   val (c1, _) = dest_FASL_PROG_SEQ prog
in
   c1
end


fun dummy_conv t = let
   val v = mk_var ("XXX", type_of t);
   val t' = mk_eq (t, v);
in
   mk_thm ([], t')
end;




val SMALLFOOT_COND_INFERENCE___block_to_seq_CONV =
   PART_MATCH lhs SMALLFOOT_COND_HOARE_TRIPLE___BLOCK_FIRST_SPLIT;




val FORALL_SIMP_CONV =
    let val thm = SPEC_ALL boolTheory.FORALL_SIMP in
    HO_PART_MATCH lhs thm
    end



fun COND_FORALL_RULE c thm =
   if c then 
      let
	 val (v,t'') = dest_forall (rhs (concl thm))
      in
	 (t'', GEN_IMP v)
      end
   else
      (rhs (concl thm), I)


(*
val (_,t) = top_goal()
val t = (fst o dest_imp o concl o SMALLFOOT_COND_INFERENCE_CONV___cond) t

val t = snd (dest_conj t)
*)

fun SMALLFOOT_COND_INFERENCE_CONV___assign t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val (v, e) = dest_smallfoot_prog_assign command;


   val (quant, thm1) = SMALLFOOT_COND_HOARE_TRIPLE___CONST_INTRO v NONE t';
   val thm2 = TRANS thm0 thm1;
   val (t'', thm2_func) = COND_FORALL_RULE quant thm2;

   val thm3 = PART_MATCH (snd o dest_imp o snd o dest_imp)
                         (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_assign)
	                 t'';
   val thm4 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___prog_assign" [] thm3;


   val thm5 = CONV_RULE (IMP_ANTE_CONV (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV 
                 smallfoot_ap_var_update___CONV)) thm4;

   val thm6 = thm2_func thm5;
   val thm7 = SUBST_MATCH (GSYM thm2) thm6 

   val thm8 = CONV_RULE (IMP_ANTE_CONV FORALL_SIMP_CONV) thm7 handle HOL_ERR _ => thm7
in
   thm8
end;



fun SMALLFOOT_COND_INFERENCE_CONV___new t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val v = dest_smallfoot_prog_new command;

   val (quant, thm1) = SMALLFOOT_COND_HOARE_TRIPLE___CONST_INTRO v NONE t';
   val thm2 = TRANS thm0 thm1;
   val (t'', thm2_func) = COND_FORALL_RULE quant thm2;

   val thm3 = PART_MATCH (snd o dest_imp o snd o dest_imp)
                         (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_new)
	                 t''

   val thm4 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___prog_assign" [] thm3;


   val thm5 = CONV_RULE (IMP_ANTE_CONV (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV 
                 smallfoot_ap_var_update___CONV)) thm4;

   val thm6 = thm2_func thm5;
   val thm7 = SUBST_MATCH (GSYM thm2) thm6 

   val thm8 = CONV_RULE (IMP_ANTE_CONV FORALL_SIMP_CONV) thm7 handle HOL_ERR _ => thm7
in
   thm8
end;





fun SMALLFOOT_COND_INFERENCE_CONV___cond t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);

   val thm1 = PART_MATCH (snd o dest_imp o snd o dest_imp) 
                         (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_cond)
                         t';

   val thm2 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___prog_assign" [] thm1;
   val thm3 = CONV_RULE (IMP_ANTE_CONV (REWRITE_CONV [SMALLFOOT_P_PROPOSITION_EVAL___REWRITES,
			                              SMALLFOOT_P_EXPRESSION_EVAL_def,
			                              SMALLFOOT_COND_HOARE_TRIPLE___fasl_prog_seq___block,
			                              SMALLFOOT_COND_HOARE_TRIPLE___fasl_prog_seq___block_block,
			                              APPEND])) thm2;

   val thm4 = SUBST_MATCH (GSYM thm0) thm3 
in
   thm4
end;

















fun MAKE___IMP___RULE thm =
   if (is_imp (concl thm)) then 
      thm
   else if (is_eq (concl thm)) then
      snd (EQ_IMP_RULE thm)
   else raise (mk_HOL_ERR "smallfootLib" "MAKE___IMP___RULE" "Wrong Input!")



fun MAKE___SMALLFOOT_COND_PROP___IMP___RULE thm =
   if (is_SMALLFOOT_COND_PROP___IMP (concl thm)) then 
      thm
   else if (is_eq (concl thm)) then
      let
         val (l,r) = dest_eq (concl thm);
         val thm1 = ISPECL [l,r] SMALLFOOT_COND_PROP___IMP___REFL___COMPUTE;
	 val thm2 = MP thm1 thm
      in
         thm2
      end
   else if (is_SMALLFOOT_COND_PROP___EQUIV (concl thm)) then
      let
         val (l,r) = dest_SMALLFOOT_COND_PROP___EQUIV (concl thm);
         val thm1 = ISPECL [l,r] SMALLFOOT_COND_PROP___EQUIV_IMP___COMPUTE;
	 val thm2 = MP thm1 thm
      in
         thm2
      end
   else
      raise (mk_HOL_ERR "smallfootLib" "MAKE___SMALLFOOT_COND_PROP___IMP___RULE" "Wrong Input!")



fun MAKE___SMALLFOOT_COND_PROP___EQUIV___RULE thm =
   if (is_SMALLFOOT_COND_PROP___EQUIV (concl thm)) then
      thm
   else if (is_eq (concl thm)) then
      let
         val (l,r) = dest_eq (concl thm);
         val thm1 = ISPECL [l,r] SMALLFOOT_COND_PROP___EQUIV___REFL___COMPUTE;
	 val thm2 = MP thm1 thm
      in
         thm2
      end
   else
      raise (mk_HOL_ERR "smallfootLib" "MAKE___SMALLFOOT_COND_PROP___EQUIV___RULE" "Wrong Input!")




fun SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm1 thm2 =
let
   val thm1' = MAKE___SMALLFOOT_COND_PROP___IMP___RULE thm1;
   val thm2' = MAKE___SMALLFOOT_COND_PROP___IMP___RULE thm2;

   val (p1,p2) = dest_SMALLFOOT_COND_PROP___IMP (concl thm1');
   val (_,p3) = dest_SMALLFOOT_COND_PROP___IMP (concl thm2');

   val thm3 = ISPECL [p1,p2,p3] SMALLFOOT_COND_PROP___IMP___TRANS;
   val thm4 = MP thm3 thm1';
   val thm5 = MP thm4 thm2';
in
   thm5
end;


fun SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm2 =
let
   val thm1' = MAKE___SMALLFOOT_COND_PROP___EQUIV___RULE thm1;
   val thm2' = MAKE___SMALLFOOT_COND_PROP___EQUIV___RULE thm2;

   val (p1,p2) = dest_SMALLFOOT_COND_PROP___EQUIV (concl thm1');
   val (_,p3) = dest_SMALLFOOT_COND_PROP___EQUIV (concl thm2');

   val thm3 = ISPECL [p1,p2,p3] SMALLFOOT_COND_PROP___EQUIV___TRANS;
   val thm4 = MP thm3 thm1';
   val thm5 = MP thm4 thm2';
in
   thm5
end;



fun SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV___TRANS_RULE thm1 thm2 =
let
   val t1 = concl thm1;
   val t2 = concl thm2;
in
   if (is_eq t1 andalso is_eq t2) then
      TRANS thm1 thm2
   else if (is_eq t1 orelse is_SMALLFOOT_COND_PROP___EQUIV t1) andalso
           (is_eq t2 orelse is_SMALLFOOT_COND_PROP___EQUIV t2) then
      SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm2
   else
      SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm1 thm2   
end;


fun dest_SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV t = 
   dest_eq t handle HOL_ERR _ =>
   dest_SMALLFOOT_COND_PROP___IMP t handle HOL_ERR _ =>
   dest_SMALLFOOT_COND_PROP___EQUIV t;



fun SMALLFOOT_COND_PROP___DEPTH_CONV___EXISTS conv t =
let
   val (v,b) = dest_COND_PROP___EXISTS t;
   val thm = conv b
in
   if (is_eq (concl thm)) then
      AP_TERM (fst (dest_comb t)) (ABS v thm)
   else if (is_SMALLFOOT_COND_PROP___IMP (concl thm)) then
      let
	 val thm1 = GEN v thm;
	 val thm2 = HO_MATCH_MP (SPEC_ALL SMALLFOOT_COND_PROP___IMP___EXISTS) thm1;
      in
	 thm2
      end
   else if (is_SMALLFOOT_COND_PROP___EQUIV (concl thm)) then
      let
	 val thm1 = GEN v thm;
	 val thm2 = HO_MATCH_MP (SPEC_ALL SMALLFOOT_COND_PROP___EQUIV___EXISTS) thm1;
      in
	 thm2
      end
   else raise UNCHANGED
end


fun SMALLFOOT_COND_PROP___DEPTH_CONV___ADD_COND conv t =
let
   val (cond,rest) = dest_COND_PROP___ADD_COND t;
   val thm = conv rest
in
   if (is_eq (concl thm)) then
      AP_TERM (fst (dest_comb t)) thm
   else if (is_SMALLFOOT_COND_PROP___IMP (concl thm)) then
      let
	 val (p1,p2) = dest_SMALLFOOT_COND_PROP___IMP (concl thm);
	 val thm1 = MP (SPECL [p1,p2,cond] SMALLFOOT_COND_PROP___IMP___ADD_COND) thm;
      in
	 thm1
      end
   else if (is_SMALLFOOT_COND_PROP___EQUIV (concl thm)) then
      let
	 val (p1,p2) = dest_SMALLFOOT_COND_PROP___EQUIV (concl thm);
	 val thm1 = MP (SPECL [p1,p2,cond] SMALLFOOT_COND_PROP___EQUIV___ADD_COND) thm;
      in
	 thm1
      end
   else raise UNCHANGED
end



fun SMALLFOOT_COND_PROP___DEPTH_CONV conv t =
   let
      val depth_conv = if (is_COND_PROP___ADD_COND t) then
			   SMALLFOOT_COND_PROP___DEPTH_CONV___ADD_COND
		       else if (is_COND_PROP___EXISTS t) then
                           SMALLFOOT_COND_PROP___DEPTH_CONV___EXISTS
                       else (fn x => fn t => (raise UNCHANGED));

      val thm = ((QCHANGED_CONV (depth_conv (SMALLFOOT_COND_PROP___DEPTH_CONV conv)))
		 ORELSEC conv) t;
   in
      thm
   end;
 

(*
fun SMALLFOOT_COND_PROP___DELAYED_DEPTH_CONV t =
   if (is_COND_PROP___ADD_COND t) then			   
      let
	  val (_, t') = dest_COND_PROP___ADD_COND t;
          val (conv, t'') = SMALLFOOT_COND_PROP___DELAYED_DEPTH_CONV t';
      in
          (fn c => (SMALLFOOT_COND_PROP___DEPTH_CONV___ADD_COND (conv c)), t'')
      end
   else if (is_COND_PROP___EXISTS t) then			   
      let
	  val (_, t') = dest_COND_PROP___EXISTS t;
          val (conv, t'') = SMALLFOOT_COND_PROP___DELAYED_DEPTH_CONV t';
      in
          (fn c => SMALLFOOT_COND_PROP___DEPTH_CONV___EXISTS (conv c), t'')
      end
   else
      (I, t);

*)


fun SMALLFOOT_COND_PROP___THENC conv1 conv2 t = 
let
  val thm1 = conv1 t
in
  (let
     val (_, t') = dest_SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV (concl thm1);
     val thm2 = conv2 t';
  in
     SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV___TRANS_RULE thm1 thm2
  end) handle UNCHANGED => thm1
end handle UNCHANGED => conv2 t





fun SMALLFOOT_COND_PROP___REPEATC conv t =
    ((SMALLFOOT_COND_PROP___THENC (QCHANGED_CONV conv) 
                                 (SMALLFOOT_COND_PROP___REPEATC conv)) t) 
    handle HOL_ERR _ => raise UNCHANGED;






fun RHS_GSYM thm =
let
   val t = rhs (concl thm);
   val (l,r) = dest_eq t;
   val thm0 = ISPECL [l,r] EQ_SYM_EQ
   val thm1 = TRANS thm thm0
in
   thm1
end;

(*
val t = ``smallfoot_ap_equal (smallfoot_ae_const 0) (smallfoot_ae_const (2+3+a))``
val t = ``smallfoot_ap_equal (smallfoot_ae_const 0) (smallfoot_ae_const (2+3))``
val t = ``smallfoot_ap_equal (smallfoot_ae_const 5) (smallfoot_ae_const (2+3))``
val t = ``smallfoot_ap_equal (smallfoot_ae_const 5) (smallfoot_ae_const (2+3))``
val t = ``smallfoot_ap_equal (smallfoot_ae_const 5) (smallfoot_ae_var v)``
val t = ``smallfoot_ap_equal g (smallfoot_ae_var v)``
val t = ``smallfoot_ap_equal g h``
val t = ``smallfoot_ap_equal (smallfoot_ae_var v) (smallfoot_ae_var v)``
val t = ``smallfoot_ap_equal e e``

val t = ``smallfoot_ap_equal smallfoot_ae_null (smallfoot_ae_const (2+3))``
*)






fun smallfoot_ap_equal___CONV t =
    let
       val (l,r) = dest_smallfoot_ap_equal t;
    in
       if (is_smallfoot_ae_var r andalso not (is_smallfoot_ae_var l)) then
          ISPECL [l,r] smallfoot_ap_equal___COMM
       else if (l = r) then
          REWRITE_RULE [smallfoot_ap_exp_is_defined___const] (ISPEC l smallfoot_ap_equal___EQ_REWRITE)
       else if (is_smallfoot_ae_const_null l) andalso (is_smallfoot_ae_const_null r) then       
          let
	     val l' = dest_smallfoot_ae_const_null l;
	     val r' = dest_smallfoot_ae_const_null r;
	     val thm0 = ISPECL [l',r'] smallfoot_ap_equal___EQ_REWRITE___const;
             val thm1 = if (lhs (concl thm0) = t) then thm0 else
	                TRANS (EQT_ELIM (REWRITE_CONV [smallfoot_ae_null_def] 
                                        (mk_eq (t, lhs (concl thm0))))) thm0

             val const_eq = mk_eq (l',r');
             val eq_thm = reduceLib.REDUCE_CONV const_eq;
	     val turn = let 
			    val (lc,rc) = dest_eq (rhs (concl eq_thm));
                        in
                            same_const lc numSyntax.zero_tm orelse
			    (numSyntax.is_numeral lc andalso
                             not (numSyntax.is_numeral rc))
                        end handle HOL_ERR _ => false;
	     val eq_thm' = if turn then RHS_GSYM eq_thm else eq_thm;
	     val thm2 = CONV_RULE (RHS_CONV (REWRITE_CONV [
	                       eq_thm', GSYM smallfoot_ap_empty_heap_cond___false,
			       GSYM smallfoot_ap_stack_true_REWRITE])) thm1
          in
             thm2
          end
       else raise UNCHANGED
    end;



fun smallfoot_ap_unequal___CONV t =
    let
       val (l,r) = dest_smallfoot_ap_unequal t;
    in
       if (is_smallfoot_ae_var r andalso not (is_smallfoot_ae_var l)) then
          ISPECL [l,r] smallfoot_ap_unequal___COMM
       else if (l = r) then
          ISPEC l (CONJUNCT1 smallfoot_ap_unequal___EQ_REWRITES)
       else if (is_smallfoot_ae_const_null l) andalso (is_smallfoot_ae_const_null r) then       
          let
	     val l' = dest_smallfoot_ae_const_null l;
	     val r' = dest_smallfoot_ae_const_null r;

             val const_eq = mk_eq (l',r');
             val eq_thm = reduceLib.REDUCE_CONV const_eq;
	     val _ = if (rhs (concl eq_thm) = T) orelse
                        (rhs (concl eq_thm) = F) then () else raise UNCHANGED;


	     val thm0 = ISPECL [l',r'] smallfoot_ap_unequal___EQ_REWRITE___const;
             val thm1 = if (lhs (concl thm0) = t) then thm0 else
	                TRANS (EQT_ELIM (REWRITE_CONV [smallfoot_ae_null_def] 
                                        (mk_eq (t, lhs (concl thm0))))) thm0
	     val thm2 = CONV_RULE (RHS_CONV (REWRITE_CONV [
	                       eq_thm, GSYM smallfoot_ap_empty_heap_cond___false,
			       GSYM smallfoot_ap_stack_true_REWRITE])) thm1
          in
             thm2
          end
       else raise UNCHANGED
    end;



fun smallfoot_ap_unequal_comm___CONV t =
    let
       val (l,r) = dest_smallfoot_ap_unequal t;
    in
       ISPECL [l,r] smallfoot_ap_unequal___COMM
    end;




val smallfoot___PROP_SIMPLE_EQ_REWRITES_CONV =
    DEPTH_CONV smallfoot_ap_equal___CONV THENC
    DEPTH_CONV smallfoot_ap_unequal___CONV THENC
    REWRITE_CONV [smallfoot_ap_bintree___smallfoot_ae_null,
                  smallfoot_ap_list___smallfoot_ae_null,
		  smallfoot_ap_list_seg___smallfoot_ae_null,
		  smallfoot_ap_points_to___smallfoot_ae_null,
		  GSYM smallfoot_ae_null_def,
		  GSYM smallfoot_ap_list_def,
                  COND_PROP___ADD_COND___ADD_COND,
                  COND_PROP___ADD_COND___true,
                  smallfoot_ap_cond_equal___EQ_REWRITES,
		  smallfoot_ap_list_seg___EQ_REWRITE,
		  smallfoot_ap_exp_is_defined___const,
		  GSYM smallfoot_ap_stack_true_REWRITE,
		  GSYM smallfoot_ap_empty_heap_cond___false];



(*
val t = ``
 (smallfoot_prop ({|a; b; c; d; e; f|},{| |})
            {|smallfoot_ap_equal (smallfoot_ae_var a)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var b)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var c)
                (smallfoot_ae_const 0);
              smallfoot_ap_unequal (smallfoot_ae_const 0)
                (smallfoot_ae_var f);
              smallfoot_ap_points_to (smallfoot_ae_const 0) FEMPTY;
              smallfoot_ap_equal (smallfoot_ae_const 0)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var d) (smallfoot_ae_var f);
              smallfoot_ap_list_seg tl (smallfoot_ae_var d)
                (smallfoot_ae_var f);
              smallfoot_ap_points_to (smallfoot_ae_const 0) FEMPTY|})``

*)






fun smallfoot_prop___smallfoot_ap_stack_true_CONV t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (fn t => if (same_const smallfoot_ap_stack_true_term t) then SOME () else NONE)) [] 0 sfs 
   val _ = if (not (isSome found_opt)) then raise UNCHANGED else ();
   val (pos, _, _) = valOf found_opt;
   val thm1 = smallfoot_prop___COND_RESORT_CONV [pos] t;

   val (_,_,sfb') = dest_smallfoot_prop (rhs (concl thm1));
   val (_, sfb'') = bagSyntax.dest_insert sfb';

   val thm2 = ISPECL [wpb,rpb,sfb''] SMALLFOOT_COND_PROP___EQUIV___smallfoot_ap_stack_true
   val thm3 = SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm2
in
   thm3
end;



fun smallfoot_prop___smallfoot_ap_false_CONV t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (fn t => if (same_const smallfoot_ap_false_term t) then SOME () else NONE)) [] 0 sfs 
   val _ = if (not (isSome found_opt)) then raise UNCHANGED else ();
   val (pos, _, _) = valOf found_opt;
   val thm1 = smallfoot_prop___COND_RESORT_CONV [pos] t;

   val (_,_,sfb') = dest_smallfoot_prop (rhs (concl thm1));
   val (_, sfb'') = bagSyntax.dest_insert sfb';

   val thm2 = ISPECL [wpb,rpb,sfb''] SMALLFOOT_COND_PROP___EQUIV___smallfoot_ap_false
   val thm3 = SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm2
in
   thm3
end;

fun smallfoot_prop___smallfoot_ap_exp_is_defined_CONV equiv t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (fn t => SOME (dest_smallfoot_ap_exp_is_defined t))) [] 0 sfs 

   val _ = if (not (isSome found_opt)) then raise UNCHANGED else ();
   val (pos, _, v') = valOf found_opt;
   val v = dest_smallfoot_ae_var v' handle HOL_ERR _ => raise UNCHANGED;
   val thm1 = smallfoot_prop___COND_RESORT_CONV [pos] t;

   val (_,_,sfb') = dest_smallfoot_prop (rhs (concl thm1));
   val (_, sfb'') = bagSyntax.dest_insert sfb';

in
   if equiv then 
      let
         val thm2 = ISPECL [wpb,v,rpb,sfb''] SMALLFOOT_COND_PROP___EQUIV___smallfoot_ap_exp_is_defined;
         val thm3 = smallfoot_precondition_prove_RULE "smallfoot_prop___smallfoot_exp_is_defined_CONV" [] thm2;
         val thm4 = SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm3
      in thm4 end
   else
      let
         val thm2 = ISPECL [wpb,v,rpb,sfb''] SMALLFOOT_COND_PROP___IMP___smallfoot_ap_exp_is_defined;
         val thm3 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm1 thm2
      in thm3 end
end;



fun smallfoot_prop___smallfoot_ap_empty_heap_cond_CONV t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (fn t => SOME (dest_smallfoot_ap_empty_heap_cond t))) [] 0 sfs 

   val _ = if (not (isSome found_opt)) then raise UNCHANGED else ();
   val (pos, _, c) = valOf found_opt;
   val thm1 = smallfoot_prop___COND_RESORT_CONV [pos] t;

   val base_thm = if is_eq c then SMALLFOOT_COND_PROP___EQUIV___empty_heap_cond___REWRITE else
		                  SMALLFOOT_COND_PROP___EQUIV___empty_heap_cond;
   val thm2 = HO_PART_MATCH (rand o rator) (SPEC_ALL base_thm) (rhs (concl thm1))
   val thm3 = SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm2
in
   thm3
end;










fun find_pointsto_eq_spatial l n t =
    let
       val (e, _) = dest_smallfoot_ap_points_to t;
       val found_opt = find_first_num (K 
           (fn t' => let val e' = dest_smallfoot_ap_spatial t' in if (e = e') then SOME () else NONE end))
           [n] 0 l;
    in
       if (isSome found_opt) then
          let val (n2,t2,_) = valOf found_opt in
              SOME (n2,t2)
          end else NONE 
    end;

             


fun smallfoot_prop___smallfoot_ap_points_to_eq_spatial_exp_CONV t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (find_pointsto_eq_spatial sfs) [] 0 sfs 

   val _ = if (not (isSome found_opt)) then raise UNCHANGED else ();
   val (pos, _, (pos2,spt)) = valOf found_opt;
   val thm1 = smallfoot_prop___COND_RESORT_CONV [pos,pos2] t;

   val (base_thm, has_precond) = if is_smallfoot_ap_points_to spt then 
                      	    (SMALLFOOT_COND_PROP___EQUIV___points_to_SIMP_EQ___points_to,
			     false) else
			  if is_smallfoot_ap_list_seg spt then 
                      	    (SMALLFOOT_COND_PROP___EQUIV___points_to_SIMP_EQ___list_seg,
			     true) else
			  if is_smallfoot_ap_list spt then 
                      	    (SMALLFOOT_COND_PROP___EQUIV___points_to_SIMP_EQ___list,
			     true) else
			  if is_smallfoot_ap_bintree spt then 
                      	    (SMALLFOOT_COND_PROP___EQUIV___points_to_SIMP_EQ___bintree,
			     true) else
                          raise UNCHANGED
   val thm2 = HO_PART_MATCH (if has_precond then rand o rator o snd o dest_imp else rand o rator) (SPEC_ALL base_thm) (rhs (concl thm1))
   val thm3 = if has_precond then smallfoot_precondition_prove_RULE "smallfoot_prop___COND_RESORT_CONV" [] thm2 else thm2
   val thm4 = SMALLFOOT_COND_PROP___EQUIV___TRANS_RULE thm1 thm3
in
   thm4
end;





val QCHANGED_FIRST_CONV = FIRST_CONV o (map QCHANGED_CONV)

val smallfoot_prop___SIMPLIFY_CONV =
(SMALLFOOT_COND_PROP___REPEATC (SMALLFOOT_COND_PROP___DEPTH_CONV (
       (QCHANGED_FIRST_CONV
       [smallfoot___PROP_SIMPLE_EQ_REWRITES_CONV,
        smallfoot_prop___smallfoot_ap_false_CONV,        
	smallfoot_prop___smallfoot_ap_points_to_eq_spatial_exp_CONV,
	smallfoot_prop___smallfoot_ap_empty_heap_cond_CONV,
	smallfoot_prop___smallfoot_ap_stack_true_CONV,
        smallfoot_prop___smallfoot_ap_exp_is_defined_CONV true,
        PART_MATCH (rand o rator) (SPEC_ALL COND_PROP___EXISTS___COND_PROP_FALSE),
        PART_MATCH (rand o rator) (SPEC_ALL COND_PROP___ADD_COND___COND_PROP_FALSE),
        PART_MATCH (rand o rator) (SPEC_ALL COND_PROP___EXISTS___ELIM)
       ]))))














fun smallfoot_ae_var___is_equals_const___excluded done t =
   let
      val (l,r) = dest_smallfoot_ap_equal t;
      val v = dest_smallfoot_ae_var l;
      val c = dest_smallfoot_ae_const_null r;
   in
      (if mem v done  then NONE else SOME (v, c))
   end handle HOL_ERR _ => NONE;


fun smallfoot_ae_var___is_equals_var t =
   let
      val (l,r) = dest_smallfoot_ap_equal t;
      val vl = dest_smallfoot_ae_var l;
      val vr = dest_smallfoot_ae_var r;
   in
      SOME (vl, vr)
   end handle HOL_ERR _ => NONE;








(*

val t = ``
 smallfoot_prop ({|b;c;d;e;f|},{| |})
{|smallfoot_ap_unequal (smallfoot_ae_const a) (smallfoot_ae_var f);
  smallfoot_ap_points_to (smallfoot_ae_const a) FEMPTY;
  smallfoot_ap_equal (smallfoot_ae_var b) (smallfoot_ae_var c);
  smallfoot_ap_equal (smallfoot_ae_const 2) (smallfoot_ae_const a);
  smallfoot_ap_equal (smallfoot_ae_var b) (smallfoot_ae_const a);
  smallfoot_ap_equal (smallfoot_ae_var f) (smallfoot_ae_var f);
  smallfoot_ap_equal (smallfoot_ae_var f) smallfoot_ae_null;
  smallfoot_ap_list_seg tl (smallfoot_ae_var d) (smallfoot_ae_var f);
  smallfoot_ap_points_to (smallfoot_ae_var f) FEMPTY|}``;


val t = ``
 smallfoot_prop ({|a;b;c;d;e;f|},{| |})
{|smallfoot_ap_unequal (smallfoot_ae_var a) (smallfoot_ae_var f);
  smallfoot_ap_equal (smallfoot_ae_var b) (smallfoot_ae_var c);
  smallfoot_ap_equal (smallfoot_ae_var c) (smallfoot_ae_var a);
  smallfoot_ap_equal (smallfoot_ae_var b) (smallfoot_ae_const x);
  smallfoot_ap_equal (smallfoot_ae_var d) (smallfoot_ae_var f);
  smallfoot_ap_list_seg tl (smallfoot_ae_var d) (smallfoot_ae_var f);
  smallfoot_ap_points_to (smallfoot_ae_var a) FEMPTY|}``;



val t = ``
 (smallfoot_prop ({|a; b; c; d; e; f|},{| |})
            {|smallfoot_ap_equal (smallfoot_ae_var a)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var b)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var c)
                (smallfoot_ae_const 0);
              smallfoot_ap_unequal (smallfoot_ae_const 0)
                (smallfoot_ae_var f);
              smallfoot_ap_points_to (smallfoot_ae_const 0) FEMPTY;
              smallfoot_ap_equal (smallfoot_ae_const 0)
                (smallfoot_ae_const 0);
              smallfoot_ap_equal (smallfoot_ae_var d) (smallfoot_ae_var f);
              smallfoot_ap_list_seg tl (smallfoot_ae_var d)
                (smallfoot_ae_var f);
              smallfoot_ap_points_to (smallfoot_ae_const 0) FEMPTY|})``

*)



fun SMALLFOOT_AE_USED_VARS___SAVE_IN v t =
if (is_smallfoot_ae_const_null t) then SOME false else
if (is_smallfoot_ae_var t) then
   SOME (dest_smallfoot_ae_var t = v)
else NONE;


fun exists_opt save f [] = if (save) then SOME false else NONE
  | exists_opt save f (e::L) = 
    let
       val opt = f e
    in
       if (opt = NONE) then exists_opt false f L else
       if (valOf opt) then SOME true else
       exists_opt save f L
    end





fun LIST_SMALLFOOT_AE_USED_VARS___SAVE_IN save v tL =
    exists_opt save (SMALLFOOT_AE_USED_VARS___SAVE_IN v) tL;



fun SMALLFOOT_AP_USED_VARS___SAVE_IN v t =
if (same_const t smallfoot_ap_false_term) then SOME false else
if (same_const t smallfoot_ap_stack_true_term) then SOME false else
if (is_smallfoot_ap_empty_heap_cond t) then SOME false else
if (is_smallfoot_ap_compare t) then 
   let
      val (e1,e2) = dest_smallfoot_ap_compare t;
   in 
      LIST_SMALLFOOT_AE_USED_VARS___SAVE_IN true v [e1,e2]
   end else
if (is_smallfoot_ap_points_to t) then 
   let
      val (e1,tag_map) = dest_smallfoot_ap_points_to t;
      val (tag_expL, rest) = dest_finite_map tag_map;
      val save = not (isSome rest);      
   in 
      LIST_SMALLFOOT_AE_USED_VARS___SAVE_IN save v (e1::map snd tag_expL)
   end else
if (is_smallfoot_ap_list_seg_or_list t) then 
   let
      val (_,e1,e2) = dest_smallfoot_ap_list_seg_or_list t
   in
      LIST_SMALLFOOT_AE_USED_VARS___SAVE_IN true v [e1,e2]
   end else
if (is_smallfoot_ap_exp_is_defined t) then 
   let
      val e = dest_smallfoot_ap_exp_is_defined t
   in 
      SMALLFOOT_AE_USED_VARS___SAVE_IN v e
   end else
if (is_smallfoot_ap_bintree t) then
   let
      val (_,_,e) = dest_smallfoot_ap_bintree t
   in
      SMALLFOOT_AE_USED_VARS___SAVE_IN v e
   end 
else NONE;



fun LIST_SMALLFOOT_AP_USED_VARS___SAVE_IN save v tL =
    exists_opt save (SMALLFOOT_AP_USED_VARS___SAVE_IN v) tL;


fun list_remove_element n [] = []
  | list_remove_element n (e::L) =
    if n = 0 then L else
       e::(list_remove_element (n-1) L);



fun smallfoot_prop___EQ_PROPAGATE___INTERNAL new_vars_intro all_vars_intro done t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED

   val thm0 = (REWRITE_CONV [smallfoot_ae_null_def] t)
               handle UNCHANGED => REFL t;
   val t' = rhs (concl thm0)

   val (wpb,rpb,sfb) = dest_smallfoot_prop t';
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (smallfoot_ae_var___is_equals_const___excluded done)) [] 0 sfs 
in
   if isSome found_opt then
       let
	   val (pos,_,(v,c)) = valOf found_opt;
           val needs_rewrite_opt = LIST_SMALLFOOT_AP_USED_VARS___SAVE_IN true v
                          	       (list_remove_element pos sfs);
	   val needs_rewrite = (not (isSome needs_rewrite_opt)) orelse (valOf needs_rewrite_opt);
       in if (not needs_rewrite) then
	   let    
               val thm1 = smallfoot_prop___EQ_PROPAGATE___INTERNAL new_vars_intro all_vars_intro (v::done) t' 
			  handle UNCHANGED => SMALLFOOT_COND_PROP___IMP___REFL_CONV t'
               val thm2 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm0 thm1;
           in
               thm2
           end
       else let
           val thm1 = CONV_RULE (RHS_CONV (smallfoot_prop___COND_RESORT_CONV [pos])) thm0
           val (_,_,sfb') = dest_smallfoot_prop (rhs (concl thm1));
	   val (_, sfb'') = bagSyntax.dest_insert sfb';

	   val thm2 = ISPECL [wpb,rpb,v,c,sfb''] SMALLFOOT_COND_PROP___IMP___VAR_EQ_CONST_REWRITE
	   val thm3 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm1 thm2

	   val (_, p) = dest_SMALLFOOT_COND_PROP___IMP (concl thm3)
	   val thm4 = smallfoot_ap_var_update___CONV p;
	   val thm5 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm3 thm4

	   val (_, p) = dest_SMALLFOOT_COND_PROP___IMP (concl thm5);	   
	   val thm6 = (SMALLFOOT_COND_PROP___THENC
                         smallfoot_prop___SIMPLIFY_CONV 
                         (SMALLFOOT_COND_PROP___DEPTH_CONV
                            (smallfoot_prop___EQ_PROPAGATE___INTERNAL new_vars_intro all_vars_intro (v::done)))) p
  	              handle UNCHANGED => SMALLFOOT_COND_PROP___IMP___REFL_CONV p;	   
       in
	   SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm5 thm6
       end end
   else
      let
         val _ = if new_vars_intro orelse all_vars_intro then () else raise UNCHANGED;
         val found_opt = find_first_num (K (smallfoot_ae_var___is_equals_var)) [] 0 sfs 
         val v = if (isSome found_opt) then 
		     let val (_,_,(v,_)) = valOf found_opt in
			 v
                     end
                 else
                     let
                         val _ = if all_vars_intro then () else raise UNCHANGED;
			 val (wpbL, _) = bagLib.dest_bag wpb;
			 val (rpbL, _) = bagLib.dest_bag rpb;
                         val v_opt = List.find (fn x => not (mem x done)) (wpbL@rpbL)
			 val _ = if (isSome v_opt) then () else raise UNCHANGED;
	             in
                         valOf v_opt
                     end;
         val thm1 = ISPECL [v,wpb,rpb,sfb] smallfoot_prop___CONST_INTRO
         val thm2 = smallfoot_precondition_prove_RULE "smallfoot_prop___EQ_PROPAGATE___INTERNAL" [] thm1

         val c_name = get_const_name_for_var v;
         val thm3 = CONV_RULE ((RAND_CONV o RAND_CONV) (RENAME_VARS_CONV [c_name])) thm2
	 val thm4 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm0 thm3


         val (_,p0) = dest_SMALLFOOT_COND_PROP___IMP (concl thm4)
         val (c,p) = dest_COND_PROP___EXISTS p0;

         val thm_p = smallfoot_prop___EQ_PROPAGATE___INTERNAL new_vars_intro all_vars_intro done p
                     handle UNCHANGED => SMALLFOOT_COND_PROP___IMP___REFL_CONV p
         val thm_p' = GEN c thm_p

	 val thm5 = HO_MATCH_MP (SPEC_ALL SMALLFOOT_COND_PROP___IMP___EXISTS) thm_p'
         val thm6 = SMALLFOOT_COND_PROP___IMP___TRANS_RULE thm4 thm5
      in
         thm6
      end
   end;


fun smallfoot_prop___EQ_PROPAGATE_CONV new_vars_intro all_vars_intro =
      SMALLFOOT_COND_PROP___THENC
         (smallfoot_prop___EQ_PROPAGATE___INTERNAL new_vars_intro all_vars_intro [])
         smallfoot_prop___SIMPLIFY_CONV;







fun bag_el_conv conv n b =
let
   val (insert_term, rest_term) = dest_comb b;

in
   if (n = 0) then
      AP_THM (RAND_CONV conv insert_term) rest_term
   else
      AP_TERM insert_term (bag_el_conv conv (n-1) rest_term)  
end



fun smallfoot_prop___bag_el_conv conv n =
   RAND_CONV (bag_el_conv conv n)






















fun smallfoot_prop___unequal_intro e1 e2 t =
let
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs,_) = bagSyntax.dest_bag sfb
   val found_opt = find_first_num (K (fn t => 
		       let 
			  val (l,r) = dest_smallfoot_ap_unequal t;
                       in
                          if (l = e1) andalso (r = e2) then SOME false else 
                          if (l = e2) andalso (r = e1) then SOME true else NONE
		       end)) [] 0 sfs;  
in
   if (isSome found_opt) then
      let
	 val (pos, _, needs_turn) = valOf found_opt
         val thm = BAG_RESORT_CONV [pos] sfb;
	 val thm1 = if needs_turn then
			CONV_RULE (RHS_CONV (bag_el_conv smallfoot_ap_unequal_comm___CONV 0)) thm
                    else thm
         val (pre,_) = dest_comb t
      in
         AP_TERM pre thm1
      end
   else
      let
         val c1 = dest_smallfoot_ae_const_null e1
         val c2 = dest_smallfoot_ae_const_null e2
	 val thm = DECIDE (mk_neg (mk_eq(c1,c2)));

         val thm1 = SPECL [c1,c2,wpb,rpb,sfb] smallfoot_prop___UNEQUAL_INTRO
         val thm2 = MP thm1 thm
         val thm3 = if (e1 = smallfoot_ae_null_term) orelse
		       (e2 = smallfoot_ae_null_term) then
	               CONV_RULE (RHS_CONV (smallfoot_prop___bag_el_conv (REWRITE_CONV [GSYM smallfoot_ae_null_def]) 0)) thm2
                    else thm2
      in 
         thm3      
      end   
end;




fun smallfoot_prop___extract_points_to_internal e t =
let
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs,_) = bagSyntax.dest_bag sfb
   val e'_opt = find_first_num (K (fn t => 
		       let 
			  val (l,r) = dest_smallfoot_ap_equal t;
                       in
                          if (l = e) then SOME r else NONE
		       end)) [] 0 sfs;
   val e' = if (isSome e'_opt) then #3 (valOf e'_opt) else e 


   val point_to_opt = find_first_num (K (fn t => 
		       let 
			  val (e1,_) = dest_smallfoot_ap_points_to t
                       in
                          if (e1 = e') then SOME e1 else NONE
		       end)) [] 0 sfs;
in
  if (isSome point_to_opt) then
     let
         val (pos,_,_) = valOf point_to_opt
	 val thm = smallfoot_prop___COND_RESORT_CONV [pos] t
     in
         thm
     end
  else
     let
        val split_opt = find_first_num (K (fn t => 
		       let 
			  val (e1,e2) = dest_smallfoot_ap_list_seg_or_list_or_bintree t
                       in
                          if (e1 = e') then SOME (e1,e2) else NONE
		       end)) [] 0 sfs;
        val _ = if (isSome split_opt) then () else raise UNCHANGED;
        val (split_pos, split_term, (e1,e2)) = valOf split_opt;
        val thm1 = smallfoot_prop___COND_RESORT_CONV [split_pos] t
        val thm2 = CONV_RULE (RHS_CONV (smallfoot_prop___unequal_intro e1 e2)) thm1; 

        val split_thm = if (is_smallfoot_ap_list_seg split_term) then
                         SMALLFOOT_COND_PROP___IMP___list_seg_split
                     else if (is_smallfoot_ap_list split_term) then
                         SMALLFOOT_COND_PROP___IMP___list_split
                     else if (is_smallfoot_ap_bintree split_term) then
                          SMALLFOOT_COND_PROP___IMP___bintree_split
                     else raise UNCHANGED;
        val thm3 = PART_MATCH (rand o rator o snd o dest_imp) (SPEC_ALL split_thm) (rhs (concl thm2));
        val thm4 = smallfoot_precondition_prove_RULE "smallfoot_prop___extract_points_to" [] thm3;

        val thm5 = SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV___TRANS_RULE thm2 thm4
     in
        thm5
     end
end;


fun smallfoot_prop___extract_points_to___replace_exp_to_org e t =
let
   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs,_) = bagSyntax.dest_bag sfb;
   val (e', _) = dest_smallfoot_ap_points_to (hd sfs);
   val _ = if (e = e') then raise UNCHANGED else ();
   val e_opt = find_first_num (K (fn t => 
		       let 
			  val (l,r) = dest_smallfoot_ap_equal t;
                       in
                          if (l = e) andalso (r = e') then SOME () else NONE
		       end)) [] 0 sfs;
   val pos = if (isSome e_opt) then #1 (valOf e_opt) else raise UNCHANGED
   val thm1 = smallfoot_prop___COND_RESORT_CONV [0,pos] t;

   val thm2 = PART_MATCH (lhs o snd o dest_imp) (SPEC_ALL smallfoot_prop___EQUAL_POINTS_TO) (rhs (concl thm1));
   val thm3 = smallfoot_precondition_prove_RULE "smallfoot_prop___extract_points_to___replace_exp_to_org" [] thm2;
in
   TRANS thm1 thm3
end;


fun smallfoot_prop___extract_points_to e t =
let
   val e_thm_opt = SOME (SIMP_CONV arith_ss [SMALLFOOT_P_EXPRESSION_EVAL_def,
				   GSYM smallfoot_ae_null_def] e) handle UNCHANGED => NONE;
   val e' = if isSome e_thm_opt then rhs (concl (valOf e_thm_opt)) else e;
   val thm1 = smallfoot_prop___EQ_PROPAGATE_CONV true false t handle UNCHANGED => REFL t
   val (_, t') = dest_SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV (concl thm1);
   val thm2 = SMALLFOOT_COND_PROP___DEPTH_CONV 
       (smallfoot_prop___extract_points_to_internal e') t';
   val thm3 = SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV___TRANS_RULE thm1 thm2;



   val (_, t'') = dest_SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV (concl thm3);

   val thm4 = (SMALLFOOT_COND_PROP___DEPTH_CONV (smallfoot_prop___extract_points_to___replace_exp_to_org e') t''
              handle HOL_ERR _ => REFL t'') handle UNCHANGED => REFL t'';                

   val thm5 = if (isSome e_thm_opt) then
		  CONV_RULE (RHS_CONV (SMALLFOOT_COND_PROP___DEPTH_CONV (
				       smallfoot_prop___bag_el_conv (
				       ONCE_REWRITE_CONV [GSYM (valOf e_thm_opt)]) 0))) thm4
              else
		  thm4;
 
   val thm6 = SMALLFOOT_COND_PROP___EQ_OR_IMP_OR_EQUIV___TRANS_RULE thm3 thm5;
 
in
   thm6
end;





(*

val t =
    ``SMALLFOOT_COND_HOARE_TRIPLE penv
        (smallfoot_prop
           ({|u; t; r|},{|smallfoot_var "_b"; smallfoot_var "_tf"|})
           {|smallfoot_ap_points_to (smallfoot_ae_var t) FEMPTY;
             smallfoot_ap_equal (smallfoot_ae_var r)
               (smallfoot_ae_const r_const);
             smallfoot_ap_points_to (smallfoot_ae_const r_const)
               (FEMPTY |+
                (smallfoot_tag "tl",
                 smallfoot_ae_var (smallfoot_var "_tf")));
             smallfoot_ap_list_seg (smallfoot_tag "tl")
               (smallfoot_ae_var (smallfoot_var "_tf"))
               (smallfoot_ae_const r_const)|})
        (smallfoot_prog_block
           [smallfoot_prog_field_lookup u (smallfoot_p_var r)
              (smallfoot_tag "tl");
            smallfoot_prog_field_assign (smallfoot_p_var t)
              (smallfoot_tag "tl") (smallfoot_p_var u);
            smallfoot_prog_field_assign (smallfoot_p_var r)
              (smallfoot_tag "tl") (smallfoot_p_var t)])
        (smallfoot_prop
           ({|u; t; r|},{|smallfoot_var "_b"; smallfoot_var "_tf"|})
           {|smallfoot_ap_points_to (smallfoot_ae_const r_const)
               (FEMPTY |+
                (smallfoot_tag "tl",smallfoot_ae_var (smallfoot_var "_b")));
             smallfoot_ap_points_to (smallfoot_ae_var (smallfoot_var "_b"))
               (FEMPTY |+
                (smallfoot_tag "tl",
                 smallfoot_ae_var (smallfoot_var "_tf")));
             smallfoot_ap_list_seg (smallfoot_tag "tl")
               (smallfoot_ae_var (smallfoot_var "_tf"))
               (smallfoot_ae_const r_const)|})``

*)



val FAPPLY_cs = reduceLib.num_compset ();
val _ = computeLib.add_thms [smallfoot_tag_11,
			     FAPPLY_FUPDATE_THM] FAPPLY_cs
val _ = computeLib.add_conv (``$=``, 2, stringLib.string_EQ_CONV) FAPPLY_cs;


fun SMALLFOOT_COND_INFERENCE_CONV___field_lookup_internal v tt = 
let
   val (quant, thm1) = SMALLFOOT_COND_HOARE_TRIPLE___CONST_INTRO v NONE tt;
   val (t', thm1_func) = COND_FORALL_RULE quant thm1;

   val thm2 = PART_MATCH (snd o dest_imp o snd o dest_imp) (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_field_lookup) t'
   val new_exp = (rand o el 3 o strip_conj o fst o dest_imp o concl) thm2;
   val new_exp_thm = computeLib.CBV_CONV FAPPLY_cs new_exp
   val thm3 = REWRITE_RULE [new_exp_thm] thm2     
   val thm4 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___prog_field_lookup" [] thm3;


   val thm5 = CONV_RULE (IMP_ANTE_CONV (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV 
                 smallfoot_ap_var_update___CONV)) thm4;

   val thm6 = thm1_func thm5;
   val thm7 = SUBST_MATCH (GSYM thm1) thm6 
in
   thm7
end



fun SMALLFOOT_COND_INFERENCE_CONV___field_lookup t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val (v, e, tag) = dest_smallfoot_prog_field_lookup command;

   val ee = mk_comb (smallfoot_p_expression_eval_term, e);
   val thm1 = MAKE___IMP___RULE (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___extract_points_to ee) t');
   val thm2 = IMP_TRANS thm1 (MAKE___IMP___RULE thm0)

   val t'' = (fst o dest_imp o concl) thm2
   val thm3 = DEPTH_CONSEQ_CONV (SMALLFOOT_COND_INFERENCE_CONV___field_lookup_internal v) t''
   val thm4 = IMP_TRANS thm3 thm2
in
   thm4
end;











fun SMALLFOOT_COND_INFERENCE_CONV___field_assign_internal tt = 
let
   val thm1 = PART_MATCH (snd o dest_imp o snd o dest_imp) (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_field_assign) tt
   val thm2 = CONV_RULE (RATOR_CONV (REWRITE_CONV [SMALLFOOT_P_EXPRESSION_EVAL_def])) thm1     
   val thm3 = CONV_RULE (RAND_CONV (RATOR_CONV (REWRITE_CONV [SMALLFOOT_P_EXPRESSION_EVAL_def]))) thm2     
   val thm4 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___prog_field_assign" [] thm3;
in
   thm4
end


fun SMALLFOOT_COND_INFERENCE_CONV___field_assign t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val (e1, tag, e2) = dest_smallfoot_prog_field_assign command;

   val ee = mk_comb (smallfoot_p_expression_eval_term, e1);
   val thm1 = MAKE___IMP___RULE (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___extract_points_to ee) t');
   val thm2 = IMP_TRANS thm1 (MAKE___IMP___RULE thm0)

   val t'' = (fst o dest_imp o concl) thm2
   val thm3 = DEPTH_CONSEQ_CONV (SMALLFOOT_COND_INFERENCE_CONV___field_assign_internal) t''
   val thm4 = IMP_TRANS thm3 thm2
in
   thm4
end;






fun get_smallfoot_ap_unequal_exp e1 [] = [] 
  | get_smallfoot_ap_unequal_exp e1 (sf::sfs) =
    let
       val new_exp_opt = if not (is_smallfoot_ap_unequal sf) then NONE else
           let
              val (el,er) = dest_smallfoot_ap_unequal sf;
           in
              if (el = e1) then SOME er else
              if (er = e1) then SOME el else NONE
           end    
       val L = get_smallfoot_ap_unequal_exp e1 sfs
    in
       if isSome new_exp_opt then cons (valOf new_exp_opt) L else L
    end;




(*
val exp = ``smallfoot_ae_const 0``
val exp = ``smallfoot_ae_null``;

val exp = ``smallfoot_ae_var x``;
val sfb = ``
        {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
            (smallfoot_ae_null);
          smallfoot_ap_unequal 
            (smallfoot_ae_const t_const) (smallfoot_ae_var z);
          smallfoot_ap_equal (smallfoot_ae_var y)
            (smallfoot_ae_const y_const);
          smallfoot_ap_bintree (lt,rt) (smallfoot_ae_var x)|}``;





smallfoot_ap_bag_implies_in_heap_or_null___PROVE sfb exp
val exp = e3_term
smallfoot_ap_bag_implies_in_heap_or_null___PROVE sfb e3_term

*)
exception smallfoot_ap_bag_implies_in_heap_or_null___PROVE_FOUND_exn of thm

fun smallfoot_ap_bag_implies_in_heap_or_null___SEARCH_PROVE sfb expP =
   let
      val _ = if (expP smallfoot_ae_null_term) then
              raise smallfoot_ap_bag_implies_in_heap_or_null___PROVE_FOUND_exn
                 (SPEC sfb smallfoot_ap_bag_implies_in_heap_or_null___ae_null)
              else ()

      val sfb_thm = REWRITE_CONV [bagTheory.BAG_UNION_INSERT,
                                  GSYM smallfoot_ae_null_def,
				  GSYM smallfoot_ap_list_def,
				  bagTheory.BAG_UNION_EMPTY] sfb handle UNCHANGED => REFL sfb

      val (sfs, _) = bagSyntax.dest_bag (rhs (concl sfb_thm));    
      val found_opt = find_first_num (K (fn t => (
		          let
			      val exp = dest_smallfoot_ap_spatial___no_list_seg t;
                          in
			      if (expP exp) then SOME exp else NONE
		          end))) [] 0 sfs;

      val found_opt = if (isSome found_opt) then found_opt else
                      (find_first_num (K (fn t => (
		          let
                              val (_, exp1, exp2) = dest_smallfoot_ap_list_seg t;
                              val uneq_expL = get_smallfoot_ap_unequal_exp exp1 sfs;
                          in
			      if (expP exp1 andalso (mem exp2 uneq_expL)) then SOME exp1 else NONE
		          end))) [] 0 sfs);

      val _ = if isSome found_opt then () else raise UNCHANGED;
      val (pos, found_term, exp) = valOf found_opt

      val (imp_thm, rL, turn) = if (is_smallfoot_ap_points_to found_term) then
			       (smallfoot_ap_bag_implies_in_heap_or_null___points_to, [pos], false)
                           else if (is_smallfoot_ap_list found_term) then
			       (smallfoot_ap_bag_implies_in_heap_or_null___list, [pos], false)
                           else if (is_smallfoot_ap_bintree found_term) then
			       (smallfoot_ap_bag_implies_in_heap_or_null___bintree, [pos], false)
                           else if (is_smallfoot_ap_list_seg found_term) then
          let
             val (_,_,e2) = dest_smallfoot_ap_list_seg found_term;
             val found_opt = find_first_num (K (fn t => 
		       let 
			  val (l,r) = dest_smallfoot_ap_unequal t;
                       in
                          if (l = exp) andalso (r = e2) then SOME false else 
                          if (l = e2) andalso (r = exp) then SOME true else NONE
		       end)) [] 0 sfs;  
             val _ = if (isSome found_opt) then () else raise UNCHANGED;
             val (lseg_pos, _, turn) = valOf found_opt;
          in
             (smallfoot_ap_bag_implies_in_heap_or_null___list_seg,
	      ([pos,lseg_pos]), turn)
          end
	  else raise UNCHANGED;

      val sfb_thm2 = CONV_RULE (RHS_CONV (BAG_RESORT_CONV rL)) sfb_thm;
      val sfb_thm3 = if turn then CONV_RULE (RHS_CONV (bag_el_conv smallfoot_ap_unequal_comm___CONV 1)) sfb_thm2 else sfb_thm2

      val sfb_rewrite = rhs (concl sfb_thm3)
      val thm_term_rewrite = ``smallfoot_ap_bag_implies_in_heap_or_null ^sfb_rewrite ^exp``

      val imp_thm_spec = SPEC_ALL imp_thm
      val (part_fun, has_pre_cond) = if (is_imp (concl imp_thm_spec)) then ((snd o dest_imp), true) else (I, false);
      val thm0 = PART_MATCH part_fun imp_thm_spec thm_term_rewrite
      val thm1 = if has_pre_cond then smallfoot_precondition_prove_RULE "smallfoot_ap_bag_implies_in_heap_or_null___PROVE" [] thm0
                 else thm0;
    
      val thm2 = ONCE_REWRITE_RULE [GSYM sfb_thm3] thm1;      
   in
      thm2
   end handle smallfoot_ap_bag_implies_in_heap_or_null___PROVE_FOUND_exn thm =>
       thm;


fun smallfoot_ap_bag_implies_in_heap_or_null___PROVE sfb exp =
    smallfoot_ap_bag_implies_in_heap_or_null___SEARCH_PROVE sfb (fn e => (e = exp))









(*

val t = ``
(smallfoot_prop ({|t|},{|x; y|})
         {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_var t)
             (smallfoot_ae_var y);
           smallfoot_ap_equal (smallfoot_ae_var y)
             (smallfoot_ae_const y_const);
           smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_var y);
           smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
           smallfoot_ap_equal (smallfoot_ae_var x)
             (smallfoot_ae_const t_const);
           smallfoot_ap_unequal (smallfoot_ae_const t_const)
             (smallfoot_ae_const y_const);
           smallfoot_ap_points_to (smallfoot_ae_const t_const)
             (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n))|})``;
*)





exception smallfoot_prop___points_to_UNEQUAL_INTRO___CONV_exn of term;

fun smallfoot_prop___points_to_UNEQUAL_INTRO___CONV expP t =
let
   val _ = if (is_smallfoot_prop t) then () else raise UNCHANGED;

   val (wpb,rpb,sfb) = dest_smallfoot_prop t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num (K (fn t => 
		       let 
			  val (exp,t) = dest_smallfoot_ap_points_to t;
                       in
                          if (expP exp) then SOME exp else NONE
		       end)) [] 0 sfs;  

   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (points_to_pos, _, e1) = valOf found_opt;


   val uneq_expL = get_smallfoot_ap_unequal_exp e1 sfs;

   val sfb_thm = BAG_RESORT_CONV [points_to_pos] sfb
   val (_, sfb2) = bagSyntax.dest_insert (rhs (concl sfb_thm));
   val bag_implies_thm = smallfoot_ap_bag_implies_in_heap_or_null___SEARCH_PROVE sfb2 (fn t => not (mem t uneq_expL)) handle
                         UNCHANGED => raise smallfoot_prop___points_to_UNEQUAL_INTRO___CONV_exn e1;

   val t_thm = AP_TERM (fst (dest_comb t)) sfb_thm;

   val thm0 = PART_MATCH (lhs o snd o dest_imp o snd o dest_imp)
                 (SMALLFOOT_COND_PROP___EQ___points_to_UNEQUAL_INTRO)
                 (rhs (concl t_thm))
   val thm1 = MATCH_MP thm0 bag_implies_thm
   val thm2 = smallfoot_precondition_prove_RULE "smallfoot_prop___points_to_UNEQUAL_INTRO___CONSEQ_CONV" [] thm1;


   val thm3 = CONV_RULE (LHS_CONV (ONCE_REWRITE_CONV [GSYM t_thm])) thm2
in
   thm3
end handle smallfoot_prop___points_to_UNEQUAL_INTRO___CONV_exn e1 =>
           smallfoot_prop___points_to_UNEQUAL_INTRO___CONV (fn e2 => (not (e2 = e1)) andalso expP e2) t;



val SMALLFOOT_COND_INFERENCE_CONV___points_to_UNEQAL_INTRO =
   SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV
      (REPEATC (smallfoot_prop___points_to_UNEQUAL_INTRO___CONV (K true)))




fun SMALLFOOT_COND_INFERENCE_CONV___dispose t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val e1 = dest_smallfoot_prog_dispose command;

   val ee = mk_comb (smallfoot_p_expression_eval_term, e1);
   val thm1 = MAKE___IMP___RULE (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___extract_points_to ee) t');
   val thm2 = IMP_TRANS thm1 (MAKE___IMP___RULE thm0)

   val t'' = (fst o dest_imp o concl) thm2
   val thm3 = DEPTH_CONSEQ_CONV (PART_MATCH (snd o dest_imp) (SPEC_ALL SMALLFOOT_COND_INFERENCE___prog_dispose)) t''
   val thm4 = IMP_TRANS thm3 thm2
in
   thm4
end;






fun smallfoot_p_expression_eval___SIMULATE t =
   let
      val (f, arg) = dest_comb t
   in
      if (same_const f smallfoot_p_var_term) then
         mk_comb(smallfoot_ae_var_term, arg)
      else if (same_const f smallfoot_p_const_term) then
         mk_comb(smallfoot_ae_const_term, arg)
      else
	 raise mk_HOL_ERR "smallfootLib" "smallfoot_p_expression_eval___SIMULATE" "Not var or const"      
   end;


fun smallfoot_ap_implies_ae_equal___CONV tt =
let
   val _ = if (is_smallfoot_ap_implies_ae_equal tt) then () else raise UNCHANGED;
   val (P, e1, e2) = dest_smallfoot_ap_implies_ae_equal tt; 
in
   if (e1 = e2) then
      EQT_INTRO (ISPECL [e1, P] smallfoot_ap_implies_ae_equal___EQ)
   else if (is_smallfoot_prop P) then
      let
         val (wpb,rpb,sfb) = dest_smallfoot_prop P;
         val thm = ISPECL [e1,e2,wpb,rpb,sfb] smallfoot_ap_implies_ae_equal___IN_SMALLFOOT_PROP
	 val p = (fst o dest_imp o concl) thm;
	 val p_thm = EQT_ELIM (REWRITE_CONV[bagTheory.BAG_IN_BAG_INSERT] p)
         val thm2 = MP thm p_thm
      in
         EQT_INTRO thm2
      end
   else raise UNCHANGED
end;


(*
val smallfoot_ae_is_list_cond_defined___REWRITES =
store_thm ("smallfoot_ae_is_list_cond_defined___REWRITES",
``(smallfoot_ae_is_list_cond_defined P [] = P) /\
  (smallfoot_ae_is_list_cond_defined P (smallfoot_ae_const c::L) =
   smallfoot_ae_is_list_cond_defined P L) /\
  (smallfoot_ae_is_list_cond_defined P (smallfoot_ae_null::L) =
   smallfoot_ae_is_list_cond_defined P L) /\
  (v IN SET_OF_BAG (BAG_UNION wpb rpb) ==>
  (smallfoot_ae_is_list_cond_defined (smallfoot_prop (wpb,rpb) sfb) (smallfoot_ae_var v::L) =
   smallfoot_ae_is_list_cond_defined (smallfoot_prop (wpb,rpb) sfb) L)) /\

  (~(v IN SET_OF_BAG (BAG_UNION wpb rpb)) ==>
  (SMALLFOOT_COND_PROP___IMP 
   (smallfoot_ae_is_list_cond_defined (smallfoot_prop (wpb,rpb) sfb) (smallfoot_ae_var v::L))
   (smallfoot_ae_is_list_cond_defined (smallfoot_prop (wpb,BAG_INSERT v rpb) sfb) L)))

``,

SIMP_TAC list_ss [smallfoot_ae_is_list_cond_defined_def, IN_ABS3,
		  smallfoot_ae_const_def, smallfoot_ae_null_def,
		  smallfoot_ae_var_def,
		  COND_NONE_SOME_REWRITES] THEN
ONCE_REWRITE_TAC[EXTENSION] THEN
SIMP_TAC (std_ss++bool_eq_imp_ss) [IN_ABS] THEN
SIMP_TAC std_ss [smallfoot_prop___REWRITE, COND_RAND, COND_RATOR,
		 asl_bool_EVAL, smallfoot_prop___PROP___REWRITE,
		 IN_ABS, bagTheory.IN_SET_OF_BAG,
		 bagTheory.BAG_IN_BAG_UNION, DISJ_IMP_THM,
		 var_res_sl___has_write_permission_def,
		 var_res_sl___has_read_permission_def] THEN
REPEAT STRIP_TAC THEN
ASM_SIMP_TAC std_ss [bagTheory.BAG_IN_BAG_INSERT,
		 DISJ_IMP_THM, FORALL_AND_THM,
		 SMALLFOOT_COND_PROP___IMP_def,
		 IN_ABS, smallfoot_prop___COND___REWRITE,
		 BAG_ALL_DISTINCT_THM] THEN
REPEAT STRIP_TAC THEN
MATCH_MP_TAC SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS___SUBSET THEN
Q.EXISTS_TAC `SET_OF_BAG (BAG_UNION wpb rpb)` THEN
ASM_SIMP_TAC std_ss [SUBSET_DEF, bagTheory.BAG_IN_BAG_UNION,
		     bagTheory.BAG_IN_BAG_INSERT,
		     bagTheory.IN_SET_OF_BAG, DISJ_IMP_THM]);
*)

(*
val tt = snd (strip_forall t'')
*)

fun SMALLFOOT_COND_INFERENCE_CONV___cond_choose_const_internal expL tt = 
let
   val (_,pre_main,_,_) = dest_SMALLFOOT_COND_HOARE_TRIPLE tt;
   val (wpb,rpb,sfb) = dest_smallfoot_prop pre_main;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   
    
   val expL_termL = map smallfoot_p_expression_eval___SIMULATE (fst (listLib.dest_list expL));
   val const_termL = map (fn t => if (is_smallfoot_ae_const_null t) then dest_smallfoot_ae_const_null t else
				  let
                                     val v = dest_smallfoot_ae_var t;
				     val found_opt = find_first_num (K (smallfoot_ae_var___is_equals_const v)) [] 0 sfs
                                     val _ = if (isSome found_opt) then () else raise UNCHANGED;
                                     val (_,_,c) = valOf found_opt
			          in
				     c
                                  end) expL_termL;
   val cL = listLib.mk_list(const_termL,numSyntax.num);

   val thm0 = PART_MATCH (snd o dest_imp o snd o dest_imp) 
      (SPEC_ALL SMALLFOOT_COND_INFERENCE___cond_choose_const_ELIM) tt
   val thm1 = INST [``cL:num list`` |-> cL] thm0 

   val thm2 = CONV_RULE (RAND_CONV (RATOR_CONV (RAND_CONV 
                    (SIMP_CONV list_ss [SMALLFOOT_P_EXPRESSION_EVAL_def])))) thm1
   val thm3 = CONV_RULE (RATOR_CONV (RAND_CONV 
                    (SIMP_CONV list_ss [SMALLFOOT_P_EXPRESSION_EVAL_def]))) thm2;
   val thm4 = CONV_RULE (RATOR_CONV (RAND_CONV 
                    (DEPTH_CONV (smallfoot_ap_implies_ae_equal___CONV) THENC
	             REWRITE_CONV[]))) thm3;
   val thm5 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___cond_choose_const" [] thm4;


   val pre_cond = (fst o dest_imp o concl) thm5; 
   val thm6 = PART_MATCH (snd o dest_imp o snd o dest_imp) 
      (SPEC_ALL SMALLFOOT_COND_INFERENCE___smallfoot_cond_best_local_action) pre_cond

   val thm7 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___cond_choose_const" [] thm6;
   val thm8 = IMP_TRANS thm7 thm5
   val thm9 = CONV_RULE (RATOR_CONV (REWRITE_CONV [bagTheory.BAG_UNION_INSERT,
			    bagTheory.BAG_UNION_EMPTY])) thm8

   val thm10 = CONV_RULE (RATOR_CONV (RAND_CONV (RENAME_VARS_CONV ["frame_sfb"]))) thm9
in
   thm10
end;



fun SMALLFOOT_COND_INFERENCE_CONV___cond_choose_const t =
let
   val thm0 = SMALLFOOT_COND_INFERENCE___block_to_seq_CONV t;
   val t' = rhs (concl thm0);
   val command = dest_SMALLFOOT_COND_HOARE_TRIPLE___first_command t';
   val (c,pre,post,_,_,expL) = dest_smallfoot_cond_choose_const_best_local_action command;

   val thm1 = MAKE___IMP___RULE (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___EQ_PROPAGATE_CONV true true) t');
   val thm2 = IMP_TRANS thm1 (MAKE___IMP___RULE thm0)

   val t'' = (fst o dest_imp o concl) thm2
   val thm3 = DEPTH_CONSEQ_CONV (SMALLFOOT_COND_INFERENCE_CONV___cond_choose_const_internal expL) t''
   val thm4 = IMP_TRANS thm3 thm2
in
   thm4
end;



(*
val tt = snd (strip_forall t'')

val t = ``
 SMALLFOOT_COND_HOARE_TRIPLE penv
      (smallfoot_prop ({|t|},{|x|})
         {|smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
           smallfoot_ap_points_to (smallfoot_ae_const t_const)
             (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n));
           smallfoot_ap_unequal (smallfoot_ae_const t_const)
             smallfoot_ae_null;
           smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_const n);
           smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_var x)
             (smallfoot_ae_const t_const)|}) (smallfoot_prog_block [])
      (smallfoot_prop ({|t|},{|x|})
         {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_var x)
             (smallfoot_ae_var t);
           smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_var t)|})``

*)


fun SMALLFOOT_COND_INFERENCE_CONV___skip_internal tt = 
let
   val thm0_opt = SOME (SMALLFOOT_COND_INFERENCE_CONV___points_to_UNEQAL_INTRO tt)
	      handle UNCHANGED => NONE
   val thm1 = PART_MATCH (snd o dest_imp o snd o dest_imp) 
      (SPEC_ALL SMALLFOOT_COND_HOARE_TRIPLE___SOLVE) 
      (if isSome thm0_opt then (rhs (concl (valOf thm0_opt))) else tt)

   val thm2 = smallfoot_precondition_prove_RULE "SMALLFOOT_COND_INFERENCE___skip" [] thm1;
   val thm3 = CONV_RULE (RATOR_CONV (RAND_CONV (RENAME_VARS_CONV ["frame_sfb"]))) thm2

   val thm4 = if (isSome thm0_opt) then ONCE_REWRITE_RULE [GSYM (valOf thm0_opt)] thm3 else thm3;
in
   thm4
end;



fun SMALLFOOT_COND_INFERENCE_CONV___skip t =
let
   val (penv,prev,prog,post) = dest_SMALLFOOT_COND_HOARE_TRIPLE t;
   val _ = if (prog = ``smallfoot_prog_block []``) then () else raise UNCHANGED;

   val thm1 = MAKE___IMP___RULE (SMALLFOOT_COND_HOARE_TRIPLE___PRECOND_CONV (smallfoot_prop___EQ_PROPAGATE_CONV true true) t);
   val t'' = (fst o dest_imp o concl) thm1
   val thm2 = DEPTH_CONSEQ_CONV SMALLFOOT_COND_INFERENCE_CONV___skip_internal t''
   val thm3 = IMP_TRANS thm2 thm1
in
   thm3
end;



val SMALLFOOT_COND_INFERENCE_CONV___prog_step = 
    FIRST_CONV (map QCHANGED_CONV [SMALLFOOT_COND_INFERENCE_CONV___assign,
  SMALLFOOT_COND_INFERENCE_CONV___new,
  SMALLFOOT_COND_INFERENCE_CONV___cond,
  SMALLFOOT_COND_INFERENCE_CONV___field_lookup,
  SMALLFOOT_COND_INFERENCE_CONV___field_assign,
  SMALLFOOT_COND_INFERENCE_CONV___dispose,
  SMALLFOOT_COND_INFERENCE_CONV___skip,
  SMALLFOOT_COND_INFERENCE_CONV___cond_choose_const]);



















fun SMALLFOOT_PROP_IMPLIES___RESORT_CONV contextL splitL impL t = 
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;
   val (func, argL) = strip_comb t;

   val thm0 = REFL (list_mk_comb (func, List.take (argL,3)))

   val context_thm = BAG_RESORT_CONV contextL (el 4 argL)
   val thm1 = MK_COMB (thm0, context_thm);

   val split_thm = BAG_RESORT_CONV splitL (el 5 argL)
   val thm2 = MK_COMB (thm1, split_thm);

   val imp_thm = BAG_RESORT_CONV impL (el 6 argL)
   val thm3 = MK_COMB (thm2, imp_thm);

   val thm4 = AP_THM thm3 (el 7 argL)
in
   thm4
end 

fun SMALLFOOT_PROP_IMPLIES___WEAK_COND_CONV context_conv split_conv imp_conv t = 
let
   val (sr,wpb,rpb,wpb',sfb_context,sfb_split,sfb_imp,sfb_rest) = dest_SMALLFOOT_PROP_IMPLIES t;
   val thm0 = SPECL [wpb,rpb,wpb', sfb_context, sfb_split, sfb_imp,
	        sfb_rest, sr] SMALLFOOT_PROP_IMPLIES___WEAK_COND_REWRITE;
   val weak_pre_cond = (fst o dest_imp o fst o dest_imp o snd o strip_forall o concl) thm0

   fun option_conv conv t =
       ((SOME ((CHANGED_CONV (conv weak_pre_cond)) t) handle HOL_ERR _ => NONE), t)

   val context_thm_opt = option_conv context_conv sfb_context;
   val split_thm_opt = option_conv split_conv sfb_split;
   val imp_thm_opt = option_conv imp_conv sfb_imp;

   val _ = if ((isSome (fst context_thm_opt)) orelse
               (isSome (fst split_thm_opt)) orelse
               (isSome (fst imp_thm_opt))) then () else raise UNCHANGED;
   fun thm_opt_expand thm_opt =
       if (isSome (fst thm_opt)) then valOf (fst thm_opt) else REFL (snd thm_opt)


   val precond_thm = DISCH weak_pre_cond (ADD_ASSUM weak_pre_cond (
                       LIST_CONJ (map thm_opt_expand 
				 [context_thm_opt,
				  split_thm_opt,
				  imp_thm_opt])))
in
   MATCH_MP thm0 precond_thm
end





fun SMALLFOOT_PROP_IMPLIES___EQ_PROPAGATE___CONSEQ_CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED
   val thm0 = (REWRITE_CONV [smallfoot_ae_null_def] t)
               handle UNCHANGED => REFL t;
   val t' = rhs (concl thm0)
   val (_,wpb,rpb,_,_,sfb,sfb',_) = dest_SMALLFOOT_PROP_IMPLIES t';
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val (sfs', _) = bagSyntax.dest_bag sfb';
   val found_opt = find_first_num (K (smallfoot_ae_var___is_equals_const___excluded [])) [] 0 sfs 
   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (pos,_,(v,c)) = valOf found_opt;
   val thm1 = CONV_RULE (RHS_CONV (SMALLFOOT_PROP_IMPLIES___RESORT_CONV [] [pos] [])) thm0
   val needs_rewrite_opt = LIST_SMALLFOOT_AP_USED_VARS___SAVE_IN true v sfs';
   val needs_rewrite = (not (isSome needs_rewrite_opt)) orelse (valOf needs_rewrite_opt);
in 
   if (not needs_rewrite) then
      let    
	 val t'' = rhs (concl thm1)
         val thm2 = PART_MATCH (lhs o snd o dest_imp) (SPEC_ALL SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT) t''
         val pre_cond = fst (dest_imp (concl thm2))
         val pre_cond_thm = EQT_ELIM (REWRITE_CONV [SMALLFOOT_IS_STRONG_STACK_PROPOSITION___EVAL] pre_cond)
         val thm3 = MP thm2 pre_cond_thm
	 val thm4 = TRANS thm1 thm3
      in
         thm4
      end
    else
      let
	 val t'' = rhs (concl thm1)
         val thm2 = PART_MATCH (snd o dest_imp o snd o dest_imp) (SPEC_ALL SMALLFOOT_PROP_IMPLIES___equal_const) t''
         val thm3 = smallfoot_precondition_prove_RULE "SMALLFOOT_PROP_IMPLIES___EQ_PROPAGATE" [] thm2;
         val thm4 = CONV_RULE (RAND_CONV (ONCE_REWRITE_CONV [GSYM thm1])) thm3;


         val t''' = (fst o dest_imp o concl) thm4;
         val var_update_thm = SMALLFOOT_PROP_IMPLIES___WEAK_COND_CONV (K REFL) (K REFL) smallfoot_ap_var_update___INTERNAL_CONV t'''

         val thm5 = CONV_RULE (RATOR_CONV (REWRITE_CONV [var_update_thm])) thm4;
       in
         thm5
       end 
end;


fun SMALLFOOT_PROP_IMPLIES___SIMP_EQ___CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED
in 
   smallfoot___PROP_SIMPLE_EQ_REWRITES_CONV  t
end;



fun SMALLFOOT_PROP_IMPLIES___ELIM_stack_true___CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED

   val (_,_,_,_,_,_,sfb,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs, _) = bagSyntax.dest_bag sfb;

   val found_opt = find_first_num 
          (K (fn t => if (same_const smallfoot_ap_stack_true_term t) then SOME () else NONE))
          [] 0 sfs;
   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (pos,_,_) = valOf found_opt;
   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV [] [] [pos] t   
   val thm1 = CONV_RULE (RHS_CONV (REWRITE_CONV [SMALLFOOT_PROP_IMPLIES___stack_true])) thm0
in 
   thm1
end;





fun SMALLFOOT_PROP_IMPLIES___ELIM_FRAME___CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED

   val (_,_,_,_,_,sfb,sfb',_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val (sfs', _) = bagSyntax.dest_bag sfb';

   val found_opt = find_first_num 
          (K (fn t => find_first_num (K (fn t' => (if (t' = t) then SOME () else NONE))) [] 0 sfs'))
          [] 0 sfs;
   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (pos,_,(pos2, _, _)) = valOf found_opt;
   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV [] [pos] [pos2] t   
   val thm1 = CONV_RULE (RHS_CONV (REWRITE_CONV [SMALLFOOT_PROP_IMPLIES___FRAME])) thm0
in 
   thm1
end;


(*
val t = ``
SMALLFOOT_PROP_IMPLIES T
           ({|smallfoot_var "z"; smallfoot_var "x"|},{| |}) {| |}
           {|smallfoot_ap_equal (smallfoot_ae_var (smallfoot_var "z"))
               (smallfoot_ae_const z_const);
             smallfoot_ap_equal (smallfoot_ae_var (smallfoot_var "x"))
               (smallfoot_ae_const x_const)|}
           {|smallfoot_ap_points_to (smallfoot_ae_const z_const)
               (FEMPTY |+ (smallfoot_tag "c",smallfoot_ae_const 3));
             smallfoot_ap_points_to (smallfoot_ae_const x_const)
               (FEMPTY |+ (smallfoot_tag "c",smallfoot_ae_const 3))|}
           {|smallfoot_ap_points_to (smallfoot_ae_const x_const) FEMPTY;
             smallfoot_ap_points_to (smallfoot_ae_const z_const) FEMPTY|}
           frame_sfb``



val t =
    ``SMALLFOOT_PROP_IMPLIES F ({|t|},{|x; y|}) {| |}
        {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
            (smallfoot_ae_const y_const);
          smallfoot_ap_equal (smallfoot_ae_var x)
            (smallfoot_ae_const t_const);
          smallfoot_ap_equal (smallfoot_ae_var y)
            (smallfoot_ae_const y_const);
          smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n)|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_const n)
            (smallfoot_ae_const y_const);
          smallfoot_ap_points_to (smallfoot_ae_const t_const)
            (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n))|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl")
            (smallfoot_ae_const t_const) (smallfoot_ae_const y_const)|}
        frame_sfb``;


val t =
    ``SMALLFOOT_PROP_IMPLIES F ({|t|},{|x; y|}) {| |}
        {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
            (smallfoot_ae_null);
          smallfoot_ap_equal (smallfoot_ae_var x)
            (smallfoot_ae_const t_const);
          smallfoot_ap_equal (smallfoot_ae_var y)
            (smallfoot_ae_const y_const);
          smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n)|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_const n)
            (smallfoot_ae_const y_const);
          smallfoot_ap_points_to (smallfoot_ae_const t_const)
            (FEMPTY |+ (smallfoot_tag "lt",smallfoot_ae_const n)
                    |+ (smallfoot_tag "rt",smallfoot_ae_const n'))|}
        {|smallfoot_ap_bintree (smallfoot_tag "lt", smallfoot_tag "rt")
            (smallfoot_ae_const t_const)|}
        frame_sfb``;


val ex_list = [];

SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___CONSEQ_CONV t

use_smallfoot_pretty_printer := true
*)


exception SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn of 
	  (int option * int option)


fun SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH sfs_context sfs_split sfs_imp
                                                     ex_list =
let 
   val ex_imp =  map (fn (a,b) => valOf a) (
                  filter (fn (a,b) => isSome a andalso not (isSome b)) ex_list);
   val imp_opt = find_first_num (K (fn t => (SOME (dest_smallfoot_ap_spatial t)))) ex_imp 0 sfs_imp 
   val _ = if (isSome imp_opt) then () else raise UNCHANGED;
   val (imp_pos, imp_term, e1_term) = valOf imp_opt;

   val ex_split =  map (fn (a,b) => valOf b) (
                  filter (fn (a,b) => (a = SOME imp_pos) andalso isSome b) ex_list);
   val split_opt = find_first_num (K (fn t => 
                         let
			    val (e1_term', L) = dest_smallfoot_ap_points_to t
                         in
                            if (e1_term = e1_term') then SOME L else NONE
                         end)) ex_split 0 sfs_split
   val _ = if isSome split_opt then () else
	      (raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn
		    (SOME imp_pos, NONE));

   val (split_pos, _, L) = valOf split_opt;
   val (L_list, L_rest) = dest_finite_map L
   val (thm, unequal_opt) = 
        if is_smallfoot_ap_points_to imp_term then
	   let
			val (_,L') = dest_smallfoot_ap_points_to imp_term
                        val (L'_list, L'_rest) = dest_finite_map L'
			val _ = if (L_rest = L'_rest) andalso
                                   all (fn e => mem e L_list) L'_list then () else
				raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn (SOME imp_pos, SOME split_pos)			
	   in
                        (SMALLFOOT_PROP_IMPLIES___points_to___points_to, NONE)
           end
        else if is_smallfoot_ap_list_seg_or_list imp_term then
	   let
              val (tl,_,e2_term) = dest_smallfoot_ap_list_seg_or_list imp_term
              val e3_term = snd (first (fn (a,b) => (a = tl)) L_list)
                            handle HOL_ERR _ =>
            		    raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn (SOME imp_pos, SOME split_pos)

              val thm = if is_smallfoot_ap_list imp_term then
			    SMALLFOOT_PROP_IMPLIES___points_to___list else
			    SMALLFOOT_PROP_IMPLIES___points_to___list_seg
	      val thm = SPEC e3_term thm
	   in
              (thm, SOME (e1_term, e2_term))
           end 
        else if is_smallfoot_ap_bintree imp_term then
	   let
              val (lt,rt,_) = dest_smallfoot_ap_bintree imp_term
              val (el_term,er_term) = 
                            (snd (first (fn (a,b) => (a = lt)) L_list),
                             snd (first (fn (a,b) => (a = rt)) L_list))
                            handle HOL_ERR _ =>
            		    raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn (SOME imp_pos, SOME split_pos)

              val thm = SPECL [el_term, er_term]
			    SMALLFOOT_PROP_IMPLIES___points_to___bintree
	   in
              (thm, SOME (e1_term, smallfoot_ae_null_term))
           end 
        else
           raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn (SOME imp_pos, SOME split_pos);

   val unequal_pos_turn_opt = if not (isSome unequal_opt) then NONE else
      let
          val (left_e,right_e) = valOf unequal_opt;
          val unequal_opt2 = find_first_num (K (fn t => 
		       let 
			  val (l,r) = dest_smallfoot_ap_unequal t;
                       in
                          if (l = left_e) andalso (r = right_e) then SOME false else 
                          if (l = right_e) andalso (r = left_e) then SOME true else NONE
		       end)) [] 0 sfs_context;  
          val _ = if isSome unequal_opt2 then () else
                  raise SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn (SOME imp_pos, NONE);         
	  val (u_pos, _, u_turn) = valOf unequal_opt2;
      in
          SOME (u_pos, u_turn)
      end
in
   (thm, split_pos, imp_pos, unequal_pos_turn_opt)
end handle SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH_exn ex =>
    SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH sfs_context sfs_split sfs_imp
                                                     (cons ex ex_list);


fun SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___CONSEQ_CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;

   val (_,_,_,_,sfb_context, sfb_split,sfb_imp,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs_context, _) = bagSyntax.dest_bag sfb_context;
   val (sfs_split, _) = bagSyntax.dest_bag sfb_split;
   val (sfs_imp, _) = bagSyntax.dest_bag sfb_imp;

   val (implies_thm, split_pos, imp_pos, unequal_pos_turn_opt) =
    SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___SEARCH sfs_context sfs_split sfs_imp []

   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV (if isSome unequal_pos_turn_opt then [fst (valOf unequal_pos_turn_opt)] else [])
	                                        [split_pos] [imp_pos] t
	
   val thm1 = if (isSome unequal_pos_turn_opt andalso (snd (valOf unequal_pos_turn_opt))) then
       CONV_RULE ((RHS_CONV o RATOR_CONV o RATOR_CONV o RATOR_CONV o RAND_CONV) (bag_el_conv smallfoot_ap_unequal_comm___CONV 0)) thm0
              else thm0
	
   val t' = rhs (concl thm1);
   val thm2 = PART_MATCH (snd o dest_imp o snd o dest_imp) (SPEC_ALL implies_thm) t'
   val thm3 = smallfoot_precondition_prove_RULE "SMALLFOOT_PROP_IMPLIES___POINTS_TO_ELIM" [] thm2;

   val thm1_imp = snd (EQ_IMP_RULE thm1)
   val thm4 = IMP_TRANS thm3 thm1_imp
in 
   thm4
end;





exception SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH_exn of 
	  (int option * int option);


fun SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH sfs_split sfs_imp
							sfb_context 
                                                     ex_list =
let 
   val ex_imp =  map (fn (a,b) => valOf a) (
                  filter (fn (a,b) => isSome a andalso not (isSome b)) ex_list);
   val imp_opt = find_first_num (K (fn t => (SOME (dest_smallfoot_ap_list_seg_or_list t)))) ex_imp 0 sfs_imp 
   val _ = if (isSome imp_opt) then () else raise UNCHANGED;
   val (imp_pos, imp_term, (tl, e1_term, e3_term)) = valOf imp_opt;

   val ex_split =  map (fn (a,b) => valOf b) (
                  filter (fn (a,b) => (a = SOME imp_pos) andalso isSome b) ex_list);
   val split_opt = find_first_num (K (fn t => 
                         let
			    val (tl', e1_term', e2_term) = dest_smallfoot_ap_list_seg t
                         in
                            if (e1_term = e1_term') andalso (tl = tl') then SOME e2_term else NONE
                         end)) ex_split 0 sfs_split
   val _ = if isSome split_opt then () else
	      (raise SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH_exn
		    (SOME imp_pos, NONE));

   val (split_pos, _, e2_term) = valOf split_opt;
   
   val (thm, ap_bag_implies_thm_opt) = if (is_smallfoot_ap_list imp_term) then
					   (SMALLFOOT_PROP_IMPLIES___list___REMOVE_START, NONE) else
       let
           val sfb_imp = bagSyntax.mk_bag (
                           list_remove_element imp_pos sfs_imp,
                           type_of imp_term)
           val sfb = bagSyntax.mk_union (sfb_imp, sfb_context);           
	   val ap_bag_implies_thm = smallfoot_ap_bag_implies_in_heap_or_null___PROVE sfb e3_term
       in
           (SMALLFOOT_PROP_IMPLIES___list_seg___REMOVE_START, SOME ap_bag_implies_thm)
       end
in
   (thm, ap_bag_implies_thm_opt, split_pos, imp_pos)
end handle SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH_exn ex =>
    SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH sfs_split sfs_imp
							sfb_context 
                                                     (cons ex ex_list);


(*
val t =
    ``SMALLFOOT_PROP_IMPLIES F ({|t|},{|x|}) {| |}
        {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
            smallfoot_ae_null;
          smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_const n);
          smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
          smallfoot_ap_equal (smallfoot_ae_var x)
            (smallfoot_ae_const x_const)|}
        {|smallfoot_ap_points_to (smallfoot_ae_const t_const)
            (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n));
          smallfoot_ap_list_seg (smallfoot_tag "tl")
            (smallfoot_ae_const x_const) (smallfoot_ae_const t_const)|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl")
            (smallfoot_ae_const x_const) (smallfoot_ae_const n)|}
        frame_sfb`` 
*)


fun SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___CONSEQ_CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;

   val (_,_,_,_,sfb_context, sfb_split,sfb_imp,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs_split, _) = bagSyntax.dest_bag sfb_split;
   val (sfs_imp, _) = bagSyntax.dest_bag sfb_imp;

   val (implies_thm, pre_cond_thm_opt, split_pos, imp_pos) =
    SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___SEARCH sfs_split sfs_imp sfb_context []

   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV [] [split_pos] [imp_pos] t
	
   val part_fun = if (isSome pre_cond_thm_opt) then
              (snd o dest_imp o snd o dest_imp o snd o dest_imp)
              else (snd o dest_imp o snd o dest_imp)
	
   val t' = rhs (concl thm0);
   val thm1 = PART_MATCH part_fun (SPEC_ALL implies_thm) t'
   val thm2 = if (isSome pre_cond_thm_opt) then
		  MP thm1 (valOf pre_cond_thm_opt) else  thm1
   val thm3 = smallfoot_precondition_prove_RULE "SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START" [] thm2;

   val thm0_imp = snd (EQ_IMP_RULE thm0)
   val thm4 = IMP_TRANS thm3 thm0_imp
in 
   thm4
end;














fun is_STRONG_STACK_PROPOSITION___PROVE t =
   let
      val t' = mk_comb (``SMALLFOOT_IS_STRONG_STACK_PROPOSITION``, t);
   in
      EQT_ELIM (QCHANGED_CONV (REWRITE_CONV [SMALLFOOT_IS_STRONG_STACK_PROPOSITION___EVAL]) t')
   end


(*
val t = 
``
SMALLFOOT_PROP_IMPLIES T ({|t; x|},{| |}) {|t|} {| |}
        {|smallfoot_ap_equal (smallfoot_ae_var x)
            (smallfoot_ae_const x_const);
          smallfoot_ap_less (smallfoot_ae_var t)
            (smallfoot_ae_const x_const);
          smallfoot_ap_list (smallfoot_tag "tl")
            (smallfoot_ae_const x_const)|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_var x)
            (smallfoot_ae_var t);
          smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_var t)|}
        frame_sfb ``
*)

fun SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT___CONV no_eq_const t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;

   val (_,_,_,_,_,sfb,_,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num 
          (K (fn t => if (no_eq_const andalso isSome (smallfoot_ae_var___is_equals_const___excluded [] t)) then 
                         (*ignore cases that are handled by EQ_propagation*) NONE
                      else
                           (SOME (is_STRONG_STACK_PROPOSITION___PROVE t))))
          [] 0 sfs;
   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (pos,_,is_strong_thm) = valOf found_opt;

   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV [] [pos] [] t   

   val t' = rhs (concl thm0);
   val thm1 = PART_MATCH (lhs o snd o dest_imp) (SPEC_ALL SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT) t'
   val thm2 = MP thm1 is_strong_thm


   val thm3 = TRANS thm0 thm2
in
   thm3
end;



fun is_STRONG_STACK_PROPOSITION___USED_VARS_DIFF___PROVE wpb rpb wpb' tt =
   let
      val pre_cond = ``smallfoot_prop___WEAK_COND ^wpb ^rpb``
      val t' = ``SMALLFOOT_AP_PERMISSION_UNIMPORTANT___USED_VARS
              (SET_OF_BAG ^wpb UNION SET_OF_BAG ^rpb DIFF SET_OF_BAG ^wpb') ^tt``;
   in
      smallfoot_precondition_prove NONE [pre_cond] t'
   end


(*
val t = 
``
SMALLFOOT_PROP_IMPLIES T ({|t; x|},{| |}) {|t|} {| smallfoot_ap_equal (smallfoot_ae_var x)
            (smallfoot_ae_const x_const);
          smallfoot_ap_less (smallfoot_ae_var t)
            (smallfoot_ae_const x_const)|}
        {|smallfoot_ap_list (smallfoot_tag "tl")
            (smallfoot_ae_const x_const)|}
        {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_var x)
            (smallfoot_ae_var t);
          smallfoot_ap_list (smallfoot_tag "tl") (smallfoot_ae_var t)|}
        frame_sfb ``

val t = 
``
 SMALLFOOT_PROP_IMPLIES T ({|t|},{|x; y|}) {| |}
         {|smallfoot_ap_list_seg (smallfoot_tag "tl") (smallfoot_ae_const n)
             (smallfoot_ae_const y_const);
           smallfoot_ap_equal (smallfoot_ae_var x)
             (smallfoot_ae_const t_const);
           smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
           smallfoot_ap_equal (smallfoot_ae_var y)
             (smallfoot_ae_const y_const)|}
         {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
             (smallfoot_ae_const y_const);
           smallfoot_ap_points_to (smallfoot_ae_const t_const)
             (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n))|} {| |}
         frame_sf``


(REPEATC SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___FROM_CONTEXT___CONV) t
*)



(*This reverses some parts of 
  SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT___CONV.
  Be careful not to cause nonterminating loops. It should just be
  used in the final step*)

fun SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___FROM_CONTEXT___CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;

   val (_,wpb,rpb,wpb',sfb,_,_,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val (sfs, _) = bagSyntax.dest_bag sfb;
   val found_opt = find_first_num 
          (K (fn t => let
                         val thm = is_STRONG_STACK_PROPOSITION___PROVE t;
			 (*the theorem used_vars_thm is not used here, but it needs to be provable,
			   a exeption is raised to find another element, if the theorem
			   can not be proved*)
                         val used_vars_thm = is_STRONG_STACK_PROPOSITION___USED_VARS_DIFF___PROVE wpb rpb wpb' t;
                      in
                         (SOME thm)
                      end))
          [] 0 sfs;
   val _ = if (isSome found_opt) then () else raise UNCHANGED;
   val (pos,_,is_strong_thm) = valOf found_opt;

   val thm0 = SMALLFOOT_PROP_IMPLIES___RESORT_CONV [pos] [] [] t   

   val t' = rhs (concl thm0);
   val thm1 = PART_MATCH (lhs o snd o dest_imp) (GSYM (SPEC_ALL SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT)) t'
   val thm2 = MP thm1 is_strong_thm

   val thm3 = TRANS thm0 thm2
in
   thm3
end;


(* 

val t = ``
SMALLFOOT_PROP_IMPLIES T ({|t|},{|x; y|}) {| |}
           {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
               (smallfoot_ae_const y_const);
             smallfoot_ap_list_seg (smallfoot_tag "tl")
               (smallfoot_ae_const n) (smallfoot_ae_const y_const);
             smallfoot_ap_equal (smallfoot_ae_var x)
               (smallfoot_ae_const t_const);
             smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
             smallfoot_ap_equal (smallfoot_ae_var y)
               (smallfoot_ae_const y_const)|}
           {|smallfoot_ap_points_to (smallfoot_ae_const t_const)
               (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n))|} {| |}
           frame_sf``


val t = 
``SMALLFOOT_PROP_IMPLIES T ({|t|},{|x; y|}) {| |}
          {|smallfoot_ap_unequal (smallfoot_ae_const t_const)
              (smallfoot_ae_const y_const);
            smallfoot_ap_list_seg (smallfoot_tag "tl")
              (smallfoot_ae_const n) (smallfoot_ae_const y_const);
            smallfoot_ap_equal (smallfoot_ae_var x)
              (smallfoot_ae_const t_const);
            smallfoot_ap_equal (smallfoot_ae_var t) (smallfoot_ae_const n);
            smallfoot_ap_equal (smallfoot_ae_var y)
              (smallfoot_ae_const y_const)|}
          {|smallfoot_ap_points_to (smallfoot_ae_const t_const)
              (FEMPTY |+ (smallfoot_tag "tl",smallfoot_ae_const n))|} {| |}
          frame_sfb``

*)


fun SMALLFOOT_PROP_IMPLIES___SOLVE___CONSEQ_CONV t =
let
   val _ = if (is_SMALLFOOT_PROP_IMPLIES t) then () else raise UNCHANGED;

   val (strong_flag,wpb,rpb,wpb',_,_,sfb_imp,_) = dest_SMALLFOOT_PROP_IMPLIES t;
   val _ = if (is_EMPTY_BAG sfb_imp) then () else raise UNCHANGED;

   val thm0 = REPEATC (SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT___CONV false) t 
              handle UNCHANGED => REFL t

   (*just move something back, if the strong_flag indicates so*)
   val thm1 = if not (strong_flag = T) then thm0 else
              CONV_RULE (RHS_CONV (
                  REPEATC SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___FROM_CONTEXT___CONV
              )) thm0
              handle UNCHANGED => thm0
   
   val t' = rhs (concl thm1);
   val thm2 = PART_MATCH (snd o dest_imp o snd o dest_imp) (GSYM (SPEC_ALL SMALLFOOT_PROP_IMPLIES___SOLVE)) t'
   val thm3 = smallfoot_precondition_prove_RULE "SMALLFOOT_PROP_IMPLIES___SOLVE___CONV" [] thm2;

   val thm1_imp = snd (EQ_IMP_RULE thm1)
   val thm4 = IMP_TRANS thm3 thm1_imp
in
   thm4
end;



val SMALLFOOT_PROP_IMPLIES___SIMPS = 
    FIRST_CONV (map QCHANGED_CONV [
        SMALLFOOT_PROP_IMPLIES___EQ_PROPAGATE___CONSEQ_CONV,
        SMALLFOOT_PROP_IMPLIES___SIMP_EQ___CONV,
	SMALLFOOT_PROP_IMPLIES___ELIM_stack_true___CONV,
	SMALLFOOT_PROP_IMPLIES___ELIM_FRAME___CONV,
	SMALLFOOT_PROP_IMPLIES___ELIM_POINTS_TO___CONSEQ_CONV,
	SMALLFOOT_PROP_IMPLIES___STRONG_STACK_PROPOSITION___TO_CONTEXT___CONV true,
        SMALLFOOT_PROP_IMPLIES___LIST_REMOVE_START___CONSEQ_CONV,
	SMALLFOOT_PROP_IMPLIES___SOLVE___CONSEQ_CONV]);


val SMALLFOOT_STEP_TAC =
  ONCE_DEPTH_CONSEQ_CONV_TAC SMALLFOOT_COND_INFERENCE_CONV___prog_step ORELSE
  DEPTH_CONSEQ_CONV_TAC SMALLFOOT_PROP_IMPLIES___SIMPS ORELSE
  SIMP_TAC std_ss [FORALL_AND_THM, BAG_EVERY_THM]



val SMALLFOOT_STEP___CONSEQ_CONV =
   FIRST_CONV [
     SMALLFOOT_COND_INFERENCE_CONV___prog_step,
     SMALLFOOT_PROP_IMPLIES___SIMPS]

val SMALLFOOT_SOLVE_TAC =
REPEAT 
(DEPTH_CONSEQ_CONV_TAC SMALLFOOT_STEP___CONSEQ_CONV THEN
 SIMP_TAC std_ss [FORALL_AND_THM, BAG_EVERY_THM])



val SMALLFOOT_INPUT_FILE_TAC =
 CONSEQ_CONV_TAC SMALLFOOT_INPUT_FILE___CONSEQ_CONV



fun smallfoot_set_goal file =
  let
     val t = parse_smallfoot_file file; 
     val _ = proofManagerLib.set_goal([], t);
  in
     proofManagerLib.e SMALLFOOT_INPUT_FILE_TAC
  end;

fun smallfoot_prove file =
  let
     val t = parse_smallfoot_file file; 
     val thm = prove(t, SMALLFOOT_INPUT_FILE_TAC THEN
		        SMALLFOOT_SOLVE_TAC);
  in
     thm
  end;



end;
