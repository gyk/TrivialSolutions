
module CircularQueue
    (
      CircularQueue
    , empty
    , enqueue
    , dequeue
    , length
    , isEmpty
    , isFull
    ) where

import Prelude hiding (length)

import Control.Monad (liftM, when)
import Control.Monad.ST (ST)
import Data.Array.ST (STArray)
import Data.Array.MArray (MArray, getBounds, newArray_, readArray, writeArray)
import Data.STRef (STRef, newSTRef, readSTRef, writeSTRef)

data CircularQueue s a = CQ {
      cqArray :: STArray s Int a
    , cqHead :: STRef s Int
    , cqTail :: STRef s Int
    }

{-# INLINE wrapInc #-}
wrapInc :: Int -> CircularQueue s a -> ST s Int
wrapInc i q = do
    (lo, hi) <- getBounds $ cqArray q
    let arrLen = hi - lo + 1
    return $ (i + 1) `mod` arrLen

empty :: Int -> ST s (CircularQueue s a)
empty capacity = do
    arr <- newArray_ (0, capacity - 1 + 1)
    h <- newSTRef 0
    t <- newSTRef 0
    return $ CQ arr h t

length :: CircularQueue s a -> ST s Int
length q = do
    h <- readSTRef $ cqHead q
    t <- readSTRef $ cqTail q
    (lo, hi) <- getBounds $ cqArray q
    let arrLen = hi - lo + 1
    return $ (t - h) `rem` arrLen

isEmpty :: CircularQueue s a -> ST s Bool
isEmpty q = do
    h <- readSTRef $ cqHead q
    t <- readSTRef $ cqTail q
    return $ h == t

isFull :: CircularQueue s a -> ST s Bool
isFull q = do
    h <- readSTRef $ cqHead q
    t <- readSTRef $ cqTail q
    newT <- wrapInc t q
    return $ h == newT

-- a.k.a. pushBack
enqueue :: a -> CircularQueue s a -> ST s ()
enqueue x q = do
    fullQ <- isFull q
    when fullQ $
        -- Protip: Don't use fail
        fail "Circular queue is full"

    t <- readSTRef $ cqTail q
    newT <- wrapInc t q
    writeSTRef (cqTail q) newT
    writeArray (cqArray q) t x

-- a.k.a. popFront
dequeue :: CircularQueue s a -> ST s a
dequeue q = do
    emptyQ <- isEmpty q
    when emptyQ $
        fail "Circular queue is empty"

    h <- readSTRef $ cqHead q
    newH <- wrapInc h q
    writeSTRef (cqHead q) newH
    readArray (cqArray q) h
