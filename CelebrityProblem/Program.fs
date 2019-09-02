open System

open CelebrityProblem

[<EntryPoint>]
let main argv =
    if Array.length argv <> 1 then
        failwith "Wrong number of arguments"
    let n = int(argv.[0])

    let knows = GenerateRandomGraph n
    let rnd = Random()
    let hasCelebrity = rnd.NextBool()
    let i =
        match hasCelebrity with
        | true ->
            let i = rnd.Next(n)
            do SetCelebrity knows i
            Some i
        | false ->
            None

    let cel = FindCelebrity knows
    if n <= 25 then
        let knows01 = Array2D.map (fun x -> if x then 1 else 0) knows
        printfn "\nAdjacency matrix =\n%A\n\nCelebrity = %A" knows01 cel

    if hasCelebrity then
        match cel with
        | Some cel when cel = Option.get i ->
            ()
        | _ ->
            failwith "The celebrity is present but cannot find her"

    match cel with
    | Some cel ->
        if not <| CheckCelebrity knows cel then
            failwith "Found the wrong person"
    | _ -> ()

    0 // return an integer exit code
