-- Josephus problem

josephus n m = (snd . head . dropWhile (\(i, s) -> i < n)) xs
  where
    xs = iterate (\(i, s) -> (i + 1, (s + m) `rem` (i + 1))) (1, 0)

josephusFast n m
  | n < m     = josephus n m
  | m == 1    = n - 1
  | otherwise = let j = josephusFast (n - n `div` m) m
                    t = j - n `rem` m
                in
                  if t < 0
                  -- j' = (j - n % m) + n
                  then t + n
                  -- j' = (j - n % m) + (j - n % m) / (m - 1)
                  else t + t `div` (m - 1)
