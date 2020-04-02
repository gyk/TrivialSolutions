open InfInt
open Graph
open MaxFlow

let private fromInt (cap: int) : InfInt =
    if cap < 0 then
        Infinite
    else
        Finite cap

type GraphData =
    { nVertices: int
      edges: seq<(int * int) * int>
      source: int
      sink: int
      expectedFlow: int option }

    member this.ToGraphMat () : GraphMat =
        let gMat = GraphMat(this.nVertices)
        for (fromTo, c) in this.edges do
            (gMat :> IGraph).AddEdge fromTo (fromInt c)
        gMat

    member this.ToGraphList () : GraphList =
        let gList = GraphList(this.nVertices)
        for (fromTo, c) in this.edges do
            (gList :> IGraph).AddEdge fromTo (fromInt c)
        gList

let testMaxFlow (testId: int) (gData: GraphData) : bool =
    let gList = gData.ToGraphList()
    printfn "\n\nGraph %d\n========\n" testId
    let flowEdmondsKarp = EdmondsKarp gList gData.source gData.sink
    printfn "Max flow (Edmonds Karp) = %A\n" flowEdmondsKarp
    (gList :> IGraph).Reset()
    let flowDinic = Dinic gList gData.source gData.sink
    printfn "Max flow (Edmonds Karp) = %A\n" flowDinic

    gData.expectedFlow
    |> Option.map (fun f ->
        let f = fromInt f
        f = flowEdmondsKarp && f = flowDinic)
    |> Option.defaultValue true

[<EntryPoint>]
let main argv =
    // Trivial
    let g0Data = {
        nVertices = 1
        edges = []
        source = 0
        sink = 0
        expectedFlow = None
    }

    // Sedgewick's book, Fig. 22.5
    let g1Data = {
        nVertices = 6
        edges = [
            ((0, 1), 2)
            ((0, 2), 3)
            ((1, 3), 3)
            ((1, 4), 1)
            ((2, 3), 1)
            ((2, 4), 1)
            ((3, 5), 2)
            ((4, 5), 3)
        ]
        source = 0
        sink = 5
        expectedFlow = Some 4
    }

    // The example from https://en.wikipedia.org/wiki/Edmonds–Karp_algorithm
    let g2Data = {
        nVertices = 7
        edges = [
            ((0, 1), 3)
            ((0, 3), 3)
            ((1, 2), 4)
            ((2, 0), 3)
            ((2, 3), 1)
            ((2, 4), 2)
            ((3, 4), 2)
            ((3, 5), 6)
            ((4, 1), 1)
            ((4, 6), 1)
            ((5, 6), 9)
        ]
        source = 0
        sink = 6
        expectedFlow = Some 5
    }

    // Introduction to Algorithms, 3rd edition, Figure 26.1
    let g3Data = {
        nVertices = 6
        edges = [
            ((0, 1), 16)
            ((0, 2), 13)
            ((1, 2), 10)
            ((1, 3), 12)
            ((2, 1), 4)
            ((2, 4), 14)
            ((3, 2), 9)
            ((3, 5), 20)
            ((4, 3), 7)
            ((4, 5), 4)
        ]
        source = 0
        sink = 5
        expectedFlow = Some 23
    }

    // Wikipedia, Dinic's algorithm
    let g4Data = {
        nVertices = 6
        edges = [
            ((0, 1), 10)
            ((0, 2), 10)
            ((1, 2), 2)
            ((1, 3), 4)
            ((1, 4), 8)
            ((2, 4), 9)
            ((3, 5), 10)
            ((4, 5), 10)
        ]
        source = 0
        sink = 5
        expectedFlow = Some 14
    }

    // https://en.wikipedia.org/wiki/Max-flow_min-cut_theorem#Project_selection_problem
    let g5Data = {
        nVertices = 8
        edges = [
            ((0, 1), 100)
            ((0, 2), 200)
            ((0, 3), 150)
            ((1, 4), -1)
            ((1, 5), -1)
            ((2, 5), -1)
            ((3, 6), -1)
            ((4, 7), 200)
            ((5, 7), 100)
            ((6, 7), 50)
        ]
        source = 0
        sink = 7
        expectedFlow = Some 250
    }

    let gData = [g0Data; g1Data; g2Data; g3Data; g4Data; g5Data]

    for (i, g) in Seq.indexed gData do
        if not <| testMaxFlow i g then
            failwith "The max flow test failed"

    0 // return an integer exit code
