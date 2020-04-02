// # Max Flow in F#
//
// ## References
//
// - Algorithms in C, Robert Sedgewick, Chapter 22.
// - https://oi-wiki.org/graph/flow/max-flow/

module MaxFlow
    open System.Collections.Generic

    open InfInt
    open Graph

    let private bfsEdmondsKarp (g: GraphList) (s: int) (t: int) : (int option [] * InfInt) option =
        let q = Queue<int * InfInt>()
        q.Enqueue((s, Infinite))
        let parents: int option [] = Array.init ((g :> IGraph).NumVertices) (fun _ -> None)
        parents.[s] <- Some s

        let mutable flow = None
        while Option.isNone flow && q.Count > 0 do
            let (head, f) = q.Dequeue()
            for KeyValue(n, e) in g.AdjList.[head] do
                if Option.isNone parents.[n] && e.Residual > Finite 0 then
                    parents.[n] <- Some head
                    let f = min f e.Residual
                    q.Enqueue((n, f))
                    if n = t then
                        flow <- Some f

        Option.map (fun f -> (parents, f)) flow

    let EdmondsKarp (g: GraphList) (s: int) (t: int) : InfInt =
        let rec go flow =
            match bfsEdmondsKarp g s t with
            | Some (parents, df) ->
                let mutable x = t
                while x <> s do
                    let p = Option.get parents.[x]
                    g.AdjList.[p].[x].Increase(df)
                    g.AdjList.[x].[p].Increase(-df)
                    x <- p
                go (flow + df)
            | None -> flow
        go (Finite 0)

    let private bfsDinic (g: GraphList) (s: int) : int option [] =
        let q = Queue<int>()
        q.Enqueue(s)
        let d: int option [] = Array.init ((g :> IGraph).NumVertices) (fun _ -> None)
        d.[s] <- Some 0

        while q.Count > 0 do
            let head = q.Dequeue()
            for KeyValue(n, e) in g.AdjList.[head] do
                if Option.isNone d.[n] && e.Residual > Finite 0 then
                    d.[n] <- Option.map (fun x -> x + 1) d.[head]
                    q.Enqueue(n)
        d

    let Dinic (g: GraphList) (s: int) (t: int) : InfInt =
        let rec dfs (levelG: int option []) (x: int) (flowCap: InfInt) : InfInt =
            if x = t || flowCap = Finite 0 then
                flowCap
            else
                let mutable flow = Finite 0
                let mutable flowCap = flowCap
                for KeyValue(n, e) in g.AdjList.[x] do
                    match (levelG.[x], levelG.[n]) with
                    | (Some dx, Some dn) when dx + 1 = dn ->
                        let f = dfs levelG n (min flowCap e.Residual)
                        e.Increase(f)
                        g.AdjList.[n].[x].Increase(-f)
                        flow <- flow + f
                        flowCap <- flowCap - f
                    | _ -> ()
                flow

        let rec go flow =
            let levelGraph = bfsDinic g s
            match levelGraph.[t] with
            | Some _ ->
                let df = dfs levelGraph s Infinite
                go (flow + df)
            | None -> flow

        if s = t then
            Finite 0
        else
            go (Finite 0)
