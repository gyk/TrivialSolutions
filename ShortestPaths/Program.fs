open Graph
open ShortestPaths

type GraphData =
    { nVertices: int;
      edges: seq<(int * int) * float> }

    member this.ToGraphMat (): GraphMat =
        let gMat = GraphMat(this.nVertices)
        for e in this.edges do
            e ||> (gMat :> IGraph).AddEdge
        gMat

    member this.ToGraphList (): GraphList =
        let gList = GraphList(this.nVertices)
        for e in this.edges do
            e ||> (gList :> IGraph).AddEdge
        gList

let testShortestPaths (testId: int) (gData: GraphData): bool =
    let gList = gData.ToGraphList()
    printfn "\n\nGraph %d\n========\n" testId
    let dijkstraAPSP = ComputeAllPairsShortestPaths gList Dijkstra
    printfn "All shortest paths = \n%A\n" dijkstraAPSP

    let gMat = gData.ToGraphMat()
    let floydAPSP = FloydWarshall gMat
    printfn "All shortest paths = \n%A\n" floydAPSP

    // Ugly code, to deal with floating-point comparison
    let n = (gList :> IGraph).NumVertices
    seq {
        for i in 0 .. (n - 1) do
            for j in 0 .. (n - 1) do
                yield
                    match dijkstraAPSP.[i, j], floydAPSP.[i, j] with
                    | Some (l1, w1), Some (l2, w2) ->
                        l1 = l2 && abs(w1 - w2) < 1e-6
                    | None, None -> true
                    | _ -> false
    } |> Seq.exists not |> not

[<EntryPoint>]
let main argv =
    // Trivial
    let g0Data = {
        nVertices = 1;
        edges = []
    }

    // Sedgewick's book, Fig. 21.8
    let g1Data = {
        nVertices = 6;
        edges =
        [
            ((0, 1), 0.41);
            ((0, 5), 0.29);
            ((1, 2), 0.51);
            ((1, 4), 0.32);
            ((2, 3), 0.50);
            ((3, 0), 0.45);
            ((3, 5), 0.38);
            ((4, 2), 0.32);
            ((4, 3), 0.36);
            ((5, 1), 0.29);
            ((5, 4), 0.21);
        ]
    }

    // The inverse graph of Graph 1
    let g2Data = {
        nVertices = g1Data.nVertices;
        edges = g1Data.edges
                |> Seq.map (fun ((a, b), wt) -> ((b, a), wt))
    }

    // Rosetta Code, Dijkstra's algorithm
    let g3Data = {
        nVertices = 6;
        edges =
        [
            ((0, 1), 7.);
            ((0, 2), 9.);
            ((0, 5), 14.);
            ((1, 2), 10.);
            ((1, 3), 15.);
            ((2, 3), 11.);
            ((2, 5), 2.);
            ((3, 4), 6.);
            ((4, 5), 9.);
        ]
    }

    // TODO: More test cases, esp. graphs with negative edges.
    let gData = [g0Data; g1Data; g2Data; g3Data]

    for (i, g) in Seq.indexed gData do
        if not <| testShortestPaths i g then
            failwith <| sprintf "Graph %d inconsistent results\n" i

    0 // return an integer exit code
