module Graph

open System.Collections.Generic

open InfInt

type Edge =
    { capacity: InfInt
      mutable flow: InfInt } with
    member this.Residual : InfInt =
        this.capacity - this.flow
    member this.Increase (delta: InfInt) =
        this.flow <- min this.capacity (this.flow + delta)
    member this.IsVirtual : bool =
        this.capacity = Finite 0


let newEdge (capacity: InfInt) : Edge =
    { capacity = capacity
      flow = Finite 0 }

type IGraph =
    abstract member NumVertices : int
    abstract member NumEdges : int
    abstract member AddEdge : (int * int) -> InfInt -> unit
    abstract member GetEdge: (int * int) -> Edge option
    abstract member RemoveEdge: (int * int) -> Edge option
    abstract member GetEdges : int -> seq<int * Edge>
    abstract member Reset : unit -> unit

/// Undirected graph represented by adjacency matrix.
type GraphMat (nVertices: int) =
    let adjMat: Edge option [,] =
        Array2D.init nVertices nVertices (fun i j -> None)
    let mutable nEdges: int = 0

    interface IGraph with
        member this.NumVertices : int = nVertices
        member this.NumEdges : int = nEdges

        member this.AddEdge ((fromV, toV): int * int) (capacity: InfInt) =
            adjMat.[fromV, toV] <- Some (newEdge capacity)
            adjMat.[toV, fromV] <- Some (newEdge <| Finite 0)
            nEdges <- nEdges + 1

        member this.GetEdge ((fromV, toV): int * int) : Edge option =
            adjMat.[fromV, toV]

        member this.RemoveEdge ((fromV, toV): int * int) : Edge option =
            let old = adjMat.[fromV, toV]
            adjMat.[fromV, toV] <- None
            adjMat.[toV, fromV] <- None
            nEdges <- nEdges - 1
            old

        member this.GetEdges (fromV: int) : seq<int * Edge> =
            let n = (this :> IGraph).NumVertices
            seq {
                for j = 0 to (n - 1) do
                    match adjMat.[fromV, j] with
                    | Some e -> yield (j, e)
                    | _ -> ()
            }

        member this.Reset () =
            let n = (this :> IGraph).NumVertices
            for i = 0 to (n - 1) do
                for j = 0 to (n - 1) do
                    match adjMat.[i, j] with
                    | Some e -> e.flow <- Finite 0
                    | _ -> ()

    member this.AdjMatrix = adjMat


/// Undirected graph represented by adjacency list.
type GraphList (nVertices: int) =
    // Not really a list. But similar to adjacency lists, dicts work efficiently with sparse
    // networks.
    let adjList : Dictionary<int, Edge> [] =
        Array.init nVertices (fun _ -> Dictionary<int, Edge>())
    let mutable nEdges: int = 0

    member this.AdjList = adjList

    interface IGraph with
        member this.NumVertices : int = nVertices
        member this.NumEdges : int = nEdges

        member this.AddEdge ((fromV, toV): int * int) (capacity: InfInt) =
            adjList.[fromV].[toV] <- newEdge capacity
            adjList.[toV].[fromV] <- newEdge <| Finite 0
            nEdges <- nEdges + 1

        member this.GetEdge ((fromV, toV): int * int) : Edge option =
            match adjList.[fromV].TryGetValue(toV) with
            | (true, e) -> Some e
            | (false, _) -> None

        member this.RemoveEdge ((fromV, toV): int * int) : Edge option =
            match adjList.[fromV].TryGetValue(toV) with
            | (true, old) ->
                adjList.[fromV].Remove(toV) |> ignore
                adjList.[toV].Remove(fromV) |> ignore
                nEdges <- nEdges - 1
                Some old
            | (false, _) -> None

        member this.GetEdges (fromV: int) : seq<int * Edge> =
            seq {
                for KeyValue(j, e) in adjList.[fromV] do
                    yield (j, e)
            }

        member this.Reset () =
            for eList in adjList do
                for KeyValue(_, e) in eList do
                    e.flow <- Finite 0
