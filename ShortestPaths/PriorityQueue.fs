// # Priority Queues for Index Items
//
// ## References
//
// - Algorithms in C, Robert Sedgewick, Chapter 9.

module PriorityQueue

type PriorityQueue(capacity: int) =
    let data = ResizeArray<float>(capacity)
    let indices = ResizeArray<int>(capacity + 1)
    let invIndices = ResizeArray<int option>(capacity)
    do
        indices.Add(-1)

    let getN () = indices.Count - 1

    let swap (i: int) (j: int) =
        let k = indices.[i]
        indices.[i] <- indices.[j]
        indices.[j] <- k

        invIndices.[indices.[i]] <- Some i
        invIndices.[indices.[j]] <- Some j

    let rec fixUp: int -> unit = function
        | 0 -> failwith "Invalid index"
        | 1 -> ()
        | i ->
            let p = i / 2
            if data.[indices.[p]] > data.[indices.[i]] then
                swap p i
                fixUp p

    let rec fixDown (i: int) =
        let n = getN ()
        let l, r = i * 2, i * 2 + 1
        if l > n then  // no children
            ()
        else
            let m =
                if l = n then  // only left child
                    l
                else  // Both children exist. It also implies i <= n, obviously.
                    if data.[indices.[l]] <= data.[indices.[r]] then
                        l
                    else
                        r

            if data.[indices.[i]] > data.[indices.[m]] then
                swap i m
                fixDown m

    // The count of items in the queue, with `indicecs.[0]` excluded, of course.
    member this.Count : int = getN ()

    member this.IsEmpty : bool = this.Count = 0

    member this.Add (x: float) : int =
        data.Add(x)
        let dataIndex = data.Count - 1
        indices.Add(dataIndex)
        invIndices.Add(Some <| indices.Count - 1)
        fixUp <| getN ()
        dataIndex

    member this.PeekMin () : (int * float) =
        let minIndex = indices.[1]
        (Option.get invIndices.[minIndex], data.[minIndex])

    member this.DeleteMin () : (int * float) =
        let minIndex = indices.[1]
        let minValue = data.[minIndex]

        let n = getN ()
        swap 1 n
        indices.RemoveAt(int(n))
        invIndices.[minIndex] <- None

        fixDown 1
        (minIndex, minValue)

    // Method `ChangeKey` is implicitly implemented in the setter of indexed property.

    member this.Item
        with get (index: int) =
            data.[index]
        and set (index: int) (value: float) =
            let oldValue = data.[index]
            data.[index] <- value
            match invIndices.[index] with
            | Some i ->
                if value < oldValue then
                    fixUp i
                else if value > oldValue then
                    fixDown i
            | None -> ()
