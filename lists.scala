// Exercise from Purely Function Data Structures
// Write suffixes to give all the suffixes and a list given the list

val demo = List(1,2,3)

def suffixes_helper[A](in: List[A], out: List[List[A]]): List[List[A]] = in match 
  case (hd :: tl) =>
    suffixes_helper(tl, in +: out)
  case Nil => 
    (Nil +: out).reverse

extension [A](xs: List[A])
  def suffixes: List[List[A]] = suffixes_helper(xs, Nil)

@main def lists(): Unit =
  println(s"Suffixes of $demo")
  demo.suffixes.foreach(s => println(s"Suffix of $s"))
