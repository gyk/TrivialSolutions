import System.Random

rangeSmall :: (Double, Double)
rangeSmall = (small (-), small (+)) where
  small = \op -> (1 `op`) . last . takeWhile 
    (\x -> sqrt(1 `op` x) /= 1) $ iterate (/2) 1

randSineList :: Double -> [Double]
randSineList seed = map (abs . fst) sinCosFib
  where
    sinCosFib :: [(Double, Double)]
    sinCosFib = (sin fib1, cos fib1) : (sin 1.5, cos 1.5) : 
      zipWith next sinCosFib (tail sinCosFib)
        where fib1 = 0.75 + 0.25 * (seed - 0.5)

    (lower, upper) = rangeSmall
    next' (sa, ca) (sb, cb) = (sa * cb + ca * sb, ca * cb - sa * sb)
    next sca scb = let
      (s, c) = next' sca scb
      lenSquared = s * s + c * c in
        if lenSquared >= upper || lenSquared <= lower
        then let scale = 1 / sqrt(lenSquared) in
          (s * scale, c * scale)
        else (s, c)

calcPiBuffon :: Int -> [(Double, Double)] -> (Int, Double)
calcPiBuffon nTosses distSinePairs = 
  (count, fromIntegral (nTosses * 2) / fromIntegral count) 
    where
      count = length . filter isCrossed . take nTosses $ distSinePairs
      isCrossed (distDoubled, sine) = sine > distDoubled

main = do
  r <- randomIO
  g <- newStdGen
  let total = 10000
  let (count, myPi) = calcPiBuffon total $ 
        zipWith (,) (randoms g) (randSineList r)

  putStrLn $ "Total: " ++ show total
  putStrLn $ "Count: " ++ show count
  putStrLn $ "Estimated Pi = " ++ show myPi
