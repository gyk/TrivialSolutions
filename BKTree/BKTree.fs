/// Burkhard-Keller Tree
module BKTree

let levenshtein (a: string) (b: string) : int =
  let (a, b) =
    if a.Length < b.Length then
      (b, a)
    else
      (a, b)

  let (na, nb) = (a.Length, b.Length)
  let d: int [][] = [| for _ in 0..1 -> [| 0 .. nb |] |]

  for r in 1 .. na do
    let (dThis, dLast) = (d.[r % 2], d.[(r - 1) % 2])
    dThis.[0] <- r
    for c in 1 .. nb do
      dThis.[c] <- Seq.min <| seq {
        dThis.[c - 1] + 1;
        dLast.[c] + 1;
        dLast.[c - 1] +
          if a.[r - 1] = b.[c - 1] then
            0
          else
            1
      }
  d.[na % 2].[nb]


type BKTree =
  | Leaf
  | Node of Node

and Node =
  { value: string;
    branch: Map<int, BKTree> }

let rec insert (x: string) (t: BKTree) : BKTree =
  match t with
  | Leaf ->
    Node { value = x;
           branch = Map.empty }
  | Node { value = r; branch = m } ->
    let d = levenshtein x r
    let branch' =
      match Map.tryFind d m with
      | Some tt -> Map.add d (insert x tt) m
      | None -> Map.add d (Node { value = x; branch = Map.empty }) m
    Node { value = r;
           branch = branch' }

let ofSeq (dict: seq<string>) : BKTree =
   Seq.fold (fun tree w -> insert w tree) Leaf dict

// Can also implement `delete` and `contains` if one feels bored.

/// Finds strings with an edit distance no larger than `radius`.
let rec search (x: string) (radius: int) (t: BKTree) : seq<int * string> =
  // By triangle inequality:
  //
  //     |d(x, root) - d(root, child)| <= d(x, child) <= radius
  match t with
  | Leaf -> Seq.empty
  | Node { value = r; branch = m } ->
    let dXR = levenshtein x r
    let s =
      if dXR <= radius then
        seq { (dXR, r) }
      else
        Seq.empty
    Map.fold
      (fun s dRC tt ->
        if abs (dXR - dRC) > radius then
          s
        else
          Seq.append s <| search x radius tt)
      s
      m
