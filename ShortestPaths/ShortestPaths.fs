// # Shortest Paths in F#
//
// ## References
//
// - Algorithms in C, Robert Sedgewick, Chapter 21.

module ShortestPaths
    open Graph

    /// A pair of `(parent-id, distance-to-the-source)`.
    type ParentDist = int * float

    // Represented as a shortest path tree
    type ShortestPaths = ParentDist option []

    /// A pair of `(next-vertex-id, distance-to-the-source)`.
    type NextDist = int * float

    type AllShortestPaths = NextDist option [,]

    let makeInverse (g: GraphList) : GraphList =
        let invG = GraphList((g :> IGraph).NumVertices)
        let edges = (g :> IGraph).ExtractEdges()
        for ((a, b), wt) in edges do
            (invG :> IGraph).AddEdge (b, a) wt
        invG

    // Given a method that solves single-source shortest paths, computes all-pairs shortest paths of
    // the graph.
    let ComputeAllPairsShortestPaths
        (g: GraphList)
        (solver: GraphList -> int -> ShortestPaths)
        : AllShortestPaths =
        let n = (g :> IGraph).NumVertices
        // Uses the inverse graph because the path matrix stores the next vertex on the path rather
        // than the parent link.
        let invG = makeInverse g
        let allPaths = Array2D.init n n (fun _ _ -> None)
        for i in 0 .. (n - 1) do
            let p = solver invG i
            allPaths.[*, i] <- p
        allPaths

    open PriorityQueue

    /// Dijkstra's algorithm.
    ///
    /// Precondition: Graph `g` has no negative edges.
    let Dijkstra (g: GraphList) (source: int) : ShortestPaths =
        let n = (g :> IGraph).NumVertices
        let spTree = Array.init n (fun _ -> None)

        // Most implementations of Dijkstra's algorithm insert all vertices at once into the
        // priority queue at initialization, rather than using tricolor graph traversal.
        let q = PriorityQueue(n)
        for i = 0 to (n - 1) do
            q.Add(if i = source then 0.0 else infinity) |> ignore
        spTree.[source] <- Some (source, 0.0)

        while not q.IsEmpty do
            let (minV, _) = q.DeleteMin()
            if q.[minV] < infinity then
                for (v, wt) in g.AdjList.[minV] do
                    let d = q.[minV] + wt
                    if d < q.[v] then  // relaxation
                        q.[v] <- d
                        spTree.[v] <- Some (minV, d)
        spTree

    /// Floyd-Warshall algorithm.
    let FloydWarshall (g: GraphMat) : AllShortestPaths =
        // Notes:
        //
        // - w(s, s) = 0.0
        // - d(s, t, 0) = w(s, t)
        // - d(s, i, i - 1) has already used vertex i. For the same reason we don't need to use an
        //   array of V^3 elements.
        let n = (g :> IGraph).NumVertices
        let p = Array2D.mapi
                    (fun s t w ->
                        if s = t then
                            Some (t, 0.0)
                        else
                            Option.map (fun w -> (t, w)) w)
                    g.AdjMatrix
        let d (s, t) =
            match p.[s, t] with
            | Some (_, wt) -> wt
            | None -> infinity

        for i in 0 .. (n - 1) do
            for s in 0 .. (n - 1) do
                if d(s, i) < infinity then
                    for t in 0 .. (n - 1) do
                        let d' = d(s, i) + d(i, t)
                        if d' < d(s, t) then
                            let p' = fst << Option.get <| p.[s, i]  // (!) not `i`
                            p.[s, t] <- Some (p', d')
        p
