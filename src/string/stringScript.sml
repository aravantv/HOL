(* =====================================================================*)
(* FILE		: stringScript.sml				        *)
(* DESCRIPTION  : A theory of 8-bit characters and strings built        *)
(*                from them.                                            *)
(*                                                                      *)
(* AUTHOR	: Konrad Slind, University of Cambridge, 2001           *)
(* =====================================================================*)

(* interactive use:
  app load ["numLib", "listTheory", "listSyntax",
            "BasicProvers", "Q", "SingleStep", "metisLib"];
*)

open HolKernel boolLib Parse;
open numLib numSyntax BasicProvers SingleStep listTheory bossLib metisLib;

val export_rewrites = BasicProvers.export_rewrites "string";

(* ---------------------------------------------------------------------*)
(* Create the new theory						*)
(* ---------------------------------------------------------------------*)

val _ = new_theory "string";

(* ---------------------------------------------------------------------*)
(* Characters are represented by the natural numbers <= 255.            *)
(* ---------------------------------------------------------------------*)

val is_char =
 let val n = mk_var("n",num)
     val topnum = mk_numeral (Arbnum.fromInt 256)
 in mk_abs(n,mk_less(n,topnum))
 end;

val CHAR_EXISTS = Q.prove (`?n. ^is_char n`, Q.EXISTS_TAC `0` THEN REDUCE_TAC);

val CHAR_TYPE = new_type_definition("char", CHAR_EXISTS);

val CHAR_TYPE_FACTS =
    (define_new_type_bijections
       {ABS="CHR", REP="ORD",name="char_BIJ", tyax=CHAR_TYPE});

val ORD_11   = save_thm("ORD_11",prove_rep_fn_one_one CHAR_TYPE_FACTS)
val CHR_11   = save_thm("CHR_11",
                         BETA_RULE (prove_abs_fn_one_one CHAR_TYPE_FACTS));
val _ = export_rewrites ["CHR_11"]
val ORD_ONTO = save_thm("ORD_ONTO",
                         BETA_RULE (prove_rep_fn_onto CHAR_TYPE_FACTS));
val CHR_ONTO = save_thm("CHR_ONTO",
                         BETA_RULE (prove_abs_fn_onto CHAR_TYPE_FACTS));

val CHR_ORD  = save_thm("CHR_ORD", CONJUNCT1 CHAR_TYPE_FACTS);
val ORD_CHR  = save_thm("ORD_CHR",BETA_RULE (CONJUNCT2 CHAR_TYPE_FACTS));

val ORD_CHR_RWT = Q.store_thm
("ORD_CHR_RWT",
 `!r. r < 256 ==> (ORD (CHR r) = r)`,
 PROVE_TAC [ORD_CHR]);
val _ = export_rewrites ["ORD_CHR_RWT"]

val ORD_CHR_COMPUTE = Q.store_thm
("ORD_CHR_COMPUTE",
 `!r. ORD (CHR r) = if r < 256 then r else ORD (CHR r)`,
 PROVE_TAC [ORD_CHR_RWT]);

val ORD_BOUND = Q.store_thm
("ORD_BOUND",
 `!c. ORD c < 256`,
 PROVE_TAC [ORD_ONTO]);

val char_nchotomy = Q.store_thm("char_nchotomy",
  `!c. ?n. c = CHR n`,
  STRIP_TAC THEN Q.EXISTS_TAC `ORD c` THEN REWRITE_TAC [CHR_ORD]);

val ranged_char_nchotomy = Q.store_thm("ranged_char_nchotomy",
  `!c. ?n. (c = CHR n) /\ n < 256`,
  STRIP_TAC THEN Q.EXISTS_TAC `ORD c` THEN REWRITE_TAC [CHR_ORD, ORD_BOUND]);

val ordn = term_of_int o Char.ord;

val isLower_def = Define`
  isLower c = ^(ordn #"a") <= ORD c /\ ORD c <= ^(ordn #"z")`;

val isUpper_def = Define`
  isUpper c = ^(ordn #"A") <= ORD c /\ ORD c <= ^(ordn #"Z")`;

val isDigit_def = Define`
  isDigit c = ^(ordn #"0") <= ORD c /\ ORD c <= ^(ordn #"9")`;

val isAlpha_def = Define `isAlpha c = isLower c \/ isUpper c`;

val isHexDigit_def = Define`
  isHexDigit c = ^(ordn #"0") <= ORD c /\ ORD c <= ^(ordn #"9") \/
                 ^(ordn #"a") <= ORD c /\ ORD c <= ^(ordn #"f") \/
                 ^(ordn #"A") <= ORD c /\ ORD c <= ^(ordn #"F")`;

val isAlphaNum_def = Define `isAlphaNum c = isAlpha c \/ isDigit c`;

val isPrint_def = Define`
  isPrint c = ^(ordn #" ") <= ORD c /\ ORD c < 127`;

val isSpace_def = Define`
  isSpace c = (ORD c = ^(ordn #" ")) \/ 9 <= ORD c /\ ORD c <= 13`;

val isGraph_def = Define `isGraph c = isPrint c /\ ~isSpace c`;

val isPunct_def = Define `isPunct c = isGraph c /\ ~isAlphaNum c`;

val isAscii_def = Define `isAscii c = ORD c <= 127`;

val isCntrl_def = Define`
  isCntrl c = ORD c < ^(ordn #" ") \/ 127 <= ORD c`;

val toLower_def = Define`
  toLower c = if isUpper c then CHR (ORD c + 32) else c`;

val toUpper_def = Define`
  toUpper c = if isLower c then CHR (ORD c - 32) else c`;

val char_lt_def = Define `char_lt a b = ORD a < ORD b`;
val char_le_def = Define `char_le a b = ORD a <= ORD b`;
val char_gt_def = Define `char_gt a b = ORD a > ORD b`;
val char_ge_def = Define `char_ge a b = ORD a >= ORD b`;

val _ = overload_on ("<", Term`char_lt`);
val _ = overload_on (">", Term`char_gt`);
val _ = overload_on ("<=", Term`char_le`);
val _ = overload_on (">=", Term`char_ge`);

val _ = send_to_back_overload "<" {Name = "char_lt", Thy = "string"};
val _ = send_to_back_overload ">" {Name = "char_gt", Thy = "string"};
val _ = send_to_back_overload "<=" {Name = "char_le", Thy = "string"};
val _ = send_to_back_overload ">=" {Name = "char_ge", Thy = "string"};

(*---------------------------------------------------------------------------
    In our development, CHR is not a constructor. Is that really
    important? We can at least prove the following theorem about
    equality of chars.
 ---------------------------------------------------------------------------*)

val CHAR_EQ_THM = Q.store_thm
("CHAR_EQ_THM",
 `!c1 c2. (c1 = c2) = (ORD c1 = ORD c2)`,
 REPEAT GEN_TAC
   THEN EQ_TAC
   THEN RW_TAC bool_ss [ORD_11]);


val CHAR_INDUCT_THM = Q.store_thm
("CHAR_INDUCT_THM",
 `!P. (!n. n < 256 ==> P (CHR n)) ==> !c. P c`,
REPEAT STRIP_TAC
  THEN STRIP_ASSUME_TAC (Q.SPEC `c` CHR_ONTO)
  THEN RW_TAC bool_ss []);

(*---------------------------------------------------------------------------
      Strings are represented as lists of characters. This gives us
      EXPLODE and IMPLODE as the functions mapping into, and from, the
      representation.
 ---------------------------------------------------------------------------*)

val _ = Hol_datatype`string = EMPTYSTRING | STRING of char => string`

val GET_def = Define`
  (GET (STRING x s) 0 = x) /\
  (GET (STRING x s) (SUC n) = GET s n)`;

val _ = set_fixity "'" (Infixl 2000);
val _ = overload_on ("'", Term`$GET`);
val _ = send_to_back_overload "'" {Name = "GET", Thy = "string"};

val IMPLODE_def = Define`
  (IMPLODE [] = "") /\
  (IMPLODE (c::cs) = STRING c (IMPLODE cs))
`;
val _ = export_rewrites ["IMPLODE_def"]

val EXPLODE_def = Define`
  (EXPLODE "" = []) /\
  (EXPLODE (STRING c s) = c :: EXPLODE s)
`;
val _ = export_rewrites ["EXPLODE_def"]

val TRANSFORM_def = Define `TRANSFORM f = IMPLODE o f o EXPLODE`;

val IMPLODE_EXPLODE = store_thm(
  "IMPLODE_EXPLODE",
  ``IMPLODE (EXPLODE s) = s``,
  Induct_on `s` THEN SRW_TAC [][]);

val EXPLODE_IMPLODE = store_thm(
  "EXPLODE_IMPLODE",
  ``EXPLODE (IMPLODE cs) = cs``,
  Induct_on `cs` THEN SRW_TAC [][]);

fun stac(n,t) = store_thm(n,t,METIS_TAC [EXPLODE_IMPLODE, IMPLODE_EXPLODE])
val EXPLODE_ONTO = stac("EXPLODE_ONTO", ``!cs. ?s. cs = EXPLODE s``);
val IMPLODE_ONTO = stac("IMPLODE_ONTO", ``!s. ?cs. s = IMPLODE cs``);
val EXPLODE_11 = stac("EXPLODE_11", ``(EXPLODE s1 = EXPLODE s2) = (s1 = s2)``)
val IMPLODE_11 = stac("IMPLODE_11", ``(IMPLODE cs1 = IMPLODE cs2) = (cs1 = cs2)``)

val _ = export_rewrites ["EXPLODE_11", "IMPLODE_11", "IMPLODE_EXPLODE",
                         "EXPLODE_IMPLODE"]

(*---------------------------------------------------------------------------
    Definability of prim. rec. functions over strings.
 ---------------------------------------------------------------------------*)

val alt_string_Axiom = Q.prove
(`!b g. ?f.  (f (IMPLODE []) = b) /\
       (!c t. f (IMPLODE (c::t)) = g c t (f (IMPLODE t)))`,
REPEAT GEN_TAC
  THEN STRIP_ASSUME_TAC
     (prove_rec_fn_exists listTheory.list_Axiom
        ``(list_rec (b:'a) f ([]:char list) = b) /\
          (list_rec b f (h::t) = f h t (list_rec b f t))``)
   THEN Q.EXISTS_TAC`list_rec b g o EXPLODE`
   THEN RW_TAC bool_ss [combinTheory.o_DEF,list_case_def,EXPLODE_IMPLODE]);

(*---------------------------------------------------------------------------
     Induction for strings.
 ---------------------------------------------------------------------------*)

val STRING_ACYCLIC = Q.store_thm
("STRING_ACYCLIC",
 `!s c. ~(STRING c s = s) /\ ~(s = STRING c s)`,
 Induct THEN SRW_TAC [][]);

(*---------------------------------------------------------------------------
      Size of a string.
 ---------------------------------------------------------------------------*)

val STRLEN_def = Define`
  (STRLEN "" = 0) /\
  (STRLEN (STRING c s) = 1 + STRLEN s)
`;
val _ = export_rewrites ["STRLEN_def"]
val STRLEN_DEF = save_thm("STRLEN_DEF", STRLEN_def);

val STRLEN_EQ_0 = Q.store_thm
("STRLEN_EQ_0",
 `!x. (STRLEN x = 0) = (x="")`,
 Cases THEN SRW_TAC [][STRLEN_DEF]);

val _ = export_rewrites ["STRLEN_EQ_0"]

val GET = Q.store_thm
("GET",
  `!n s. n < STRLEN s ==> (GET s n = EL n (EXPLODE s))`,
  Induct THEN Cases THEN SRW_TAC [ARITH_ss] [GET_def]);

(*---------------------------------------------------------------------------*)
(* Destruct a string. This will be used to re-phrase the HOL development     *)
(* with an ML definition of DEST_STRING in terms of the Basis String struct. *)
(*---------------------------------------------------------------------------*)

val DEST_STRING_def = Define`
   (DEST_STRING "" = NONE) /\
   (DEST_STRING (STRING c rst) = SOME(c,rst))
`;
val _ = export_rewrites ["DEST_STRING_def"]

val DEST_STRING_LEMS = Q.store_thm
("DEST_STRING_LEMS",
 `!s. ((DEST_STRING s = NONE) = (s = "")) /\
      ((DEST_STRING s = SOME(c,t)) = (s = STRING c t))`,
 Cases THEN SRW_TAC [][]);

val EXPLODE_EQNS = save_thm("EXPLODE_EQNS", EXPLODE_def)
val IMPLODE_EQNS = save_thm("IMPLODE_EQNS", IMPLODE_def)

(* ----------------------------------------------------------------------
    More rewrites for IMPLODE and EXPLODE
   ---------------------------------------------------------------------- *)

val IMPLODE_EQ_EMPTYSTRING = Q.store_thm(
  "IMPLODE_EQ_EMPTYSTRING",
  `((IMPLODE l = "") = (l = [])) /\
   (("" = IMPLODE l) = (l = []))`,
  Cases_on `l` THEN SRW_TAC [][]);
val _ = export_rewrites ["IMPLODE_EQ_EMPTYSTRING"]

val EXPLODE_EQ_NIL = Q.store_thm(
  "EXPLODE_EQ_NIL",
  `((EXPLODE s = []) = (s = "")) /\
   (([] = EXPLODE s) = (s = ""))`,
  Cases_on `s` THEN SRW_TAC [][]);
val _ = export_rewrites ["EXPLODE_EQ_NIL"]

val EXPLODE_EQ_THM = Q.store_thm
("EXPLODE_EQ_THM",
 `!s h t. ((h::t = EXPLODE s) = (s = STRING h (IMPLODE t))) /\
          ((EXPLODE s = h::t) = (s = STRING h (IMPLODE t)))`,
  Cases THEN SRW_TAC [][EQ_IMP_THM] THEN SRW_TAC [][]);

val IMPLODE_EQ_THM = Q.store_thm
("IMPLODE_EQ_THM",
 `!c s l. ((STRING c s = IMPLODE l) = (l = c::EXPLODE s)) /\
          ((IMPLODE l = STRING c s) = (l = c::EXPLODE s))`,
 Cases_on `l` THEN SRW_TAC [][EQ_IMP_THM] THEN SRW_TAC [][]);

(*---------------------------------------------------------------------------*)
(* ML-style recursion equations for EXPLODE and IMPLODE                      *)
(*---------------------------------------------------------------------------*)

val EXPLODE_DEST_STRING = Q.store_thm
("EXPLODE_DEST_STRING",
 `!s. EXPLODE s = case DEST_STRING s
                   of NONE -> []
                   || SOME(c,t) -> c::EXPLODE t`,
 Cases THEN SRW_TAC [][])

val IMPLODE_STRING = Q.store_thm
("IMPLODE_STRING",
 `!clist.IMPLODE clist = FOLDR STRING "" clist`,
 Induct THEN SRW_TAC [][]);

(*---------------------------------------------------------------------------*)
(* Main fact about STRLEN                                                    *)
(*---------------------------------------------------------------------------*)

val STRLEN_THM = Q.store_thm
("STRLEN_THM",
 `!s. STRLEN s = LENGTH (EXPLODE s)`,
 Induct THEN SRW_TAC [ARITH_ss][]);

val STRLEN_EQ_0 = Q.store_thm
("STRLEN_EQ_0",
 `!x. (STRLEN x = 0) = (x="")`,
 Cases THEN SRW_TAC [][]);

(*---------------------------------------------------------------------------
                      String concatenation
 ---------------------------------------------------------------------------*)

val STRCAT_def = Define`
  (STRCAT "" s = s) /\
  (STRCAT (STRING c s1) s2 = STRING c (STRCAT s1 s2))
`

val STRCAT = store_thm(
  "STRCAT",
  ``STRCAT s1 s2 = IMPLODE(APPEND (EXPLODE s1) (EXPLODE s2))``,
  Induct_on `s1` THEN SRW_TAC [][STRCAT_def]);

val STRCAT_EQNS = Q.store_thm
("STRCAT_EQNS",
 `(STRCAT "" s = s) /\
  (STRCAT s "" = s) /\
  (STRCAT (STRING c s1) s2 = STRING c (STRCAT s1 s2))`,
 SRW_TAC [][STRCAT]);
val _ = export_rewrites ["STRCAT_EQNS"]

val STRCAT_ASSOC = Q.store_thm
("STRCAT_ASSOC",
 `!s1 s2 s3. STRCAT s1 (STRCAT s2 s3) = STRCAT (STRCAT s1 s2) s3`,
 SRW_TAC [] [STRCAT])

val STRCAT_11 = Q.store_thm
("STRCAT_11",
 `!s1 s2 s3. ((STRCAT s1 s2 = STRCAT s1 s3) = (s2=s3)) /\
             ((STRCAT s1 s3 = STRCAT s2 s3) = (s1=s2))`,
 SRW_TAC [][STRCAT]);
val _ = export_rewrites ["STRCAT_11"]

val STRCAT_ACYCLIC = Q.store_thm
("STRCAT_ACYCLIC",
 `!s s1. ((s = STRCAT s s1) = (s1 = "")) /\
         ((s = STRCAT s1 s) = (s1 = ""))`,
 PROVE_TAC [STRCAT_EQNS,STRCAT_11]);

val STRCAT_EXPLODE = Q.store_thm
("STRCAT_EXPLODE",
 `!s1 s2. STRCAT s1 s2 = FOLDR STRING s2 (EXPLODE s1)`,
  Induct THEN SRW_TAC [][])

val STRCAT_EQ_EMPTY = Q.store_thm
("STRCAT_EQ_EMPTY",
 `!x y. (STRCAT x y = "") = (x="") /\ (y="")`,
 SRW_TAC [][STRCAT]);
val _ = export_rewrites ["STRCAT_EQ_EMPTY"]
(*---------------------------------------------------------------------------
     String length and concatenation
 ---------------------------------------------------------------------------*)

val STRLEN_CAT = Q.store_thm
("STRLEN_CAT",
 `!x y. STRLEN (STRCAT x y) = (STRLEN x + STRLEN y)`,
 SRW_TAC [][STRCAT,STRLEN_THM]);

(*---------------------------------------------------------------------------
       Is one string a prefix of another?
 ---------------------------------------------------------------------------*)

val isPREFIX_def = Define`
  (isPREFIX "" s = T) /\
  (isPREFIX (STRING c1 s1) "" = F) /\
  (isPREFIX (STRING c1 s1) (STRING c2 s2) = (c1 = c2) /\ isPREFIX s1 s2)
`;
val _ = export_rewrites ["isPREFIX_def"]

val isPREFIX_DEF = store_thm(
  "isPREFIX_DEF",
  ``!s1 s2.
       isPREFIX s1 s2 =
       case (DEST_STRING s1, DEST_STRING s2)
        of (NONE, _) -> T
        || (SOME __, NONE) -> F
        || (SOME(c1,t1),SOME(c2,t2)) -> (c1=c2) /\ isPREFIX t1 t2``,
  HO_MATCH_MP_TAC (theorem "isPREFIX_ind") THEN SRW_TAC [][]);

val isPREFIX_IND = Q.store_thm
("isPREFIX_IND",
 `!P. (!s1 s2.
         (!c t1 t2.
           (DEST_STRING s1 = SOME (c,t1)) /\
           (DEST_STRING s2 = SOME (c,t2)) ==> P t1 t2) ==> P s1 s2)
       ==> !v v1. P v v1`,
 GEN_TAC THEN STRIP_TAC THEN Induct THEN SRW_TAC [][]);

val isPREFIX_STRCAT = Q.store_thm
("isPREFIX_STRCAT",
 `!s1 s2. isPREFIX s1 s2 = ?s3. s2 = STRCAT s1 s3`,
 recInduct (theorem "isPREFIX_ind") THEN SRW_TAC [][] THEN PROVE_TAC []);

(*---------------------------------------------------------------------------
    Exportation
 ---------------------------------------------------------------------------*)

val _ = ConstMapML.insert(prim_mk_const{Name="DEST_STRING",Thy="string"});
val _ = ConstMapML.insert(prim_mk_const{Name="STRING",Thy="string"});
val _ = ConstMapML.prim_insert(prim_mk_const{Name="EMPTYSTRING",Thy="string"},
                               (false,"","\"\"",Parse.Type`:string`));

fun adjoin_to_theory_struct l = adjoin_to_theory {sig_ps = NONE,
  struct_ps = SOME (fn ppstrm =>
    app (fn s => (PP.add_string ppstrm s; PP.add_newline ppstrm)) l)};

val _ = adjoin_to_theory_struct [
  "val _ =",
  "let open Lib boolSyntax numSyntax",
  "    val char_type = type_of (fst(dest_forall(concl char_nchotomy)))",
  "    val ORD_tm = fst(strip_comb(lhs(lhs(snd(strip_forall(concl ORD_11))))))",
  "    val ORD_abs = list_mk_abs([mk_var(\"v1\",bool-->num),",
  "                               mk_var(\"v2\",alpha-->num),",
  "                               mk_var(\"v3\",char_type)],",
  "                               mk_comb(ORD_tm,mk_var(\"v3\",char_type)))",
  "in",
  " TypeBase.write",
  " [TypeBasePure.mk_nondatatype_info",
  "  (char_type, ",
  "    {nchotomy = SOME ranged_char_nchotomy,",
  "     size = SOME(ORD_abs,CONJUNCT1(Drule.SPEC_ALL boolTheory.AND_CLAUSES)),",
  "     encode = NONE})]",
  "end;",
  "",
  "val _ = app (fn n => ConstMapML.insert\
  \ (prim_mk_const{Name=n,Thy=\"string\"}))",
  "      [\"CHR\",\"ORD\",\"DEST_STRING\",\"STRING\"]",
  "val _ = ConstMapML.prim_insert(prim_mk_const{Name=\"EMPTYSTRING\",",
  "          Thy=\"string\"},(false,\"\",\"\\\"\\\"\",mk_type(\"string\",[])));"
  ];

val _ =
 let open EmitML
 in emitML (!Globals.emitMLDir)
   ("string",
    OPEN ["num", "list", "option"]
    :: MLSIG "type num = numML.num"
    :: MLSIG "type char = Char.char"
    :: MLSIG "type string = String.string"
    :: MLSIG "val CHR : num -> char"
    :: MLSIG "val ORD : char -> num"
    :: MLSTRUCT "type char = Char.char;"
    :: MLSTRUCT "type string = String.string;"
    :: MLSTRUCT "fun CHR n = Char.chr(valOf(Int.fromString(numML.toDecString n)));"
    :: MLSTRUCT "fun ORD c = numML.fromDecString(Int.toString(Char.ord c));"
    :: MLSTRUCT "fun STRING c s = String.^(Char.toString c,s);"
    :: MLSTRUCT "fun DEST_STRING s = if s = \"\" then NONE \n\
        \          else SOME(String.sub(s,0),String.extract(s,1,NONE));"
    :: map (DEFN o PURE_REWRITE_RULE [arithmeticTheory.NUMERAL_DEF])
       [EXPLODE_DEST_STRING, IMPLODE_STRING, STRLEN_THM, STRCAT_EXPLODE, isPREFIX_DEF])
 end;

val _ = export_theory();

val _ = let
  val ^^ = Path.concat
  infix ^^
in
  export_theory_as_docfiles ("help" ^^ "thms")
end;
