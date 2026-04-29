# Purely Functional Data Structures in Scala 3

This project contains implementations of data structures and exercises from Chris Okasaki's book, *Purely Functional Data Structures*, using Scala 3 and `scala-cli`.

## Catalog

### 1. Persistent Lists
- **File:** `lists.scala`
- **Implementation:** Includes a `suffixes` extension method for `List[A]` which returns all suffixes of a list in $O(n)$ time and space, demonstrating structural sharing.

### 2. Binary Search Tree (Set)
- **File:** `binary_tree_set_member.scala`
- **Implementation:** A functional BST implementation with:
  - `insert`: Standard functional insertion.
  - `member`: Basic membership test (2 comparisons per node).
  - `member2`: Optimized membership test (1 comparison per node, Exercise 2.2).

## Usage

This project uses [scala-cli](https://scala-cli.virtuslab.org/).

### Running Tests
To run the MUnit test suite:
```bash
scala-cli test .
```

### Running Applications
To run the individual demonstration programs:
```bash
# Run the Binary Tree demo
scala-cli run binary_tree_set_member.scala

# Run the Suffixes demo
scala-cli run lists.scala
```

### Development Mode
To run tests automatically on file changes:
```bash
scala-cli test . --watch
```
