
let naiveSearch (w: string) (radius: int) (candidates: seq<string>) : seq<int * string> =
  candidates
  |> Seq.map (fun c -> (BKTree.levenshtein w c, c))
  |> Seq.filter (fun (d, c) -> d <= radius)

let mutable testID = 0

let testBKTree (w: string) (r: int) (dict: seq<string>) =
  let t = BKTree.ofSeq dict
  let expected = Seq.toList (naiveSearch w r dict)
  let res = Seq.toList (BKTree.search w r t)
  if List.length res <> List.length expected || set res <> set expected  then
    failwithf "Test %d failed" testID
  else
    printfn "(#%d) %A" testID res
  testID <- testID + 1

[<EntryPoint>]
let main argv =
  testBKTree "sort" 2 <| seq {
    "some";
    "soft";
    "same";
    "mole";
    "soda";
    "salmon";
  }

  testBKTree "fuck" 1 <| seq {
    "f*ck";
    "fvck";
    "fsck";
    "fcuk";
    "fork";
  }

  let dict = seq {
    "hell";
    "help";
    "shel";
    "smell";
    "fell";
    "felt";
    "oops";
    "pop";
    "oouch";
    "halt";
  }

  testBKTree "ops" 2 dict
  testBKTree "helt" 2 dict

  0 // return an integer exit code
