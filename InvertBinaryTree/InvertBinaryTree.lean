-- This module serves as the root of the `InvertBinaryTree` library.
-- Import modules here that should be built as part of the library.
import InvertBinaryTree.Basic


/-- Makes a complete tree where the leaves are `range (2 ^ d)` --/
def makeTreeOfIndices (d: Nat) : Tree d :=
  let rec makeTreeAux (d: Nat) (offset: Nat) : Tree d :=
    match d with
    | 0 => .leaf offset
    | d + 1 => .branch (makeTreeAux d offset) (makeTreeAux d (offset + 2^d))
  makeTreeAux d 0

-- TODO: Simplify
def Tree.fromArray (a: Array Nat) (depth: Nat)
  (h_a_is_not_empty: a.size > 0)
  (h_depth_eq_log2_size: depth = Nat.log2 a.size)
  : Tree depth :=
  let rec makeTreeAux (d: Nat)
                      (offset: Nat)
                      (len: Nat)
                      (h_length: len = 2^d)
                      (h_bound: offset + len <= a.size): Tree d :=

    have offset_lt_size : offset < a.size := by
      have len_pos : len > 0 := by
        rw [h_length]
        exact Nat.pow_pos (by decide)
      have h_offset : offset + 1 ≤ offset + len := by
        exact Nat.add_le_add_left (Nat.succ_le_of_lt len_pos) offset
      exact Nat.lt_of_succ_le (Nat.le_trans h_offset h_bound)

    let offset' := Fin.mk offset offset_lt_size
    match d with
    | 0 => .leaf a[offset']
    | d' + 1 =>
      let len' := 2^d'
      let h2 : len' = 2^d' := by
        simp_arith
      have h_half: len' * 2 = len := by
          rw [h_length]
          simp [len', Nat.pow_succ]
      let h_left_bound : offset + len' <= a.size := by
        have : len' ≤ len := by
          rw [← h_half]
          exact Nat.le_mul_of_pos_right len' (by decide)
        exact Nat.le_trans (Nat.add_le_add_left this offset) h_bound
      let h_right_bound : (offset + len') + len' <= a.size := by
        rw [Nat.add_assoc, ← Nat.mul_two, h_half]
        exact h_bound
      .branch
        (makeTreeAux d' offset len' h2 h_left_bound)
        (makeTreeAux d' (offset + len') len' h2 h_right_bound)
  have h_size_not_0 : a.size ≠ 0 := by
    intro h
    rw [h] at h_a_is_not_empty
    contradiction
  have h_total_bound : 0 + (2^depth) <= a.size := by
    rw [Nat.zero_add]
    rw [h_depth_eq_log2_size]
    apply Nat.log2_self_le
    exact h_size_not_0
  makeTreeAux depth 0 (2^depth) (by simp) h_total_bound

#eval Tree.fromArray #[0, 1, 2, 3] 2 (by decide) (by rfl)


def Tree.fromArrayUnchecked (a: Array Nat) (d: Nat) : Tree d :=
  let rec makeTreeAux (d: Nat) (a: Array Nat) (offset: Nat) : Tree d :=
    match d with
    | 0 => .leaf a[offset]!
    | d + 1 => .branch (makeTreeAux d a offset) (makeTreeAux d a (offset + 2^d))
  makeTreeAux d a 0

#eval Tree.fromArrayUnchecked #[0, 1, 2, 3] 2

namespace Constants

  def myTree :=
    Tree.branch
      (Tree.branch
        (Tree.branch (Tree.leaf 0) (Tree.leaf 1))
        (Tree.branch (Tree.leaf 2) (Tree.leaf 3)))
      (Tree.branch
        (Tree.branch (Tree.leaf 4) (Tree.leaf 5))
        (Tree.branch (Tree.leaf 6) (Tree.leaf 7)))

  #eval makeTreeOfIndices 3 == myTree
  #eval s!"{makeTreeOfIndices 3}"

  #eval invert myTree
  #eval invert (invert myTree) == myTree
  #eval Tree.fromArrayUnchecked (Array.range (2^4)) 4
  #eval Tree.fromArray (Array.range (2^4)) 4 (by decide) (by rfl)

end Constants
