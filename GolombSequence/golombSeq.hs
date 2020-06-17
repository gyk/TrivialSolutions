{--

slm sequence, a.k.a. Silverman's sequence


References:

- Programming Challenges, 6.6.7 Self-describing Sequence
- http://mathworld.wolfram.com/SilvermansSequence.html

--}

import Data.Array

slm 1 = 1
slm n =
    let initList = [(1, 1), (2, 3)] in
    slm' 3 3 initList where
        slm' k end whole@((i, e):xs)
            | end >= n = k - 1
            | k <= e = slm' (k+1) (end+i) (whole ++ [(k, end+i)])
            | otherwise = slm' k end xs

--  n   1  2  3  4  5
-- S(n) 1  2  2  3  ?
-- The value of s(5) can be s(4-1) = 3 or s(4-1) + 1 = 4,
-- depending on the number of occurences of 3, i.e., s(3).
-- Actually, s(5) = s(5 - s(3)) + 1.
slm2 n = a ! n where
    a = listArray (1, n) $ 1:2:(map (\i -> a!(i - a!(a!(i-1)))+1) [3..])

{--

n              |     S(n)
---------------------------
100           -->    21
9999          -->    356
123456        -->    1684
1000000000    -->    438744

--}
