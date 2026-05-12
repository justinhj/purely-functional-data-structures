(* Stack code *)
signature Stack =
sig
  type 'a Stack
  val empty : 'a Stack
  val isEmpty : 'a Stack -> bool
  val cons : 'a * 'a Stack -> 'a Stack
  val head : 'a Stack -> 'a
  val tail : 'a Stack -> 'a Stack
end

structure List: Stack =
struct
  type 'a Stack = 'a list
  val empty = []
  fun isEmpty s = null s
  fun cons (x, s) = x :: s
  fun head s = hd s
  fun tail s = tl s
end

structure CustomStack: Stack =
struct
  datatype 'a Stack = NIL | CONS of 'a * 'a Stack
  val empty = NIL
  fun isEmpty NIL = true | isEmpty _ = false
  fun cons (x, s) = CONS (x, s)
  fun head NIL = raise Empty
    | head (CONS (x, s)) = x
  fun tail NIL = raise Empty
    | tail (CONS (x, s)) = s
end
;

val s1 = CustomStack.cons (10, CustomStack.empty) ;
CustomStack.head s1;






