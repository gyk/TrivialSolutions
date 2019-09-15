module PriorityQueue

open System.Collections.Generic

type PriorityQueue() =
    let q = SortedDictionary<float, HashSet<int>>()

    member this.Contains (key: float) (value: int) : bool =
        match q.TryGetValue(key) with
        | (true, s) -> s.Contains(value)
        | _ -> false

    member this.TryPopMin () : int option =
        match Seq.tryHead q with
        | Some (KeyValue(minKey, s)) ->
            let m = Seq.head s
            s.Remove(m) |> ignore
            if s.Count = 0 then
                q.Remove(minKey) |> ignore
            Some m
        | None -> None

    member this.Add (key: float) (value: int) =
        match q.TryGetValue(key) with
        | (true, s) ->
            s.Add(value) |> ignore
        | (false, _) ->
            q.Add(key, HashSet([value]))

    member this.IsEmpty : bool =
        q.Count = 0

    /// Precondition: `(key, value)` does exist in the queue.
    member this.ChangeKey (key: float) (value: int) (newKey: float) =
        let s = q.[key]
        s.Remove(value) |> ignore
        if s.Count = 0 then
            q.Remove(key) |> ignore
        this.Add newKey value
