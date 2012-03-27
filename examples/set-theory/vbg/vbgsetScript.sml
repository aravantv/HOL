open HolKernel boolLib bossLib Parse

val _ = new_theory "vbgset"

(* hide constants from the existing (typed) set theory *)
val _ = app (ignore o hide) ["UNION", "IN", "SUBSET", "EMPTY", "INSERT"]

(* create a new type (of VBG classes) *)
val _ = new_type("vbgc", 0)

(* with this call, the syntax with ∈ is enabled as well. *)
val _ = new_constant ("IN", ``:vbgc -> vbgc -> bool``)

(* similarly, this abbreviation also allows for ∉ *)
val _ = overload_on ("NOTIN", ``λx y. ~(x ∈ y)``)

val SET_def = Define` SET(x) = ∃w. x ∈ w `
val SUBSET_def = Define`x ⊆ y <=> ∀u. u ∈ x ⇒ u ∈ y`

val EXTENSION = new_axiom ("EXTENSION", ``(a = b) <=> (∀x. x ∈ a <=> x ∈ b)``)

val SPECIFICATION = new_axiom(
  "SPECIFICATION",
  ``∀(P : vbgc -> bool). ∃w. ∀x. x ∈ w <=> SET(x) ∧ P(x)``);

val SPEC0 = new_specification(
  "SPEC0",
  ["SPEC0"],
  CONV_RULE SKOLEM_CONV SPECIFICATION);

val EMPTY_def = Define`EMPTY = SPEC0 (λx. F)`

val NOT_IN_EMPTY = store_thm(
  "NOT_IN_EMPTY",
  ``x ∉ {}``,
  SRW_TAC [][EMPTY_def, SPEC0]);
val _ = export_rewrites ["NOT_IN_EMPTY"]

val EMPTY_UNIQUE = store_thm(
  "EMPTY_UNIQUE",
  ``(∀x. x ∉ u) ⇒ (u = {})``,
  SRW_TAC [][EXTENSION]);

val INFINITY = new_axiom(
  "INFINITY",
  ``∃w. SET w ∧ (∃u. u ∈ w ∧ ∀x. x ∉ u) ∧
        ∀x. x ∈ w ⇒ ∃y. y ∈ w ∧ ∀u. u ∈ y <=> u ∈ x ∨ (u = x)``);

val EMPTY_SET = store_thm(
  "EMPTY_SET",
  ``SET {}``,
  STRIP_ASSUME_TAC INFINITY THEN
  `u = {}` by SRW_TAC [][EMPTY_UNIQUE] THEN
  `SET u` by METIS_TAC [SET_def] THEN
  METIS_TAC []);
val _ = export_rewrites ["EMPTY_SET"]

val EMPTY_SUBSET = store_thm(
  "EMPTY_SUBSET",
  ``{} ⊆ A ∧ (A ⊆ {} <=> (A = {}))``,
  SRW_TAC [][SUBSET_def] THEN METIS_TAC [EMPTY_UNIQUE, NOT_IN_EMPTY]);
val _ = export_rewrites ["EMPTY_SUBSET"]

val SUBSET_REFL = store_thm(
  "SUBSET_REFL",
  ``A ⊆ A``,
  SRW_TAC [][SUBSET_def]);
val _ = export_rewrites ["SUBSET_REFL"]

val SUBSET_ANTISYM = store_thm(
  "SUBSET_ANTISYM",
  ``(x = y) <=> x ⊆ y ∧ y ⊆ x``,
  SRW_TAC [][EXTENSION, SUBSET_def] THEN METIS_TAC []);

val SUBSET_TRANS = store_thm(
  "SUBSET_TRANS",
  ``x ⊆ y ∧ y ⊆ z ⇒ x ⊆ z``,
  SRW_TAC [][SUBSET_def])

val Sets_def = Define`Sets = SPEC0 (λx. T)`

val SET_Sets = store_thm(
  "SET_Sets",
  ``x ∈ Sets <=> SET x``,
  SRW_TAC [][Sets_def, SPEC0]);

val SUBSET_Sets = store_thm(
  "SUBSET_Sets",
  ``x ⊆ Sets``,
  SRW_TAC [][SUBSET_def, SET_Sets, SET_def] THEN METIS_TAC []);

val RUS_def = Define`
  RUS = SPEC0 (\x. x ∉ x)
`;

(* gives result
     ⊢ RUS ∈ RUS ⇔ SET RUS ∧ RUS ∉ RUS
*)
val RUSlemma =
``RUS ∈ RUS``
    |> (SIMP_CONV (srw_ss()) [RUS_def, Once SPEC0] THENC
        SIMP_CONV (srw_ss()) [GSYM RUS_def])

val RUS_not_SET = store_thm(
  "RUS_not_SET",
  ``¬ SET RUS``,
  METIS_TAC [RUSlemma]);

val POW_def = Define`POW A = SPEC0 (λx. x ⊆ A)`
val IN_POW = store_thm(
  "IN_POW",
  ``x ∈ POW A ⇔ SET x ∧ x ⊆ A``,
  SRW_TAC [][POW_def, SPEC0]);
val _ = export_rewrites ["IN_POW"]

val POWERSET = new_axiom(
  "POWERSET",
  ``SET a ⇒ ∃w. SET w ∧ ∀x. x ⊆ a ⇒ x ∈ w``);

val SUBSETS_ARE_SETS = store_thm(
  "SUBSETS_ARE_SETS",
  ``∀A B. SET A ∧ B ⊆ A ⇒ SET B``,
  REPEAT STRIP_TAC THEN IMP_RES_TAC POWERSET THEN
  `B ∈ w` by METIS_TAC [] THEN
  METIS_TAC [SET_def]);

val POW_SET_CLOSED = store_thm(
  "POW_SET_CLOSED",
  ``∀a. SET a ⇒ SET (POW a)``,
  REPEAT STRIP_TAC THEN IMP_RES_TAC POWERSET THEN
  MATCH_MP_TAC SUBSETS_ARE_SETS THEN
  Q.EXISTS_TAC `w` THEN SRW_TAC [][Once SUBSET_def]);


val SINGC_def = Define`
  SINGC a = SPEC0 (λx. x = a)
`


val PCLASS_SINGC_EMPTY = store_thm(
  "PCLASS_SINGC_EMPTY",
  ``¬SET a ⇒ (SINGC a = {})``,
  SRW_TAC [][SINGC_def, SPEC0, Once EXTENSION]);

val SET_IN_SINGC = store_thm(
  "SET_IN_SINGC",
  ``SET a ⇒ (x ∈ SINGC a ⇔ (x = a))``,
  SRW_TAC [boolSimps.CONJ_ss][SINGC_def, SPEC0]);

val SINGC_11 = store_thm(
  "SINGC_11",
  ``SET x ∧ SET y ⇒ ((SINGC x = SINGC y) = (x = y))``,
  SRW_TAC [][Once EXTENSION, SimpLHS] THEN
  SRW_TAC [][SET_IN_SINGC] THEN METIS_TAC []);
val _ = export_rewrites ["SINGC_11"]


val PAIRC_def = Define`PAIRC a b = SPEC0 (λx. (x = a) ∨ (x = b))`

val SINGC_PAIRC = store_thm(
  "SINGC_PAIRC",
  ``SINGC a = PAIRC a a``,
  SRW_TAC [][SINGC_def, PAIRC_def]);

val PCLASS_PAIRC_EMPTY = store_thm(
  "PCLASS_PAIRC_EMPTY",
  ``¬SET a ∧ ¬SET b ⇒ (PAIRC a b = {})``,
  SRW_TAC [][PAIRC_def, Once EXTENSION, SPEC0] THEN
  Cases_on `x = a` THEN SRW_TAC [][] THEN
  Cases_on `x = b` THEN SRW_TAC [][]);

val SET_IN_PAIRC = store_thm(
  "SET_IN_PAIRC",
  ``SET a ∧ SET b ⇒ (∀x. x ∈ PAIRC a b ⇔ (x = a) ∨ (x = b))``,
  SRW_TAC [boolSimps.CONJ_ss, boolSimps.DNF_ss][PAIRC_def, SPEC0]);

val UNORDERED_PAIRS = new_axiom(
  "UNORDERED_PAIRS",
  ``SET a ∧ SET b ⇒ ∃w. SET w ∧ a ∈ w ∧ b ∈ w``);

val PAIRC_SET_CLOSED = store_thm(
  "PAIRC_SET_CLOSED",
  ``SET a ∧ SET b ⇒ SET (PAIRC a b)``,
  DISCH_THEN (fn th => STRIP_ASSUME_TAC (MATCH_MP UNORDERED_PAIRS th) THEN
                       STRIP_ASSUME_TAC th) THEN
  MATCH_MP_TAC SUBSETS_ARE_SETS THEN Q.EXISTS_TAC `w` THEN
  SRW_TAC [][SUBSET_def, SET_IN_PAIRC] THEN SRW_TAC [][]);

val SINGC_SET = store_thm(
  "SINGC_SET",
  ``SET (SINGC a)``,
  Cases_on `SET a` THEN1 SRW_TAC [][SINGC_PAIRC, PAIRC_SET_CLOSED] THEN
  SRW_TAC [][PCLASS_SINGC_EMPTY]);
val _ = export_rewrites ["SINGC_SET"]

(* UNION ish operations *)

val UNION_def = Define`a ∪ b = SPEC0 (λx. x ∈ a ∨ x ∈ b)`

val IN_UNION = store_thm(
  "IN_UNION",
  ``x ∈ A ∪ B ⇔ x ∈ A ∨ x ∈ B``,
  SRW_TAC [][UNION_def, SPEC0] THEN METIS_TAC [SET_def]);
val _ = export_rewrites ["IN_UNION"]

val BIGUNION_def = Define`BIGUNION A = SPEC0 (λx. ∃y. y ∈ A ∧ x ∈ y)`
val IN_BIGUNION = store_thm(
  "IN_BIGUNION",
  ``x ∈ BIGUNION A ⇔ ∃y. y ∈ A ∧ x ∈ y``,
  SRW_TAC [][BIGUNION_def, SPEC0] THEN METIS_TAC [SET_def]);
val _ = export_rewrites ["IN_BIGUNION"]

val EMPTY_UNION = store_thm(
  "EMPTY_UNION",
  ``({} ∪ A = A) ∧ (A ∪ {} = A)``,
  SRW_TAC [][EXTENSION]);
val _ = export_rewrites ["EMPTY_UNION"]

val UNIONS = new_axiom(
  "UNIONS",
  ``SET a ⇒ ∃w. SET w ∧ ∀x y. x ∈ y ∧ y ∈ a ⇒ x ∈ w``);

val UNION_SET_CLOSED = store_thm(
  "UNION_SET_CLOSED",
  ``SET A ∧ SET B ⇒ SET (A ∪ B)``,
  STRIP_TAC THEN
  `SET (PAIRC A B)` by METIS_TAC [PAIRC_SET_CLOSED] THEN
  POP_ASSUM (STRIP_ASSUME_TAC o MATCH_MP UNIONS) THEN
  POP_ASSUM MP_TAC THEN
  ASM_SIMP_TAC (srw_ss() ++ boolSimps.DNF_ss)[SET_IN_PAIRC] THEN
  STRIP_TAC THEN MATCH_MP_TAC SUBSETS_ARE_SETS THEN Q.EXISTS_TAC `w` THEN
  SRW_TAC [][SUBSET_def] THEN SRW_TAC [][]);

val BIGUNION_SET_CLOSED = store_thm(
  "BIGUNION_SET_CLOSED",
  ``SET A ⇒ SET (BIGUNION A)``,
  STRIP_TAC THEN IMP_RES_TAC UNIONS THEN MATCH_MP_TAC SUBSETS_ARE_SETS THEN
  Q.EXISTS_TAC `w` THEN ASM_SIMP_TAC (srw_ss()) [SUBSET_def] THEN
  METIS_TAC []);

val INSERT_def = Define`x INSERT y = SINGC x ∪ y`

val IN_INSERT = store_thm(
  "IN_INSERT",
  ``x ∈ a INSERT A ⇔ SET a ∧ (x = a) ∨ x ∈ A``,
  SRW_TAC [][INSERT_def] THEN Cases_on `SET a` THEN
  SRW_TAC [][SET_IN_SINGC, PCLASS_SINGC_EMPTY]);
val _ = export_rewrites ["IN_INSERT"]

val SET_INSERT = store_thm(
  "SET_INSERT",
  ``SET (x INSERT b) = SET b``,
  SRW_TAC [][INSERT_def] THEN
  Cases_on `SET b` THEN1 SRW_TAC [][UNION_SET_CLOSED] THEN
  SRW_TAC [][] THEN
  Q_TAC SUFF_TAC `b ⊆ SINGC x ∪ b` THEN1 METIS_TAC [SUBSETS_ARE_SETS] THEN
  SRW_TAC [][SUBSET_def]);
val _ = export_rewrites ["SET_INSERT"]

val INSERT_IDEM = store_thm(
  "INSERT_IDEM",
  ``a INSERT a INSERT s = a INSERT s``,
  SRW_TAC [][Once EXTENSION] THEN METIS_TAC []);
val _ = export_rewrites ["INSERT_IDEM"]

val SUBSET_SING = store_thm(
  "SUBSET_SING",
  ``x ⊆ {a} ⇔ SET a ∧ (x = {a}) ∨ (x = {})``,
  SRW_TAC [][SUBSET_def] THEN EQ_TAC THENL [
    Cases_on `SET a` THEN SRW_TAC [][] THENL [
      Cases_on `x = {}` THEN SRW_TAC [][] THEN
      SRW_TAC [][Once EXTENSION] THEN
      `∃b. b ∈ x` by METIS_TAC [EMPTY_UNIQUE] THEN
      METIS_TAC [],
      METIS_TAC [EMPTY_UNIQUE]
    ],
    SIMP_TAC (srw_ss()) [DISJ_IMP_THM]
  ]);
val _ = export_rewrites ["SUBSET_SING"]

val BIGUNION_EMPTY = store_thm(
  "BIGUNION_EMPTY",
  ``(BIGUNION {} = {}) ∧ (BIGUNION {{}} = {})``,
  CONJ_TAC THEN SRW_TAC [][Once EXTENSION]);
val _ = export_rewrites ["BIGUNION_EMPTY"]

val BIGUNION_SING = store_thm(
  "BIGUNION_SING",
  ``SET a ⇒ (BIGUNION {a} = a)``,
  SRW_TAC [][Once EXTENSION]);

val BIGUNION_UNION = store_thm(
  "BIGUNION_UNION",
  ``SET a ∧ SET b ⇒ (BIGUNION {a;b} = a ∪ b)``,
  SRW_TAC [boolSimps.DNF_ss][Once EXTENSION]);

val POW_EMPTY = store_thm(
  "POW_EMPTY",
  ``POW {} = {{}}``,
  SRW_TAC [][Once EXTENSION] THEN SRW_TAC [boolSimps.CONJ_ss][]);

val POW_SING = store_thm(
  "POW_SING",
  ``SET a ⇒ (POW {a} = {{}; {a}})``,
  SRW_TAC [][Once EXTENSION] THEN
  ASM_SIMP_TAC (srw_ss() ++ boolSimps.CONJ_ss ++ boolSimps.DNF_ss) [] THEN
  METIS_TAC []);

(* "primitive ordered pair" *)
val POPAIR_def = Define`POPAIR a b = {{a}; {a;b}}`

val POPAIR_SET = store_thm(
  "POPAIR_SET",
  ``SET (POPAIR a b)``,
  SRW_TAC [][POPAIR_def]);
val _ = export_rewrites ["POPAIR_SET"]

val SING_11 = store_thm(
  "SING_11",
  ``SET a ∧ SET b ⇒ (({a} = {b}) = (a = b))``,
  STRIP_TAC THEN ASM_SIMP_TAC (srw_ss()) [SimpLHS, Once EXTENSION] THEN
  SRW_TAC [][] THEN METIS_TAC []);

val SING_EQ_PAIR = store_thm(
  "SING_EQ_PAIR",
  ``SET a ∧ SET b ∧ SET c ⇒ (({a;b} = {c}) = (a = b) ∧ (b = c))``,
  STRIP_TAC THEN ASM_SIMP_TAC (srw_ss()) [SimpLHS, Once EXTENSION] THEN
  SRW_TAC [][] THEN METIS_TAC []);

val PAIR_EQ_PAIR = store_thm(
  "PAIR_EQ_PAIR",
  ``SET a ∧ SET b ∧ SET c ∧ SET d ⇒
    (({a;b} = {c;d}) ⇔ (a = c) ∧ (b = d) ∨ (a = d) ∧ (b = c))``,
  STRIP_TAC THEN ASM_SIMP_TAC (srw_ss()) [Once EXTENSION, SimpLHS] THEN
  SRW_TAC [][] THEN METIS_TAC []);

val POPAIR_INJ = store_thm(
  "POPAIR_INJ",
  ``SET a ∧ SET b ∧ SET c ∧ SET d ⇒
    ((POPAIR a b = POPAIR c d) ⇔ (a = c) ∧ (b = d))``,
  STRIP_TAC THEN SRW_TAC [][SimpLHS, Once EXTENSION] THEN
  SRW_TAC [][POPAIR_def] THEN REVERSE EQ_TAC THEN1 SRW_TAC [][] THEN
  METIS_TAC [SING_11, SING_EQ_PAIR, PAIR_EQ_PAIR]);

(* ordered pairs that work when classes are involved *)
val OPAIR_def = Define`
  OPAIR a b = SPEC0 (λx. ∃y. y ∈ a ∧ (x = POPAIR {} y)) ∪
              SPEC0 (λx. ∃y. y ∈ b ∧ (x = POPAIR {{}} y))
`;

val SET_OPAIR = store_thm(
  "SET_OPAIR",
  ``SET a ∧ SET b ⇒ SET (OPAIR a b)``,
  SRW_TAC [][OPAIR_def] THEN MATCH_MP_TAC UNION_SET_CLOSED THEN CONJ_TAC THENL[
    SRW_TAC [][POPAIR_def] THEN MATCH_MP_TAC SUBSETS_ARE_SETS THEN
    SRW_TAC [boolSimps.DNF_ss][SUBSET_def, SPEC0] THEN
    Q.EXISTS_TAC `POW (POW (a ∪ {{}}))` THEN
    SRW_TAC [][POW_SET_CLOSED, UNION_SET_CLOSED] THEN
    ASM_SIMP_TAC (srw_ss() ++ boolSimps.DNF_ss) [SUBSET_def],
    SRW_TAC [][POPAIR_def] THEN MATCH_MP_TAC SUBSETS_ARE_SETS THEN
    SRW_TAC [boolSimps.DNF_ss][SUBSET_def, SPEC0] THEN
    Q.EXISTS_TAC `POW (POW (b ∪ {{{}}}))` THEN
    SRW_TAC [][POW_SET_CLOSED, UNION_SET_CLOSED] THEN
    ASM_SIMP_TAC (srw_ss() ++ boolSimps.DNF_ss) [SUBSET_def]
  ]);

val ZERO_NEQ_ONE = store_thm(
  "ZERO_NEQ_ONE",
  ``{} ≠ {{}}``,
  SRW_TAC [][EXTENSION] THEN Q.EXISTS_TAC `{}` THEN SRW_TAC [][]);
val _ = export_rewrites ["ZERO_NEQ_ONE"]

val POPAIR_01 = store_thm(
  "POPAIR_01",
  ``POPAIR {} x ≠ POPAIR {{}} y``,
  SRW_TAC [][POPAIR_def] THEN SRW_TAC [][Once EXTENSION] THEN
  Q.EXISTS_TAC `{{}}` THEN SRW_TAC [][SING_11] THEN
  SRW_TAC [][Once EXTENSION] THEN Q.EXISTS_TAC `{{}}` THEN
  SRW_TAC [][]);

val OPAIR_11 = store_thm(
  "OPAIR_11",
  ``((OPAIR a b = OPAIR c d) ⇔ (a = c) ∧ (b = d))``,
  SRW_TAC [][Once EXTENSION, SimpLHS] THEN
  SRW_TAC [][OPAIR_def, SPEC0] THEN
  REVERSE EQ_TAC THEN1 SRW_TAC [][] THEN
  REPEAT STRIP_TAC THENL [
    SIMP_TAC (srw_ss()) [EXTENSION, EQ_IMP_THM] THEN
    Q.X_GEN_TAC `e` THEN REPEAT STRIP_TAC THEN
    `SET e` by METIS_TAC [SET_def] THEN
    FIRST_X_ASSUM (Q.SPEC_THEN `POPAIR {} e` MP_TAC) THEN
    ASM_SIMP_TAC (srw_ss()) [POPAIR_01] THENL [
      DISCH_THEN (MP_TAC o CONV_RULE LEFT_IMP_EXISTS_CONV o #1 o
                  EQ_IMP_RULE),
      DISCH_THEN (MP_TAC o CONV_RULE LEFT_IMP_EXISTS_CONV o #2 o
                  EQ_IMP_RULE)
    ] THEN
    DISCH_THEN (Q.SPEC_THEN `e` MP_TAC) THEN SRW_TAC [][] THEN
    POP_ASSUM MP_TAC THEN
    `SET y` by METIS_TAC [SET_def] THEN
    SRW_TAC [][POPAIR_INJ],

    SIMP_TAC (srw_ss()) [EXTENSION, EQ_IMP_THM] THEN
    Q.X_GEN_TAC `e` THEN REPEAT STRIP_TAC THEN
    `SET e` by METIS_TAC [SET_def] THEN
    FIRST_X_ASSUM (Q.SPEC_THEN `POPAIR {{}} e` MP_TAC) THEN
    ASM_SIMP_TAC (srw_ss()) [POPAIR_01] THENL [
      DISCH_THEN (MP_TAC o CONV_RULE LEFT_IMP_EXISTS_CONV o #1 o
                  EQ_IMP_RULE),
      DISCH_THEN (MP_TAC o CONV_RULE LEFT_IMP_EXISTS_CONV o #2 o
                  EQ_IMP_RULE)
    ] THEN
    DISCH_THEN (Q.SPEC_THEN `e` MP_TAC) THEN SRW_TAC [][] THEN
    POP_ASSUM MP_TAC THEN
    `SET y` by METIS_TAC [SET_def] THEN
    SRW_TAC [][POPAIR_INJ]
  ]);

val _ = add_rule { fixity = Closefix,
                   term_name = "OPAIR",
                   block_style = (AroundEachPhrase, (PP.CONSISTENT, 0)),
                   paren_style = OnlyIfNecessary,
                   pp_elements = [TOK "〈", TM, HardSpace 1,
                                  TOK "·", BreakSpace(1,2),
                                  TM, TOK "〉"]}

(*
val FORMATION = new_axiom(

*)

val _ = export_theory()