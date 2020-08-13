module Tests

open Xunit
open FsUnit.Xunit

open TopologicalSort.TopologicalSort

let buildGraph (edges: seq<(int * int)>) : Graph =
  edges |> Seq.fold (fun g pair -> addEdge pair g) Map.empty

let checkTopoSort (g: Graph) : bool =
  let checkOrdering (ord: Vertex list) : bool =
    let m = Map.ofSeq <| Seq.zip ord (Seq.initInfinite id)
    seq { for KeyValue(fromV, toVSet) in g do for toV in toVSet -> m.[fromV] > m.[toV] }
    |> Seq.exists id
    |> not

  match (sortKahn g, sortDfs g) with
  | (Cyclic, Cyclic) -> true  // It still passes if both were wrong :(
  | (Order ord1, Order ord2) -> checkOrdering ord1 && checkOrdering ord2
  | _ -> false


[<Fact>]
let Test1 () =
  (&&)
    (buildGraph [|(0, 1)|] |> checkTopoSort)
    (buildGraph [|(1, 0)|] |> checkTopoSort)
  |> should be True

[<Fact>]
let Test2 () =
  buildGraph [|(0, 1); (1, 0)|]
  |> checkTopoSort
  |> should be True

[<Fact>]
let Test3 () =
  buildGraph [|(1, 0); (2, 0); (3, 1); (3, 2)|]
  |> checkTopoSort
  |> should be True

[<Fact>]
let Test4 () =
  //  6 -> 4 -> 2
  //  5 -> 3 -> 2 -> 1
  //  7 -> 3
  buildGraph [|(2, 1); (3, 2); (4, 2); (5, 3); (6, 4); (7, 3)|]
  |> checkTopoSort
  |> should be True

[<Fact>]
let Test5 () =
  // Test4 + [1 -> 6]
  buildGraph [|(2, 1); (3, 2); (4, 2); (5, 3); (6, 4); (7, 3); (1, 6)|]
  |> checkTopoSort
  |> should be True

[<Fact>]
let Test6 () =
  //  From https://en.wikipedia.org/wiki/Topological_sorting
  buildGraph [|
    (5, 11)
    (7, 11)
    (7, 8)
    (3, 8)
    (3, 10)
    (11, 2)
    (11, 9)
    (11, 10)
    (8, 9)
  |]
  |> checkTopoSort
  |> should be True

[<Fact>]
let Test7 () =
  // From GeeksforGeeks
  buildGraph [|(5, 0); (5, 2); (2, 3); (4, 0); (4, 1); (1, 3)|]
  |> checkTopoSort
  |> should be True
