-- Victor Taelin's "Invert a binary tree" challenge
-- https://gist.github.com/VictorTaelin/45440a737e47b872d7505c6cda27b6aa
import InvertBinaryTree

def readIntArray : IO (Array Nat) := do
  let stdin ← IO.getStdin
  let line ← stdin.getLine
  let numbers := line.splitOn " "
  let nats := numbers.filterMap String.toNat?
  return nats.toArray

#eval IO.println s!"{Tree.fromArrayUnchecked (#[1, 2, 3, 4, 5, 6, 7, 8]) 3}"

def main : IO Unit := do
  let arr ← readIntArray
  -- FIXME: How to fix it?
  if arr.size == 16 then
    let tree : Tree _ := Tree.fromArray arr 16 sorry sorry
    let invertedTree := invert tree
    IO.println s!"{tree}"
    IO.println s!"{invertedTree}"
