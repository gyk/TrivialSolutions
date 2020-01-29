module Tests

open Xunit
open FsUnit.Xunit

open ACAutomata

let checkAC (vocab: string list) (word: string) (found: (int * string) list) : bool =
    let ac = buildAutomaton vocab
    let s1 = set <| search word ac
    let s2 = set found
    s1 = s2

[<Fact>]
let Test1 () =
    checkAC
        ["a"; "ab"; "bab"; "bc"; "bca"; "c"; "caa"]
        "abccab"
        [(0, "a"); (1, "ab"); (2, "bc"); (2, "c"); (3, "c"); (4, "a"); (5, "ab")]
    |> should be True

[<Fact>]
let Test2 () =
    checkAC
        ["bar"; "ara"; "bara"; "barbara"]
        "barbarian barbara said: barabum"
        [(2, "bar"); (5, "bar"); (12, "bar"); (15, "bar"); (16, "barbara"); (16, "bara");
         (16, "ara"); (26, "bar"); (27, "bara"); (27, "ara")]
    |> should be True

[<Fact>]
let Test3 () =
    checkAC
        ["he"; "she"; "hers"; "his"]
        "ahishers"
        [(3, "his"); (5, "she"); (5, "he"); (7, "hers")]
    |> should be True
