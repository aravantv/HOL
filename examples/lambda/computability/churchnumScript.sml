open HolKernel boolLib bossLib Parse binderLib

open chap3Theory
open pred_setTheory
open termTheory
open boolSimps

val _ = new_theory "churchnum"

val _ = set_trace "Unicode" 1

val church_def = Define`
  church n = LAM "z" (LAM "s" (FUNPOW ((@@) (VAR "s")) n (VAR "z")))
`

val FUNPOW_SUC = arithmeticTheory.FUNPOW_SUC

val bnf_church = store_thm(
  "bnf_church",
  ``∀n. bnf (church n)``,
  SRW_TAC [][church_def] THEN 
  Induct_on `n` THEN SRW_TAC [][] THEN 
  SRW_TAC [][FUNPOW_SUC]);


val FV_church = store_thm(
  "FV_church",
  ``FV (church n) = {}``,
  SRW_TAC [][church_def] THEN 
  `(n = 0) ∨ (∃m. n = SUC m)` 
    by METIS_TAC [TypeBase.nchotomy_of ``:num``] THEN 
  SRW_TAC [][] THENL [
    SRW_TAC [CONJ_ss] [EXTENSION],
    Q_TAC SUFF_TAC 
          `FV (FUNPOW ((@@) (VAR "s")) (SUC m) (VAR "z")) = {"s"; "z"}` 
          THEN1 SRW_TAC [CONJ_ss][pred_setTheory.EXTENSION] THEN
    Induct_on `m` THEN SRW_TAC [][] THENL [
      SRW_TAC [][EXTENSION],
      SRW_TAC [][Once FUNPOW_SUC] THEN 
      SRW_TAC [][EXTENSION] THEN METIS_TAC []
    ]
  ]);
val _ = export_rewrites ["FV_church"]
      
val csuc_def = Define`
  csuc = LAM "n" (LAM "z" (LAM "s" 
            (VAR "s" @@ (VAR "n" @@ VAR "z" @@ VAR "s"))))
`;

val tpm_funpow_app = store_thm(
  "tpm_funpow_app",
  ``tpm pi (FUNPOW ($@@ f) n x) = FUNPOW ($@@ (tpm pi f)) n (tpm pi x)``,
  Induct_on `n` THEN SRW_TAC [][FUNPOW_SUC]);
val _  = export_rewrites ["tpm_funpow_app"]

val FV_funpow_app = store_thm(
  "FV_funpow_app",
  ``FV (FUNPOW ($@@ f) n x) ⊆ FV f ∪ FV x``,
  Induct_on `n` THEN SRW_TAC [][FUNPOW_SUC]);

val FV_funpow_app_I = store_thm(
  "FV_funpow_app_I",
  ``v ∈ FV x ⇒ v ∈ FV (FUNPOW ((@@) f) n x)``,
  Induct_on `n` THEN SRW_TAC [][FUNPOW_SUC]);

val FV_funpow_app_E = store_thm(
  "FV_funpow_app_E",                      
  ``v ∈ FV (FUNPOW ((@@) f) n x) ⇒ v ∈ FV f ∨ v ∈ FV x``,
  MATCH_ACCEPT_TAC (REWRITE_RULE [IN_UNION, SUBSET_DEF] FV_funpow_app));

val FV_funpow_app_vars = store_thm(
  "FV_funpow_app_vars",
  ``FV (FUNPOW ($@@ (VAR f)) n (VAR x)) ⊆ {f; x}``,
  Q_TAC SUFF_TAC `FV (VAR f) ∪ FV (VAR x) = {f; x}` 
        THEN1 METIS_TAC [FV_funpow_app] THEN 
  SRW_TAC [][EXTENSION]);

val SUB_funpow_app = store_thm(
  "SUB_funpow_app",
  ``[M/v] (FUNPOW ($@@ f) n x) = FUNPOW ($@@ ([M/v]f)) n ([M/v]x)``,
  Induct_on `n` THEN SRW_TAC [][FUNPOW_SUC]);
val _ = export_rewrites ["SUB_funpow_app"]

val RTC1_step = CONJUNCT2 (SPEC_ALL relationTheory.RTC_RULES)

val _ = set_fixity "-β->" (Infix(NONASSOC, 450))
val _ = overload_on ("-β->", ``compat_closure beta``)

val _ = set_fixity "-β->*" (Infix(NONASSOC, 450))
val _ = overload_on ("-β->*", ``(compat_closure beta)^*``)

val ccbeta_church = store_thm(
  "ccbeta_church",
  ``church n -β-> M ⇔ F``,
  METIS_TAC [beta_normal_form_bnf, corollary3_2_1, bnf_church]);
val _ = export_rewrites ["ccbeta_church"]

val church_eq = store_thm(
  "church_eq", 
  ``(∀s. church n ≠ VAR s) ∧ (∀M N. church n ≠ M @@ N)``,
  SRW_TAC [][church_def]);
val _ = export_rewrites ["church_eq"]



val ccbeta_rwt = store_thm(
  "ccbeta_rwt",
  ``(VAR s -β-> N ⇔ F) ∧
    (LAM x M -β-> N ⇔ ∃N0. (N = LAM x N0) ∧ M -β-> N0) ∧
    (LAM x M @@ N -β-> P ⇔
       (∃M'. (P = LAM x M' @@ N) ∧ M -β-> M') ∨
       (∃N'. (P = LAM x M @@ N') ∧ N -β-> N') ∨
       (P = [N/x]M)) ∧
    (¬is_abs M ⇒ 
      (M @@ N -β-> P ⇔ 
        (∃M'. (P = M' @@ N) ∧ M -β-> M') ∨
        (∃N'. (P = M @@ N') ∧ N -β-> N')))``,
  SRW_TAC [][cc_beta_thm] THENL [
    SRW_TAC [][EQ_IMP_THM, LAM_eq_thm] THEN SRW_TAC [][] THENL [
      METIS_TAC [fresh_tpm_subst, lemma15a],
      SRW_TAC [DNF_ss][tpm_eqr]
    ], 
    Q_TAC SUFF_TAC `!v M'. M ≠ LAM v M'` THEN1 METIS_TAC[] THEN 
    Q.SPEC_THEN `M` FULL_STRUCT_CASES_TAC term_CASES THEN 
    FULL_SIMP_TAC (srw_ss()) []
  ]);

val ccbeta_funpow_var = store_thm(
  "ccbeta_funpow_var",
  ``∀M. FUNPOW ((@@) (VAR v)) n x -β-> M ⇔
        ∃y. (M = FUNPOW ((@@) (VAR v)) n y) ∧ x -β-> y``,
  Induct_on `n`  THEN SRW_TAC [DNF_ss][FUNPOW_SUC, ccbeta_rwt]);
    

val church_behaviour = store_thm(
  "church_behaviour",
  ``church n @@ x @@ f -β->* FUNPOW ($@@ f) n x``,
  SRW_TAC [][church_def] THEN MATCH_MP_TAC RTC1_step THEN 
  Q_TAC (NEW_TAC "z") `{"s"; "z"} ∪ FV x` THEN 
  `LAM "z" (LAM "s" (FUNPOW ($@@ (VAR "s")) n (VAR "z"))) = 
   LAM z (LAM "s" (FUNPOW ($@@ (VAR "s")) n (VAR z)))`
     by (SRW_TAC [CONJ_ss][LAM_eq_thm] THEN 
         `"s" ≠ "z"` by SRW_TAC [][] THEN 
         METIS_TAC [IN_INSERT, NOT_IN_EMPTY, 
                    FV_funpow_app_vars, SUBSET_DEF]) THEN 
  POP_ASSUM SUBST_ALL_TAC THEN 
  Q_TAC (NEW_TAC "s") `{"s"; z} ∪ FV x` THEN 
  `LAM "s" (FUNPOW ($@@ (VAR "s")) n (VAR z)) = 
   LAM s (FUNPOW ($@@ (VAR s)) n (VAR z))`
      by (SRW_TAC [][LAM_eq_thm] THEN 
          METIS_TAC [IN_INSERT, NOT_IN_EMPTY, FV_funpow_app_vars, 
                     SUBSET_DEF]) THEN 
  POP_ASSUM SUBST_ALL_TAC THEN 
  Q.EXISTS_TAC `LAM s (FUNPOW ($@@ (VAR s)) n x) @@ f` THEN CONJ_TAC THEN1
    SRW_TAC [][ccbeta_rwt] THEN 
  SRW_TAC [DNF_ss][Once relationTheory.RTC_CASES1, ccbeta_rwt, 
                   lemma14b]);

val betastar_LAM = store_thm(
  "betastar_LAM",                   
  ``∀M N. LAM x M -β->* LAM x N ⇔ M -β->* N``,
  SIMP_TAC (srw_ss()) [EQ_IMP_THM, FORALL_AND_THM] THEN CONJ_TAC THENL [
    Q_TAC SUFF_TAC `∀M N. M -β->* N ⇒ 
                          ∀v M0 N0. (M = LAM v M0) ∧ (N = LAM v N0) ⇒
                                    M0 -β->* N0` THEN1 METIS_TAC [] THEN 
    HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN 
    SIMP_TAC (srw_ss() ++ DNF_ss) [ccbeta_rwt] THEN 
    METIS_TAC [relationTheory.RTC_RULES],

    HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN 
    SRW_TAC [][] THEN 
    METIS_TAC [compat_closure_rules, relationTheory.RTC_RULES]
  ]);
val _ = export_rewrites ["betastar_LAM"]

val betastar_APPr = store_thm(
  "betastar_APPr",
  ``∀M N. M -β->* N ⇒ P @@ M -β->* P @@ N``,
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN SRW_TAC [][] THEN 
  METIS_TAC [RTC1_step, compat_closure_rules]);

val betastar_APPl = store_thm(
  "betastar_APPl",
  ``∀M N. M -β->* N ⇒ M @@ P -β->* N @@ P``,
  HO_MATCH_MP_TAC relationTheory.RTC_INDUCT THEN SRW_TAC [][] THEN 
  METIS_TAC [RTC1_step, compat_closure_rules]);

val csuc_SUC = store_thm(
  "csuc_SUC",
  ``∀n. (csuc @@ (church n)) -β->* church (SUC n)``,
  GEN_TAC THEN REWRITE_TAC [csuc_def] THEN 
  SRW_TAC [DNF_ss][Once relationTheory.RTC_CASES1, ccbeta_rwt] THEN 
  SRW_TAC [][Q.SPEC `SUC n` church_def, FUNPOW_SUC] THEN 
  SRW_TAC [][betastar_APPr, betastar_LAM, church_behaviour]);

val cplus_def = Define`
  cplus = LAM "m" (LAM "n" (LAM "z" (LAM "s" 
             (VAR "m" @@ (VAR "n" @@ VAR "z" @@ VAR "s") @@ VAR "s"))))
`;

val cplus_behaviour = store_thm(
  "cplus_behaviour",
  ``cplus @@ church m @@ church n -β->* church (m + n)``,
  SRW_TAC [][cplus_def] THEN 
  SRW_TAC [][Once relationTheory.RTC_CASES1, ccbeta_rwt] THEN 
  MATCH_MP_TAC RTC1_step THEN 
  Q.EXISTS_TAC 
    `LAM "z" (LAM "s" 
       (church m @@ (church n @@ VAR "z" @@ VAR "s") @@ VAR "s"))` THEN 
  CONJ_TAC THEN1 SRW_TAC [][ccbeta_rwt, lemma14b] THEN 
  CONV_TAC (RAND_CONV (REWRITE_CONV [church_def])) THEN 
  SRW_TAC [][] THEN 
  ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
  Q.EXISTS_TAC 
    `church m @@ (FUNPOW ($@@ (VAR "s")) n (VAR "z")) @@ VAR "s"` THEN 
  CONJ_TAC THEN1 SRW_TAC [][betastar_APPl, betastar_APPr, church_behaviour] THEN
  SRW_TAC [][arithmeticTheory.FUNPOW_ADD, church_behaviour]);


(* λn.λz.λs. n (λu. z) (λg.λh. h (g s))  (λu. u) *)    
val cpred_def = Define`
  cpred = 
    LAM "n"
     (LAM "z"
       (LAM "s"
          (VAR "n" @@ (LAM "u" (VAR "z")) @@ 
           (LAM "g" (LAM "h" (VAR "h" @@ (VAR "g" @@ VAR "s")))) @@
           (LAM "u" (VAR "u")))))
`;

val cpred_bnf = store_thm(
  "cpred_bnf",
  ``∀M. cpred -β-> M ⇔ F``,
  SRW_TAC [][cpred_def, ccbeta_rwt]);
val _ = export_rewrites ["cpred_bnf"]

val FV_cpred = store_thm(
  "FV_cpred",
  ``FV cpred = {}``,
  SRW_TAC [][cpred_def, EXTENSION] THEN 
  METIS_TAC []);
val _ = export_rewrites ["FV_cpred"]

val cpred_0 = store_thm(
  "cpred_0",
  ``cpred @@ church 0 -β->* church 0``,
  SRW_TAC [][cpred_def] THEN 
  SRW_TAC [][Once relationTheory.RTC_CASES1, ccbeta_rwt] THEN 
  SRW_TAC [][church_def] THEN 
  SRW_TAC [][Once relationTheory.RTC_CASES1, ccbeta_rwt] THEN 
  SRW_TAC [][Once relationTheory.RTC_CASES1, ccbeta_rwt]);

val cpred_funpow = store_thm(
  "cpred_funpow",
  ``g ≠ h ∧ g ≠ s ∧ h ≠ s ∧ g ∉ FV f ∧ h ∉ FV f ⇒ 
      FUNPOW ((@@) (LAM g (LAM h (VAR h @@ (VAR g @@ VAR s)))))
             (SUC n)
             f
    -β->* 
      LAM h (VAR h @@ FUNPOW ((@@) (VAR s)) n (f @@ VAR s))``,
  STRIP_TAC THEN 
  Induct_on `n` THENL [
    SRW_TAC [][FUNPOW_SUC] THEN 
    SRW_TAC [DNF_ss][Once relationTheory.RTC_CASES1, ccbeta_rwt],

    CONV_TAC (LAND_CONV (ONCE_REWRITE_CONV [FUNPOW_SUC])) THEN 
    Q.MATCH_ABBREV_TAC 
      `LAM g M @@ FUNPOW ((@@) (LAM g M)) (SUC n) f -β->* gg` THEN 
    ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
    Q.EXISTS_TAC 
      `LAM g M @@ (LAM h (VAR h @@ FUNPOW ((@@) (VAR s)) n (f @@ VAR s)))` THEN
    SRW_TAC [][betastar_APPr] THEN 
    Q.MATCH_ABBREV_TAC `LAM g M @@ LAM h hh -β->* gg` THEN 
    MATCH_MP_TAC RTC1_step THEN 
    Q.EXISTS_TAC `[LAM h hh/g]M` THEN SRW_TAC [][ccbeta_rwt] THEN 
    `FV hh = {h; s} ∪ FV f`
      by (SRW_TAC [][Abbr`hh`, EXTENSION, EQ_IMP_THM] THENL [
            IMP_RES_TAC FV_funpow_app_E THEN 
            FULL_SIMP_TAC (srw_ss()) [],
            SRW_TAC [][FV_funpow_app_I],
            SRW_TAC [][FV_funpow_app_I]
          ]) THEN 
    SRW_TAC [][Abbr`M`] THEN 
    MATCH_MP_TAC RTC1_step THEN 
    Q.EXISTS_TAC `LAM h (VAR h @@ [VAR s/h]hh)` THEN 
    SRW_TAC [][ccbeta_rwt] THEN 
    SRW_TAC [][Abbr`hh`, lemma14b] THEN 
    SRW_TAC [][Abbr`gg`, FUNPOW_SUC]
  ]);

val cpred_SUC = store_thm(
  "cpred_SUC",
  ``cpred @@ church (SUC n) -β->* church n``,
  SRW_TAC [][cpred_def] THEN 
  SRW_TAC [][Once relationTheory.RTC_CASES1, ccbeta_rwt] THEN 
  CONV_TAC (RAND_CONV (ONCE_REWRITE_CONV [church_def])) THEN 
  SRW_TAC [][] THEN 
  ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
  Q.ABBREV_TAC `hgs = VAR "h" @@ (VAR "g" @@ VAR "s")` THEN 
  Q.ABBREV_TAC `ID = LAM "u" (VAR "u")` THEN 
  Q.ABBREV_TAC `Kz = LAM "u" (VAR "z")` THEN 
  Q.EXISTS_TAC `FUNPOW ((@@) (LAM "g" (LAM "h" hgs))) (SUC n) Kz @@ ID` THEN 
  CONJ_TAC THEN1 SRW_TAC [][betastar_APPl, church_behaviour] THEN 

  ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
  Q.EXISTS_TAC 
    `(LAM "h" 
       (VAR "h" @@ FUNPOW ((@@) (VAR "s")) n (Kz @@ VAR "s"))) @@ ID`  THEN 
  CONJ_TAC THENL [
    MATCH_MP_TAC betastar_APPl THEN 
    SRW_TAC [][Abbr`hgs`, cpred_funpow, Abbr`Kz`],

    SRW_TAC [DNF_ss]
            [Once relationTheory.RTC_CASES1, ccbeta_rwt, ccbeta_funpow_var,
             Abbr`ID`, Abbr`Kz`] THEN 
    SRW_TAC [DNF_ss]
            [Once relationTheory.RTC_CASES1, ccbeta_rwt, ccbeta_funpow_var]
  ]);

val cpred_behaviour = store_thm(
  "cpred_behaviour", 
  ``cpred @@ church n -β->* church (PRE n)``,
  Cases_on `n` THEN SRW_TAC [][cpred_SUC, cpred_0]);

val cminus_def = Define`
  cminus = LAM "m" (LAM "n" (VAR "n" @@ VAR "m" @@ cpred))
`;

val cminus_behaviour = store_thm(
  "cminus_behaviour",
  ``cminus @@ church m @@ church n -β->* church (m - n)``,
  SRW_TAC [][cminus_def] THEN 
  SRW_TAC [DNF_ss][Once relationTheory.RTC_CASES1, ccbeta_rwt, lemma14b] THEN 
  MATCH_MP_TAC RTC1_step THEN 
  Q.EXISTS_TAC `church n @@ church m @@ cpred` THEN 
  SRW_TAC [][ccbeta_rwt, lemma14b] THEN 
  ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
  Q.EXISTS_TAC `FUNPOW ((@@) cpred) n (church m)` THEN 
  SRW_TAC [][church_behaviour] THEN 
  Q.ID_SPEC_TAC `m` THEN Induct_on `n` THEN 
  SRW_TAC [][FUNPOW_SUC] THEN 
  ONCE_REWRITE_TAC [relationTheory.RTC_CASES_RTC_TWICE] THEN 
  Q.EXISTS_TAC `cpred @@ church (m - n)` THEN SRW_TAC [][betastar_APPr] THEN 
  Q_TAC SUFF_TAC `m - SUC n = PRE (m - n)` 
    THEN1 SRW_TAC [][cpred_behaviour] THEN
  DECIDE_TAC);
  
  

  


val _ = export_theory()
