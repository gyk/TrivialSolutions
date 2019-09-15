module Graph

// Using `Map` (`Map<(Vertex, Vertex), Weight>` and `Map<Vertex, Map<Vertex, Weight>>`) will be more
// flexible.

type IGraph =
    abstract member NumVertices : int
    abstract member NumEdges : int
    abstract member AddEdge : (int * int) -> float -> unit
    abstract member ExtractEdges : unit -> ((int * int) * float) []

/// Undirected graph represented by adjacency matrix.
type GraphMat (nVertices: int) =
    let adjMat: float option [,] =
        Array2D.init nVertices nVertices (fun _ _ -> None)
    let mutable nEdges: int = 0

    interface IGraph with
        member this.NumVertices : int = nVertices
        member this.NumEdges : int = nEdges

        member this.AddEdge ((fromV, toV): int * int) (weight: float) =
            adjMat.[fromV, toV] <- Some weight
            adjMat.[toV, fromV] <- Some weight
            nEdges <- nEdges + 1

        member this.ExtractEdges () : ((int * int) * float) [] =
            let n = (this :> IGraph).NumVertices
            // How about size hint and pre-allocation?
            [|
                for i = 0 to (n - 1) do
                    for j = i to (n - 1) do
                        match adjMat.[i, j] with
                        | Some wt -> yield ((i, j), wt)
                        | _ -> ()
            |]

    member this.AdjMatrix = adjMat
    member this.RemoveEdge ((fromV, toV): int * int) : float option =
        let old = adjMat.[fromV, toV]
        adjMat.[fromV, toV] <- None
        adjMat.[toV, fromV] <- None
        nEdges <- nEdges - 1
        old

/// Undirected graph represented by adjacency list.
type GraphList (nVertices: int) =
    let adjList : (int * float) list [] =
        Array.init nVertices (fun _ -> [])
    let mutable nEdges: int = 0

    member this.AdjList = adjList

    interface IGraph with
        member this.NumVertices : int = nVertices
        member this.NumEdges : int = nEdges

        member this.AddEdge ((fromV, toV): int * int) (weight: float) =
            adjList.[fromV] <- (toV, weight) :: adjList.[fromV]
            adjList.[toV] <- (fromV, weight) :: adjList.[toV]
            nEdges <- nEdges + 1

        member this.ExtractEdges () : ((int * int) * float) [] =
            let n = (this :> IGraph).NumVertices
            [|
                for u = 0 to (n - 1) do
                    for (v, wt) in adjList.[u] do
                        if v >= u then
                            yield ((u, v), wt)
            |]
