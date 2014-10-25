{--

Introduction to Algorithms: A Creative Approach
5.6 The skyline problem

--}

-- (begin, height, end)
type Building = (Int, Int, Int)

-- [(x, h)]
type Skyline = [(Int, Int)]

split :: [a] -> ([a],[a])
split xs = go xs xs where
  go (x:xs) (_:_:zs) = (x:us,vs) where (us,vs) = go xs zs
  go    xs   _       = ([],xs)

singleton :: Building -> Skyline
singleton (begin, height, end) = [(begin, height), (end, 0)]

-- The main skyline function
skyline :: [Building] -> Skyline
skyline x = tidy $ skyline' x
  where
    skyline' xs@(x1:x2:rest) = let (s1, s2) = split xs in
        merge (skyline s1) (skyline s2)
    skyline' (x:[]) = singleton x

merge :: Skyline -> Skyline -> Skyline
merge sk1 sk2 = merge' (0, 0) sk1 sk2
  where
    merge' (curH1, curH2) ((p1, h1):r1) ((p2, h2):r2)
        = if p1 <= p2 then
            (p1, max h1 curH2) : merge' (h1, curH2) r1 ((p2, h2):r2)
          else
            (p2, max curH1 h2) : merge' (curH1, h2) ((p1, h1):r1) r2

    merge' (curH1, 0) ((p1, h1):r1) _
        =  (p1, h1) : merge' (h1, 0) r1 []
    merge' (0, curH2) _ ((p2, h2):r2)
        =  (p2, h2) : merge' (0, h2) [] r2
    merge' (0, 0) _ _
        =  []

-- removes redundant items
tidy :: Skyline -> Skyline
tidy ((p1, h1):(p2, h2):rest)
  | p1 == p2    =  if h1 >= h2
                   then       tidy ((p1, h1):rest)
                   else       tidy ((p2, h2):rest)
  | h1 == h2    =             tidy ((p1, h1):rest)
  | otherwise   =  (p1, h1) : tidy ((p2, h2):rest)
tidy x = x

-- the example test case
testBuildings = [
  (1, 11, 5), 
  (2, 6, 7), 
  (3, 13, 9), 
  (12, 7, 16), 
  (14, 3, 25), 
  (19, 18, 22), 
  (23, 13, 29), 
  (24, 4, 28)]

-- The answer is:
--   [(1,11),(3,13),(9,0),(12,7),(16,3),(19,18),(22,3),(23,13),(29,0)]
main = print $ skyline testBuildings
