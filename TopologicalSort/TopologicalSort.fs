namespace TopologicalSort

type Vertex = int
type Graph = Map<Vertex, Set<Vertex>>
type TopSortResult = Cyclic | Order of Vertex list

module TopologicalSort =
  let find k m =
    match Map.tryFind k m with
    | Some v -> v
    | None -> Set.empty

  let update x f (g: Graph) =
    let s = find x g |> f
    if Set.isEmpty s then Map.remove x g else Map.add x s g

  let addEdge ((n0, n1): Vertex * Vertex) (g: Graph) : Graph =
    update n0 (Set.add n1) g

  let nodeSet (g: Graph) : Set<Vertex> =
    g |> Map.toSeq |> Seq.map fst |> Set.ofSeq

  let inverse (ins: Graph) : Graph =
    let mutable outs = Map.empty
    Map.iter (fun n0 n1s ->
      Set.iter (fun n1 -> outs <- addEdge (n1, n0) outs) n1s) ins
    outs

  /// Topological sort using Kahn's algorithm.
  ///
  /// - https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm
  /// - https://github.com/fsharp/fsharp/blob/master/tests/perf/MapSet/MapSet/TopologicalSort.fs
  let sortKahn (g: Graph): TopSortResult =
    let rec kahn (acc: Vertex list) (ins: Graph, outs: Graph, s: Set<Vertex>) : TopSortResult =
      if Set.isEmpty s then
        if Map.isEmpty outs then Order(List.rev acc) else Cyclic
      else
        // Pops one node from the set.
        let n = Set.minElement s
        let s' = Set.remove n s

        Set.fold (fun (ins, outs, s) m ->
          let ins = update m (Set.remove n) ins
          ( ins
          , update n (Set.remove m) outs
          , if Map.containsKey m ins then s else Set.add m s)
        ) (ins, outs, s') (find n outs)
        |> kahn (n :: acc)

    let outs = g
    let ins = inverse g
    let roots = Map.fold (fun s k _ -> Set.remove k s) (nodeSet outs) ins
    kahn [] (ins, outs, roots)

  /// Topological sort based on DFS.
  ///
  /// - https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search
  let sortDfs (g: Graph): TopSortResult =
    let mutable acc = []
    let mutable unvisited = Set.union (nodeSet g) (nodeSet <| inverse g)
    let mutable visiting = Set.empty
    let mutable cycleDetected = false

    let rec visit (n: Vertex) =
      if not cycleDetected && Set.contains n unvisited then
          if Set.contains n visiting then
            cycleDetected <- true
          else
            visiting <- Set.add n visiting
            for m in find n g do
              visit m
            unvisited <- Set.remove n unvisited
            acc <- n::acc

    let rec dfs () : TopSortResult =
      if Set.isEmpty unvisited then
        Order(acc)
      else
        let n = Set.minElement unvisited
        visit n
        if cycleDetected then
          Cyclic
        else
          dfs ()
    dfs ()

  let smokeTest () =
    //  6 -> 4 -> 2
    //  5 -> 3 -> 2 -> 1
    //  7 -> 3
    let g = [|(2, 1); (3, 2); (4, 2); (5, 3); (6, 4); (7, 3)|]
         |> Array.fold (fun g pair -> addEdge pair g) Map.empty
    printfn "%A" <| sortKahn g
    printfn "%A" <| sortDfs g

    let g = addEdge (1, 6) g
    printfn "%A" <| sortKahn g
    printfn "%A" <| sortDfs g

    // My code has passed exactly one test. I guess it's mature enough to publish on GitHub.
