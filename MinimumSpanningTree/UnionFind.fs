module UnionFind

// Weighted quick-find algorithm
type UnionFind(n: int) =
    // Prefix 's' indicates it's a disjoint **s**et
    let sId: int [] = Array.init n id
    let sSize: int [] = Array.zeroCreate n

    let rec find: int -> int =
        function
        | x when sId.[x] <> x ->
            sId.[x] <- sId.[sId.[x]]  // path compression, (!) impure
            find sId.[x]
        | x -> x

    member this.Find (x: int) : int =
        find x

    member this.IsConnected (p: int) (q: int) : bool =
        find p = find q

    member this.Union (p: int) (q: int) =
        let p = find p
        let q = find q

        if p <> q then
            match (sSize.[p] >= sSize.[q], (p, q)) with
            | (true, (p, q))
            | (false, (q, p)) ->
                sId.[q] <- p
                sSize.[p] <- sSize.[p] + sSize.[q]
