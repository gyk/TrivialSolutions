// Fenwick tree (binary indexed tree)
//
// The tree returns 0-based prefix sum, while the underlying array representation is 1-based.

namespace FenwickTree

open System

module private Helper =
    let inline lsb (x: int) = x &&& (-x)

type FenwickTree(n: int) =
    let arrLen = n + 1
    let mutable arr = Array.zeroCreate arrLen

    let lsbSeq x =
        let mutable x = x
        seq {
            while x > 0 do
                yield x
                x <- x - Helper.lsb x
        }

    let ancestorSeq x =
        let mutable x = x
        seq {
            while x < arrLen do
                yield x
                x <- x + Helper.lsb x
        }

    // Now we can see why it's called a binary indexed tree.
    member this.GetSum (index: int) = Seq.sumBy (fun i -> arr.[i]) <| lsbSeq (index + 1)

    // It's also intersting to note that `Add`ing at position x actually doesn't do much for prefix
    // sums until x but affects greatly for those beyond x (after all it is a *prefix* sum).
    member this.Add (index: int, value: int) =
        for i in ancestorSeq (index + 1) do
            arr.[i] <- arr.[i] + value

    module Test =
        let randomIdxDeltaArray n maxValue =
            let rnd = Random()
            Seq.initInfinite (fun _ -> (rnd.Next(0, n), rnd.Next(-maxValue, maxValue)))

        let smokeTest nTrials =
            for _ in 1..nTrials do
                let n = 250
                let ft = FenwickTree(n)
                let mutable aux = Array.zeroCreate n
                for (i, v) in Seq.take 100 (randomIdxDeltaArray n 1000) do
                    ft.Add(i, v)
                    aux.[i] <- aux.[i] + v

                let prefixIndices = randomIdxDeltaArray n 0
                                 |> Seq.take 5
                                 |> Seq.map fst
                for idx in prefixIndices do
                    let sumFromFenwick = ft.GetSum(idx)
                    let sumFromAuxArr = Seq.sum <| Seq.take (idx + 1) aux
                    if sumFromFenwick <> sumFromAuxArr then
                        failwith "Error"

            printfn "Done."
