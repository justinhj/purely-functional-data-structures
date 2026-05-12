(* Work in progress *)
fun isEmpty [] = true
  | isEmpty _  = false;

fun curry f = fn x => fn y => f (x, y);


