(* ========================================================================= *)
(* MATCHING AND UNIFICATION FOR SETS OF LITERALS                             *)
(* Created by Joe Hurd, June 2002                                            *)
(* ========================================================================= *)

signature mlibLiteralnet =
sig

type 'a pp          = 'a mlibUseful.pp
type ('a,'b) maplet = ('a,'b) mlibUseful.maplet
type formula        = mlibTerm.formula

type 'a literalnet

(* Basic operations *)
val empty        : unit -> 'a literalnet
val size         : 'a literalnet -> int
val size_profile : 'a literalnet -> {t : int, f : int, p : int, n : int}
val insert       : (formula,'a) maplet -> 'a literalnet -> 'a literalnet
val from_maplets : (formula,'a) maplet list -> 'a literalnet
val filter       : ('a -> bool) -> 'a literalnet -> 'a literalnet

(* mlibMatching and unifying *)
val match   : 'a literalnet -> formula -> 'a list
val matched : 'a literalnet -> formula -> 'a list
val unify   : 'a literalnet -> formula -> 'a list

(* Pretty-printing *)
val to_maplets    : 'a literalnet -> (formula,'a) maplet list
val pp_literalnet : 'a pp -> 'a literalnet pp

end
