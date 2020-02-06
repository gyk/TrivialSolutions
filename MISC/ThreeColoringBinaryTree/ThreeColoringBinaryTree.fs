// THREECOL - Three-coloring of binary trees (https://www.spoj.com/problems/THREECOL/)
//
// (Code has yet been submitted.)

module ThreeColoringBinaryTree

open System.Collections.Generic

type private Node =
    | Nil
    | Branch of Node * int * Node

let private buildTree (s: seq<int>) : Node =
    let rec go (s: (int * int) list) : (Node * (int * int) list) =
        match s with
        | (i, c)::s' ->
            match c with
            | 0 -> (Branch (Nil, i, Nil), s')
            | 1 ->
                let (l, s') = go s'
                (Branch (l, i, Nil), s')
            | 2 ->
                let (l, s') = go s'
                let (r, s') = go s'
                (Branch (l, i, r), s')
            | x -> failwithf "Unknown #children %d" x
        | [] -> failwith "Unexpected EOF"
    s
    |> Seq.indexed
    |> List.ofSeq
    |> go
    |> fst

let private memoize f keyF =
    let cache = Dictionary<_, _>()
    let rec go x =
        match keyF x with
        | Some k ->
            match cache.TryGetValue(k) with
            | (true, v) -> v
            | _ ->
               let v = f go x
               cache.Add(k, v)
               v
        | None -> f go x
    go

let private countGreenColoring (tree: Node) : int =
    let getKey ((node, isGreen): Node * bool) =
        match node with
        | Nil -> None
        | Branch (_, i, _) -> Some (i, isGreen)

    let rec go goR ((tree, isGreen): Node * bool) : int =
        match tree with
        | Nil -> 0
        | Branch (l, _, r) ->
            if isGreen then
                1 + (goR (l, false)) + (goR (r, false))
            else
                max ((goR (l, false)) + (goR (r, true)))
                    ((goR (l, true)) + (goR (r, false)))

    let goM = memoize go getKey
    max (goM (tree, false)) (goM (tree, true))

let countGreenColoringStr (tree: string) : int =
    tree
    |> Seq.map (fun ch -> int ch - int '0')
    |> buildTree
    |> countGreenColoring
