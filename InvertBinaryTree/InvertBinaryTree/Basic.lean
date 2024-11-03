
inductive Tree : Nat → Type where
  | leaf : Nat → Tree 0
  | branch : {d: Nat} → Tree d → Tree d → Tree (d + 1)
  deriving BEq

instance : ToString (Tree 0) where
  toString : Tree 0 → String
  | .leaf k => s!"Leaf({k})"

instance {d: Nat} [ToString (Tree d)] : ToString (Tree (d + 1)) where
  toString : Tree (d + 1) → String
  | .branch l r => s!"Branch({toString l}, {toString r})"

def merge (l: Tree d) (r: Tree d) : Tree (d + 1) :=
  match l, r with
  | .leaf lk, .leaf rk => .branch (.leaf lk) (.leaf rk)
  | (.branch ll lr), (.branch rl rr) =>
    .branch (merge ll rl) (merge lr rr)

def invert (tree: Tree d) : Tree d :=
  match tree with
  | .leaf k => .leaf k
  | .branch l r =>
    let l := invert l
    let r := invert r
    merge l r

def invert' (bit: Bool) (tree: Tree d) : Tree d :=
  match bit with
  | true =>
      match tree with
      | .leaf k => .leaf k
      | .branch l r =>
        let l := invert' true l
        let r := invert' true r
        invert' false (.branch l r)
  | false =>
      match tree with
      | .leaf k => .leaf k -- unreachable
      | .branch l r =>
        match l, r with
        | .leaf lk, .leaf rk => .branch (.leaf lk) (.leaf rk)
        | (.branch ll lr), (.branch rl rr) =>
          .branch (invert' false (.branch ll rl))
                  (invert' false (.branch lr rr))
  termination_by if bit then d * 2 + 1 else d * 2
