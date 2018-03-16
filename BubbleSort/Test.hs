import Test.QuickCheck

import qualified Data.List as L
import Control.Monad.ST (runST)
import qualified Data.Vector.Unboxed as V

import BubbleSort


prop_sorted :: [Int] -> Bool
prop_sorted xs =
  let
    ys = take 250 xs
    sorted = L.sort ys
    v = V.fromList ys
  in
    (V.toList $ bubbleSort v) == sorted


main = do
  quickCheck prop_sorted
