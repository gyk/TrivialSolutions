module Graph

// Using `Map` (`Map<(Vertex, Vertex), Weight>` and `Map<Vertex, Map<Vertex, Weight>>`) will be more
// flexible.

type IGraph =
    abstract member NumVertices : int
    abstract member NumEdges : int
    abstract member AddEdge : (int * int) -> float -> unit
    abstract member ExtractEdges : unit -> seq<(int * int) * float>

/// Undirected graph represented by adjacency matrix.
type GraphMat (nVertices: int) =
    let adjMat: float option [,] =
        Array2D.init nVertices nVertices (fun i j -> None)
    let mutable nEdges: int = 0

    interface IGraph with
        member this.NumVertices : int = nVertices
        member this.NumEdges : int = nEdges

        member this.AddEdge ((fromV, toV): int * int) (weight: float) =
            adjMat.[fromV, toV] <- Some weight
            nEdges <- nEdges + 1

        member this.ExtractEdges () : seq<(int * int) * float> =
            let n = (this :> IGraph).NumVertices
            seq {
                for i = 0 to (n - 1) do
                    for j = 0 to (n - 1) do
                        match adjMat.[i, j] with
                        | Some wt -> yield ((i, j), wt)
                        | _ -> ()
            }

    member this.AdjMatrix = adjMat
    member this.RemoveEdge ((fromV, toV): int * int) : float option =
        let old = adjMat.[fromV, toV]
        adjMat.[fromV, toV] <- None
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
            nEdges <- nEdges + 1

        member this.ExtractEdges () : seq<(int * int) * float> =
            let n = (this :> IGraph).NumVertices
            seq {
                for u = 0 to (n - 1) do
                    for (v, wt) in adjList.[u] do
                        yield ((u, v), wt)
            }
