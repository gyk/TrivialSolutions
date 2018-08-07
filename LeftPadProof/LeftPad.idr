-- The Great Theorem Prover Showdown (https://github.com/hwayne/lets-prove-leftpad/)
--
-- Code here is nearly completely copied from @porglezomp's Idris implementation, just for the
-- purpose of self edification.

module LeftPad

import Data.Vect

-- As I am totally new to theorem proving, I hereby write down some confusions about this proof:
--
-- * This implementation seems to sidestep the proof of the post-condition that the suffix does be
--   the original string. Is it still sound?
-- * The use of dependent pair seems redundant?
-- * Is `rewrite` deprecated by the new Elaborator Reflection system?

-- `minus` is saturating subtraction
-- `maximum` has branch `maximum Z m` but not `maximum m Z`
-- The 3rd case:
--     - Goal := maximum (S k) (S n) = (S n - S k) + S k
--     - maximum (S k) (S n) = S (maximum k n)
--     - Goal => S (maximum k n) = (S n - S k) + S k
--     - Induction hypothesis := maximum k n = (n - k) + k
--     - Goal => S ((n - k) + k) = (S n - S k) + S k
--
--     - plusSuccRightSucc l r := S (l + r) = l + S r
--     - plusSuccRightSucc (n - k) k => S ((n - k) + k) = (n - k) + S k
--     - Goal => (n - k) + S k = (S n - S k) + S k
--     - minus (S left) (S right) = minus left right
--     - Goal => trivial

eq_max : (n, k : Nat) -> maximum k n = plus (n `minus` k) k
eq_max n     Z     = rewrite minusZeroRight n in
                     rewrite plusZeroRightNeutral n in
                     Refl
eq_max Z     (S _) = Refl
eq_max (S n) (S k) = rewrite sym $ plusSuccRightSucc (n `minus` k) k in
                     rewrite eq_max n k in
                     Refl

leftPad : (padChar : Char) -> (n : Nat) -> (xs : Vect k Char) -> Vect (maximum k n) Char
leftPad {k} padChar n xs = rewrite eq_max n k
  in
    replicate (n `minus` k) padChar ++ xs
