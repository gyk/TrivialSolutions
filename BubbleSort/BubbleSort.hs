{-

A Haskell implementation of Cocktail shaker sort, or bidirectional bubble sort.

-}

module BubbleSort (bubbleSort, bubbleSortM) where

import Control.Monad (forM_, when)
import Control.Monad.Primitive (PrimMonad, PrimState)
import qualified Data.Vector.Unboxed as V
import qualified Data.Vector.Unboxed.Mutable as VM

bubbleSortM :: (PrimMonad m, V.Unbox a, Ord a) => VM.MVector (PrimState m) a -> m ()
bubbleSortM v
  | VM.null v = return ()
  | otherwise = do
      let end = VM.length v - 1
      bubbleSortR v 0 end 1

bubbleSortR :: (PrimMonad m, V.Unbox a, Ord a) => VM.MVector (PrimState m) a -> Int -> Int -> Int -> m ()
bubbleSortR v start end dir = do
  if start == end
  then return ()
  else do
    forM_ [start, start + dir .. end - dir] $ \i -> do
      let j = i + dir
      x <- VM.read v i
      y <- VM.read v j
      when (fromEnum (x `compare` y) - 1 == dir) $ do
        VM.swap v i j
    bubbleSortR v (end - dir) start (-dir)


bubbleSort :: (V.Unbox a, Ord a) => V.Vector a -> V.Vector a
bubbleSort v = V.modify bubbleSortM v
