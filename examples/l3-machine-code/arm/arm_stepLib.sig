signature arm_stepLib =
sig
   val BIT_THMS_CONV: Conv.conv
   val arm_instruction: Term.term list -> string list
   val arm_step: string -> string -> Thm.thm list
   val arm_step_hex: string -> string -> Thm.thm list
   val decode_arm: Term.term list -> bool list * Term.term -> Thm.thm list
   val decode_arm_hex: Term.term list -> string -> Thm.thm list
   val hex_to_bits_32: string -> Term.term list
   val list_instructions: unit -> string list
   val print_instructions: unit -> unit

   (*

     open arm_stepLib
     val () = print_instructions ()
     val ev = arm_step "v7"
     fun pev s = (print (s ^ "\n"); Count.apply ev s);
     val _ = Count.apply (List.map ev) (list_instructions ())
     val _ = Count.apply (List.map (Lib.total pev)) (list_instructions ())
     ev "LDR (+reg,pre)"

   *)
end
