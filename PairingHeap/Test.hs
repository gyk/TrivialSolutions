import Test.QuickCheck

import qualified Data.List as L

import PairingHeap as PH

type Key = Int

heapSort :: [(Key, v)] -> [(Key, v)]
heapSort kvs =
  let
    pqueue = foldl (\pq (k, v) -> PH.insert k v pq) PH.Empty kvs
  in
    go pqueue []
      where
        go PH.Empty xs = reverse xs
        go pq       xs = go (PH.deleteMin pq) ((PH.findMin pq):xs)


prop_heapSort :: [Int] -> Bool
prop_heapSort xs =
  let
    ys = map (\x -> (x, x * x)) $ take 500 xs
    sorted = L.sort ys
    heapSorted = heapSort ys
  in
    sorted == heapSorted


main = do
  quickCheck prop_heapSort
