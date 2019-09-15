open Graph
open MinimumSpanningTree

[<EntryPoint>]
let main argv =
    // Sedgewick's book, Fig. 20.1
    let g1Data = [
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

    let g1Mat = GraphMat(8)
    for d in g1Data do
        d ||> (g1Mat :> IGraph).AddEdge

    printfn "\n\nGraph 1 (Matrix)\n========\n"
    printfn "The adjacency matrix = \n%A\n" <| Array2D.map (Option.defaultValue nan) g1Mat.AdjMatrix
    let g1MstMat = mstPrimMat g1Mat
    printfn "MST by Prim = \n%A\n" g1MstMat

    let g1List = GraphList(8)
    for d in g1Data do
        d ||> (g1List :> IGraph).AddEdge

    printfn "\n\nGraph 1 (List)\n========\n"
    printfn "The adjacency list = \n%A\n" <| g1List.AdjList
    let g1MstList = mstPrimList g1List
    printfn "MST by Prim = \n%A\n" g1MstList

    if g1MstMat <> g1MstList ||
       g1MstMat <> mstKruskal g1Mat ||
       g1MstList <> mstKruskal g1List
    then failwith "Graph 1 inconsistent results"

    // From Wikipedia MST
    let g2Data = [
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

    let g2Mat = GraphMat(6)
    for d in g2Data do
        d ||> (g2Mat :> IGraph).AddEdge

    printfn "\n\nGraph 2 (Matrix)\n========\n"
    let g2MstLenMat = treeLength (mstPrimMat g2Mat)
    printfn "MST length = %f\n" g2MstLenMat

    let g2List = GraphList(6)
    for d in g2Data do
        d ||> (g2List :> IGraph).AddEdge

    printfn "\n\nGraph 2 (List)\n========\n"
    let g2MstLenList = treeLength (mstPrimList g2List)
    printfn "MST length = %f\n" g2MstLenList

    if g2MstLenMat <> g2MstLenList ||
       g2MstLenMat <> treeLength (mstKruskal g2Mat) ||
       g2MstLenMat <> treeLength (mstKruskal g2List)
    then failwith "Graph 2 inconsistent results"

    // TODO: Add some real unit tests.
    // TODO: Test edge (no pun intended) cases: self loop, trivial graph, etc.
    // TODO: Maybe do some fun stuff like maze generation.

    0 // exit code
