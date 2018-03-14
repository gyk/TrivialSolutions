import Test.QuickCheck

import Control.Monad (forM, forM_, liftM2, replicateM, when)
import Control.Monad.ST (runST)

import qualified CircularQueue as CQ

prop_enqueNDequeN :: [Int] -> Bool
prop_enqueNDequeN xs = runST $ do
    let l = length xs
    q <- CQ.empty l
    checkEmptiness <- CQ.isEmpty q
    forM_ xs $ \x -> do
        CQ.enqueue x q
    checkFullness <- CQ.isFull q

    if not (checkEmptiness && checkFullness)
    then return False
    else do
        ys <- replicateM l $ CQ.dequeue q
        liftM2 (&&) (CQ.isEmpty q) (return $ xs == ys)

prop_enque1Deque1 :: [Int] -> Bool
prop_enque1Deque1 xs = runST $ do
    let l = length xs
    q <- CQ.empty l

    ys <- forM xs $ \x -> do
        CQ.enqueue x q
        CQ.dequeue q

    return $ xs == ys

-- Oops, this is not really QuickCheck
prop_length :: Bool
prop_length = runST $ do
    q <- CQ.empty 2
    l <- CQ.length q
    if l /= 0
    then return False
    else do
        CQ.enqueue 42 q
        CQ.enqueue 42 q
        l <- CQ.length q
        return $ l == 2


main = do
    quickCheck prop_enqueNDequeN
    quickCheck prop_enque1Deque1
    quickCheck prop_length
