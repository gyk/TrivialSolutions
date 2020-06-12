{-

Egg Dropping Puzzle
===================

* If the egg doesn't break at a certain floor, it will not break at any floor below.
* If the eggs break at a certain floor, it will break at any floor above.
* The egg may break at the first floor.
* The egg may not break at the last floor.

(So there are #floors + 1 cases in total.)

References
----------

- https://en.wikipedia.org/wiki/Dynamic_programming#Egg_dropping_puzzle
- https://leetcode.com/articles/super-egg-drop/
- https://brilliant.org/wiki/egg-dropping/

-}

import Data.Function (fix)
import Data.Array


-- n: number of test eggs available, n = 0, 1, 2, 3, ..., N.
-- k: number of (consecutive) floors yet to be tested, k = 0, 1, 2, ..., H.
-- Return value: minimum number of trials required
eggDropNaive :: Int -> Int -> Int
eggDropNaive = go
  where
    go _ 0 = 0
    go 1 k = k
    go n k = 1 + minimum [max
                            (go (n - 1) (x - 1)) -- 🍳
                            (go n       (k - x)) -- 🥚
                          | x <- [1..k]]


eggDropMemo :: Int -> Int -> Int
eggDropMemo n k = cache ! (n, k)
  where
    bnds = ((0, 0), (n, k))
    cache = listArray bnds . map go $ range bnds
    go (_, 0) = 0
    go (1, k) = k
    go (n, k) = 1 + minimum [max
                               (cache ! (n - 1, x - 1))
                               (cache ! (n,     k - x))
                             | x <- [1..k]]


eggDrop2 :: (Int -> Int -> Int) -> Int -> Int -> Int
eggDrop2 m _ 0 = 0
eggDrop2 m 1 k = k
eggDrop2 m n k = 1 + minimum [max
                                (m (n - 1) (x - 1))
                                (m n       (k - x))
                              | x <- [1..k]]

eggDropNaive2 = fix eggDrop2

memoize :: (Int -> Int -> Int) -> (Int -> Int -> Int)
memoize f n k = lol !! n !! k
  where
    lol = map (\n -> map (f n) [0..]) [0..]

-- FIXME: Why is it so slow? The single argument case
-- (https://wiki.haskell.org/Memoization#Memoizing_fix_point_operator) works fine.
eggDropMemo2 :: Int -> Int -> Int
eggDropMemo2 = fix (memoize . eggDrop2)
-- reduced to `memoize (eggDrop2 eggDropMemo2)`

----------------------------------------------------------------

{-

Faster DP solution
------------------

- [leetcode]: https://leetcode.com/articles/super-egg-drop/#approach-3-mathematical
- [brilliant]: https://brilliant.org/wiki/egg-dropping/#a-better-approach
- [wiki]:
  https://en.wikipedia.org/wiki/Dynamic_programming#Faster_DP_solution_using_a_different_parametrization


There are two approaches to formulate the problem. One is defining `f t n` as #floors we can explore
using `n` eggs with `t` trials. It can be computed as 1 (the floor where we drop egg) + #floors
below if the egg is broken + #floors above if the egg survives. (The floor where the egg is dropped
at this trial becomes the new 0-th floor of the sub-problem, should the egg survice.) So the
recursive formulation is

    f 0 _ = 0
    f _ 0 = 0
    f t n = 1 + f (t - 1) (n - 1) + f (t - 1) n

However, to solve the recurrence relation analytically, we have to introduce an auxiliary function
`g`, which is inconvenient.

The other approach is defining `f t n` as #floors that can be *distinguished* using `n` eggs with
`t` trials. Here *distinguish* means "classify" the floors by the `t`-length sequence of successful
and failed throws. The recursive formulation becomes

    f t 0 = 1
    f 0 n = 1
    f t n = f (t - 1) (n - 1) + f (t - 1) n

Note that this process includes distinguishing the 0-th floor. As a result, now the formulation gets
rid of the `+1` term, so it directly maps to Bernoulli's triangle
(http://oeis.org/wiki/Bernoulli%27s_triangle) and the derivation is simplified. The solution is just

    Σ_{0 ≤ x ≤ n} C(t, x)

Also note that the need to distinguish the 0-th floor makes the corresponding value 1 less than the
sum (Or equivalent, `Σ_{1 ≤ x ≤ n} C(t, x)`). See [leetcode] "Alternative Mathematical Derivation"
for details.

-}

eggDropFast :: Int -> Int -> Int
eggDropFast n k = binarySearch (flip f n) 0 k k'
  where
    k' = toInteger k
    choose t = scanl (\c i -> c * (toInteger t - i + 1) `div` i) 1 [1..]
    f t n = sum . take n . tail $ choose t

-- Returns the minimum `i` s.t. `f i >= x`, where `i <- [l..r]`.
-- Precondition: ∀t ∈ [l, r]: f(t) ≤ f(t + 1) ∧ f(r) ≥ x
binarySearch :: (Int -> Integer) -> Int -> Int -> Integer -> Int
binarySearch f l r x = bs l r
  where
    bs l r =
      if l == r
      then l
      else let m = l + (r - l) `div` 2 in
        if f m >= x
        then bs l m
        else bs (m + 1) r
