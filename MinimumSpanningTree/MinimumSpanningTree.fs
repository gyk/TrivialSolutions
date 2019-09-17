// # Minimum Spanning Tree in F#
//
// The code here is based on implementations in C, so it is intentionally written in imperative
// rather than functional style. (Unfortunately, F#'s lack of break/continue in a loop makes some
// control flows not very straightforward to write.)
//
// ## References
//
// - Algorithms in C, Robert Sedgewick, Chapter 20.

module MinimumSpanningTree
    open Graph

    type ParentLink = int * float

    /// The MST represented as a mapping from the node ID to a pair consisting of the ID of its
    /// parent in the tree and the weight of the edge connecting them. The root's parent is itself.
    type MstResult = ParentLink []

    type MstTmpResult = ParentLink option []

    (* Utilities *)
    let treeLength (st: MstResult) : float =
        Seq.sumBy snd st

    let edgeListToParentLinks (es: ResizeArray<(int * int) * float>) (nVertices: int) : MstResult =
        let spTree: MstTmpResult = Array.init nVertices (fun _ -> None)
        let mst = GraphList(nVertices)
        for (uv, wt) in es do
            (mst :> IGraph).AddEdge uv wt

        let rec dfs (u: int) =
            for (v, wt) in mst.AdjList.[u] do
                if Option.isNone spTree.[v] then
                    spTree.[v] <- Some (u, wt)
                    dfs v

        spTree.[0] <- Some (0, 0.0)
        dfs 0
        Array.map Option.get spTree

    let mstPrimMat (g: GraphMat) : MstResult =
        let n = (g :> IGraph).NumVertices
        let spTree: MstTmpResult = Array.init n (fun _ -> None)
        let fringe: MstTmpResult = Array.init n (fun _ -> None)
        let mutable minVertex = Some 0
        fringe.[0] <- Some (0, 0.0)

        while Option.isSome minVertex do
            let minV = Option.get minVertex
            spTree.[minV] <- fringe.[minV]
            let mutable m = None  // the minimum vertex this round
            for i = 0 to (n - 1) do
                match spTree.[i] with  // whether vertex `i` is in the spanning tree
                | None ->
                    let frWt =
                        match (g.AdjMatrix.[minV, i], Option.map snd fringe.[i]) with
                        | (None, None) ->
                            None
                        | (None, Some frWt) ->
                            Some frWt
                        | (Some wt, Some frWt) when frWt <= wt ->
                            Some frWt
                        | (Some wt, _) ->
                            fringe.[i] <- Some (minV, wt)
                            Some wt

                    let minWt = m
                                |> Option.bind (fun i -> fringe.[i])
                                |> Option.map snd

                    match (minWt, frWt) with
                    | (Some minWt, Some frWt) when frWt < minWt -> m <- Some i
                    | (None, Some _) -> m <- Some i
                    | _ -> ()
                | _ -> ()
            minVertex <- m
        Array.map Option.get spTree

    open PriorityQueue
    let mstPrimList (g: GraphList) : MstResult =
        let n = (g :> IGraph).NumVertices
        let spTree: MstTmpResult = Array.init n (fun _ -> None)
        let fringe: MstTmpResult = Array.init n (fun _ -> None)
        let frQueue = PriorityQueue()
        let mutable minV = 0
        fringe.[0] <- Some (0, 0.0)
        frQueue.Add 0.0 0

        while not frQueue.IsEmpty do
            let minV = Option.get <| frQueue.TryPopMin ()
            spTree.[minV] <- fringe.[minV]
            for (v, wt) in g.AdjList.[minV] do
                if Option.isNone spTree.[v] then
                    match fringe.[v] with
                    | Some (_, oldWt) ->
                        if wt < oldWt then
                            fringe.[v] <- Some (minV, wt)
                            frQueue.ChangeKey oldWt v wt
                    | None ->
                        fringe.[v] <- Some (minV, wt)
                        frQueue.Add wt v
        Array.map Option.get spTree

    open UnionFind
    let mstKruskal (g: IGraph) : MstResult =
        let n = g.NumVertices
        let edges = g.ExtractEdges ()
        Array.sortInPlaceBy (fun (_, wt) -> wt) edges
        let tmpTree: ResizeArray<(int * int) * float> = ResizeArray []
        let uf = UnionFind(n)
        for ((u, v), wt) in edges do
            if not <| uf.IsConnected u v then
                uf.Union u v
                tmpTree.Add(((u, v), wt))
        edgeListToParentLinks tmpTree n

    type private Dict = System.Collections.Generic.Dictionary<int, (int * int) * float>
    let mstBoruvka (g: IGraph) : MstResult =
        let n = g.NumVertices
        let mutable edges = seq <| g.ExtractEdges ()

        let setNN (nearest: Dict) (sId: int) (uv: (int * int)) (wt: float) =
            match nearest.TryGetValue(sId) with
            | (true, (_, nnWt)) when nnWt <= wt -> ()
            | _ -> nearest.[sId] <- (uv, wt)

        let uf = UnionFind(n)
        let tmpTree: ResizeArray<(int * int) * float> = ResizeArray []
        while not <| Seq.isEmpty edges do
            let nearest = Dict()
            let remainingEdges = ResizeArray<(int * int) * float>()
            for ((u, v) as uv, wt) in edges do
                let u' = uf.Find u
                let v' = uf.Find v
                if u' <> v' then
                    remainingEdges.Add((uv, wt))
                    setNN nearest u' uv wt
                    setNN nearest v' uv wt
            edges <- remainingEdges

            for KeyValue(_, ((u, v), wt)) in nearest do
                if not <| uf.IsConnected u v then  // prevents duplicated edges
                    tmpTree.Add(((u, v), wt))
                    uf.Union u v

        edgeListToParentLinks tmpTree n
