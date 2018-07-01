module PairingHeap where

data PairingHeap a = Empty
                   | PairingTree !Int a [PairingHeap a]
                   deriving Show


singleton :: Int -> a -> PairingHeap a
singleton k v = PairingTree k v []

isEmpty Empty = True
isEmpty _     = False

insert :: Int -> a -> PairingHeap a -> PairingHeap a
insert k v Empty = singleton k v
insert k v h     = merge (singleton k v) h

findMin :: PairingHeap a -> (Int, a)
findMin Empty               = error "PairingHeap.findMin: empty heap"
findMin (PairingTree k v _) = (k, v)

deleteMin :: PairingHeap a -> PairingHeap a
deleteMin Empty                      = error "PairingHeap.deleteMin: empty heap"
deleteMin (PairingTree k v subHeaps) = mergePairs subHeaps

merge :: PairingHeap a -> PairingHeap a -> PairingHeap a
merge Empty h2 = h2
merge h1 Empty = h1
merge h1@(PairingTree k1 v1 subHeaps1) h2@(PairingTree k2 v2 subHeaps2)
    | k1 <= k2  = PairingTree k1 v1 (h2:subHeaps1)
    | otherwise = PairingTree k2 v2 (h1:subHeaps2)

mergePairs :: [PairingHeap a] -> PairingHeap a
mergePairs []         = Empty
mergePairs [h]        = h
mergePairs (h1:h2:hs) = merge h1 h2 `merge` mergePairs hs
