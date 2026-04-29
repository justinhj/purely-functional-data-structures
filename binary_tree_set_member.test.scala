//> using test.dep org.scalameta::munit::1.0.0

class BinaryTreeSetTest extends munit.FunSuite {

  def check(x: Int, t: Tree[Int], expected: Boolean)(using munit.Location): Unit = {
    assertEquals(member(x, t), expected, s"member($x) failed")
    assertEquals(member2(x, t, None), expected, s"member2($x) failed")
  }

  test("empty set") {
    check(5, Tree.Empty, false)
  }

  test("set with 1 element") {
    val tree = insert(10, Tree.Empty)
    check(10, tree, true)
    check(5, tree, false)
    check(15, tree, false)
  }

  test("set with 10 elements") {
    val nums = List(50, 25, 75, 10, 30, 60, 90, 5, 15, 20)
    val tree = nums.foldLeft(Tree.Empty: Tree[Int])((t, x) => insert(x, t))

    // Test elements that exist
    nums.foreach { n =>
      check(n, tree, true)
    }

    // Test elements that do not exist
    val missing = List(0, 100, 55, 33, 7)
    missing.foreach { n =>
      check(n, tree, false)
    }
  }

  test("member and member2 consistency") {
    // Generate a slightly larger random-ish tree
    val nums = (1 to 100 by 7).toList
    val tree = nums.foldLeft(Tree.Empty: Tree[Int])((t, x) => insert(x, t))

    for (i <- 0 to 110) {
      assertEquals(member(i, tree), member2(i, tree, None), s"Inconsistency at $i")
    }
  }
}
