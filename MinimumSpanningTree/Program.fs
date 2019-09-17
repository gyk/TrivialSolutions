open Graph
open MinimumSpanningTree

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

let testMst (testId: int) (gData: GraphData): bool =
    let gMat = gData.ToGraphMat()
    printfn "\n\nGraph %d (Matrix)\n========\n" testId
    printfn "The adjacency matrix = \n%A\n" <| Array2D.map (Option.defaultValue nan) gMat.AdjMatrix
    let gMstMat = mstPrimMat gMat
    printfn "MST by Prim = \n%A\n" gMstMat

    let gList = gData.ToGraphList()
    printfn "\n\nGraph %d (List)\n========\n" testId
    printfn "The adjacency list = \n%A\n" <| gList.AdjList
    let gMstList = mstPrimList gList
    printfn "MST by Prim = \n%A\n" gMstList

    printfn "Tree length = %f\n" <| treeLength gMstMat

    seq [
        gMstList
        mstKruskal gMat
        mstKruskal gList
        mstBoruvka gMat
        mstBoruvka gList
    ]
    |> Seq.forall ((=) gMstMat)

[<EntryPoint>]
let main argv =
    // Trivial
    let g0Data = {
        nVertices = 1;
        edges = []
    }

    // Sedgewick's book, Fig. 20.1
    let g1Data = {
        nVertices = 8;
        edges =
        [
            ((0, 1), 0.32);
            ((0, 2), 0.29);
            ((0, 5), 0.60);
            ((0, 6), 0.51);
            ((0, 7), 0.31);
            ((1, 7), 0.21);
            ((3, 4), 0.34);
            ((3, 5), 0.18);
            ((4, 5), 0.40);
            ((4, 6), 0.51);
            ((4, 7), 0.46);
            ((6, 7), 0.25);
        ]
    }

    // Wikipedia, Borůvka's algorithm
    let g2Data = {
        nVertices = 7;
        edges =
        [
            ((0, 1), 7.);
            ((0, 3), 4.);
            ((1, 2), 11.);
            ((1, 3), 9.);
            ((1, 4), 10.);
            ((2, 4), 5.);
            ((3, 4), 15.);
            ((3, 5), 6.);
            ((4, 5), 12.);
            ((4, 6), 8.);
            ((5, 6), 13.);
        ]
    }

    // Wikipedia, Minimum spanning tree
    let g3Data = {
        nVertices = 6;
        edges =
        [
            ((0, 1), 1.0);
            ((0, 3), 3.0);
            ((1, 2), 6.0);
            ((1, 3), 5.0);
            ((1, 4), 1.0);
            ((2, 4), 5.0);
            ((2, 5), 2.0);
            ((3, 4), 1.0);
            ((4, 5), 4.0);
        ]
    }

    let gData = [g0Data; g1Data; g2Data; g3Data]

    for (i, g) in Seq.indexed gData do
        if not <| testMst i g then
            failwith <| sprintf "Graph %d inconsistent results\n" i

    // TODO: Add some real unit tests.
    // TODO: Test edge (no pun intended) cases: self loop, trivial graph, etc.
    // TODO: Maybe do some fun stuff like maze generation.

    0 // exit code
