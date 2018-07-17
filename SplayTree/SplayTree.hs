module SplayTree (
    SplayTree
  , splay
  , empty
  , singleton
  , insert
  , fromList
  , inorder
  , root
  ) where


data SplayTree a = Nil | Node a (SplayTree a) (SplayTree a)
                   deriving (Eq, Show)


data Direction = LH | RH | NA
                 deriving (Eq, Show)


empty = Nil

singleton x = Node x Nil Nil

-- Bottom-up splaying.
-- Inspired by Mark Lentczner's StackOverflow answer, but indeed a different implementation.
splay :: (Ord a) => a -> SplayTree a -> SplayTree a
splay x t = rebuild init path
  where
    findPath x Nil            pth = (NA, singleton x):pth
    findPath x t@(Node n l r) pth = case (compare x n) of
        LT -> findPath x l ((LH, t):pth)
        EQ -> (NA, t):pth
        GT -> findPath x r ((RH, t):pth)

    ((_, init):path) = findPath x t []

    rebuild :: (Ord a) => SplayTree a -> [(Direction, SplayTree a)] -> SplayTree a
    rebuild t [] = t
    rebuild t ((LH, Node p _ tP):[]) = rebuild (rotL $ Node p t tP) []
    rebuild t ((RH, Node p tP _):[]) = rebuild (rotR $ Node p tP t) []
    rebuild t ((LH, Node p _ tP):(LH, Node g _ tG):pth) = rebuild (rotLL $ Node g (Node p t tP) tG) pth
    rebuild t ((RH, Node p tP _):(RH, Node g tG _):pth) = rebuild (rotRR $ Node g tG (Node p tP t)) pth
    rebuild t ((RH, Node p tP _):(LH, Node g _ tG):pth) = rebuild (rotLR $ Node g (Node p tP t) tG) pth
    rebuild t ((LH, Node p _ tP):(RH, Node g tG _):pth) = rebuild (rotRL $ Node g tG (Node p t tP)) pth

-- The naming convention here follows the diagrams in the Wikipedia article.
-- And also, `rot{g-p direction}{p-x direction}`.

-- Zig
rotL :: SplayTree a -> SplayTree a
rotL Nil = Nil
rotL (Node p (Node x tA tB) tC) = Node x tA (Node p tB tC)

rotR :: SplayTree a -> SplayTree a
rotR Nil = Nil
rotR (Node p tC (Node x tB tA)) = Node x (Node p tC tB) tA

-- Zig-zig
--
-- This operation is done on edge g-p and then p-x. The order is important for preventing an O(n)
-- amortized time complexity. For example, the LL case should be: `(g (p (x A B) C) D) -> (p (x A B)
-- (g C D)) -> (x A (p B (g C D)))` rather than `(g (p (x A B) C) D) -> (g (x A (p B C)) D) -> (x A
-- (g (p B C) D))`. Zig-zig is the only operation that is different from the "rotate-to-root"
-- heuristic. There are some particular access patterns that make "rotate-to-root"'s performance
-- poor. See <https://cs.stackexchange.com/a/1230> for details.

rotLL :: SplayTree a -> SplayTree a
rotLL Nil = Nil
rotLL (Node g (Node p (Node x tA tB) tC) tD) = Node x tA (Node p tB (Node g tC tD))

rotRR :: SplayTree a -> SplayTree a
rotRR Nil = Nil
rotRR (Node g tD (Node p tC (Node x tB tA))) = Node x (Node p (Node g tD tC) tB) tA

-- Zig-zag
--
-- Rotation order: p-x and then g-x
-- The LR case: (g (p A (x B C)) D) -> (g (x (p A B) C) D) -> (x (p A B) (g C D))
rotLR :: SplayTree a -> SplayTree a
rotLR Nil = Nil
rotLR (Node g (Node p tA (Node x tB tC)) tD) = Node x (Node p tA tB) (Node g tC tD)

rotRL :: SplayTree a -> SplayTree a
rotRL Nil = Nil
rotRL (Node g tD (Node p (Node x tC tB) tA)) = Node x (Node g tD tC) (Node p tB tA)


insert :: (Ord a) => a -> SplayTree a -> SplayTree a
insert x Nil = singleton x
insert x t   = splay x t

fromList :: (Ord a) => [a] -> SplayTree a
fromList = foldr insert empty

inorder :: SplayTree a -> [a]
inorder Nil = []
inorder (Node n l r) = inorder l ++ [n] ++ inorder r  -- `(++)` is right associative

root :: SplayTree a -> Maybe a
root Nil = Nothing
root (Node n l r) = Just n
