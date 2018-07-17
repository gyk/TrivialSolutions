import Test.QuickCheck

import qualified Data.List as L

import qualified SplayTree as SP

isSorted :: (Ord a) => [a] -> Bool
isSorted xs = all id . map (\(x,y) -> x <= y) . zip xs $ tail xs

-- Surely it's a quite incomplete property list.
prop_bst :: [Int] -> Bool
prop_bst xs =
  let
    ys = take 200 xs
    t = SP.fromList ys
    r = SP.root t
    last = fst `fmap` L.uncons ys
  in
    isSorted (SP.inorder t) &&
    r == last

main = do
  quickCheck prop_bst
