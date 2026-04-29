import scala.math.Ordering.Implicits.*

enum Tree[+A]:
  case Empty
  case Node(value: A, left: Tree[A], right: Tree[A])

def insert[A : Ordering](x: A, t: Tree[A]): Tree[A] =
  t match
    case Tree.Empty => Tree.Node(x, Tree.Empty, Tree.Empty)
    case Tree.Node(y, left, right) =>
      if x < y then Tree.Node(y, insert(x, left), right)
      else if x > y then Tree.Node(y, left, insert(x, right))
      else t

/**
 * Basic version of member.
 * This performs 2 comparisons at each node (x < y and x > y).
 */
def member[A : Ordering](x: A, t: Tree[A]): Boolean =
  t match
    case Tree.Empty => false
    case Tree.Node(y, left, right) =>
      if x < y then member(x, left)
      else if x > y then member(x, right)
      else true

/**
 * This version will take d+1 max comparisons. It is exercise 2.2 from 
 * Purely Functional Data Structures
 */
def member2[A : Ordering](x: A, t: Tree[A], candidate: Option[A]): Boolean =
  t match
    case Tree.Empty if candidate.isEmpty => false
    case Tree.Empty => candidate.get == x 
    case Tree.Node(y, left, right) =>
      if x >= y then member2(x, right, Some(y))
      else member2(x, left, candidate)

@main def treeTest(): Unit =
  val nums = List(5, 3, 8, 1, 4, 6, 9)
  val tree = nums.foldLeft(Tree.Empty: Tree[Int])((t, x) => insert(x, t))

  println(s"Searching for 4 (exists): ${member2(4, tree, None)}")
  println(s"Searching for 7 (missing): ${member2(7, tree, None)}")
