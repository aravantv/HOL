(* This file has been generated by java2opSem from /home/helen/Recherche/hol/HOL/examples/opsemTools/java2opsem/testFiles/javaFiles/Search.java*)


open HolKernel Parse boolLib
stringLib IndDefLib IndDefRules
finite_mapTheory relationTheory
newOpsemTheory
computeLib bossLib;

val _ = new_theory "Search";

(* Method search*)
val MAIN_def =
  Define `MAIN =
    RSPEC
    (\state.
      (ScalarOf (state ' "aLength")=10))
      (Seq
        (Assign "result"
          (Const ~1)
        )
        (Seq
          (Assign "left"
            (Const 0)
          )
          (Seq
            (While
              (And
                (Equal
                  (Var "result")
                  (Const ~1)
                )
                (Less
                  (Var "left")
                  (Var "aLength")
                )
              )
              (Cond
                (Equal
                  (Arr "a"
                    (Var "left")
                  )
                  (Var "x")
                )
                (Assign "result"
                  (Var "left")
                )
                (Assign "left"
                  (Plus
                    (Var "left")
                    (Const 1)
                  )
                )
              )
            )
            (Assign "Result"
              (Var "result")
            )
          )
        )
      )
    (\state1 state2.
      ((((ScalarOf (state2 ' "Result")=~1))) ==> ((!i . (((i>=0)/\(i<Num(ScalarOf (state1 ' "aLength")))))==>(~((ArrayOf (state2 ' "a") ' (i))=ScalarOf (state1 ' "x"))))))/\(((~(ScalarOf (state2 ' "Result")=~1))) ==> ((((ArrayOf (state2 ' "a") ' (Num(ScalarOf (state2 ' "Result"))))=ScalarOf (state1 ' "x"))))))
    `

    val intVar_def =
  	     Define `intVar =["x";"result";"left";"Result"]  `

    val arrVar_def =
  	     Define `arrVar =["a"]  `

  val _ = export_theory();
