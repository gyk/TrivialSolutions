// A segment tree that does not really support inserting segments.

namespace SegmentTree

open System
open System.Collections.Generic
open System.Linq

type SegmentTree<'T>(data: 'T [], zero: 'T, combine: 'T -> 'T -> 'T) =
    let mutable tree: List<'T> = null

    // inclusive
    let getMid (l: int) (r: int) = l + (r - l) / 2
    let getLeftChild (idx: int) = idx * 2
    let getRightChild (idx: int) = idx * 2 + 1

    let getDepth (n: int) = Math.Log(float n, 2.0)
                            |> ceil
                            |> (+) Double.Epsilon
                            |> int
                            |> (+) 1

    let rec construct left right i =
        let sum =
            if left = right then
                data.[left]
            else
                let mid = getMid left right
                combine (construct left mid (getLeftChild i))
                        (construct (mid + 1) right (getRightChild i))
        tree.[i] <- sum
        sum

    let rec getSum left right i currLeft currRight =
        if left <= currLeft && right >= currRight then
            tree.[i]
        else if right < currLeft || left > currRight then
            zero
        else
            let currMid = getMid currLeft currRight
            combine (getSum left right (getLeftChild i) currLeft currMid)
                    (getSum left right (getRightChild i) (currMid + 1) currRight)

    let rec update left right i idx value =
        if left = right then
            tree.[i] <- value
        else
            let mid = getMid left right
            if idx <= mid then
                tree.[i] <- combine (update left mid (getLeftChild i) idx value)
                                    tree.[getRightChild i]
            else
                tree.[i] <- combine tree.[getLeftChild i]
                                    (update (mid + 1) right (getRightChild i) idx value)
        tree.[i]

    do
        let nLeaves = data.Length
        let depth = getDepth nLeaves
        tree <- Enumerable.Repeat(zero, (pown 2 depth) - 1 + 1).ToList()
        construct 0 (data.Length - 1) 1 |> ignore

    member this.GetSum(left: int, right: int) = getSum left right 1 0 (data.Length - 1)

    member this.Update(idx: int, value: 'T) = update 0 (data.Length - 1) 1 idx value |> ignore

////////////////////////////////////////////////////////////////

module SegmentTree =
    module NumericLiteralG =
      let inline FromZero() = LanguagePrimitives.GenericZero

    let inline getSumNaive (data: ^T [] when ^T: (static member (+): ^T * ^T -> ^T) and
                                             ^T: (static member get_Zero: unit -> ^T))
                           (left: int) (right: int) =
        if left >= data.Length || right < 0 then
            0G
        else
            seq { for i in left..right -> data.[i]: ^T } |> Seq.sum

    let randomIntArray n =
        let rnd = Random()
        Array.init n (fun _ -> rnd.Next(0, n))

    let smokeTest nTrials =
        for _ in 0 .. nTrials do
            let n = 25
            let a = randomIntArray n
            let segmentTree = SegmentTree(a, 0, (+))

            match a |> Array.take 2 |> Array.sort with
            | [|left; right|] ->
                // Updates one value
                let idx = a.[2]
                let value = a.[3]
                segmentTree.Update(idx, value)
                a.[idx] <- value

                let sumSegTree = segmentTree.GetSum(left, right)
                let sumNaive = getSumNaive a left right
                if sumSegTree <> sumNaive then
                    failwith "Not equal"
            | _ -> failwith "WTF"

        printfn "Tests done."
