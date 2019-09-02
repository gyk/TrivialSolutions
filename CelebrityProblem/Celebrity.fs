(*
    Introduction to Algorithms: A Creative Approach, 5.5 The Celebrity Problem.
*)

module CelebrityProblem
    open System

    type Random with
        member this.NextBool(): bool = this.NextDouble() > 0.5

    // .NET Core multi-dimensional arrays are faster than jagged arrays
    let GenerateRandomGraph (n: int): bool [,] =
        let rnd = Random()
        Array2D.init n n (fun _ _ -> rnd.NextBool())

    let checkArgs (a: bool [,]) (i: int) =
        let n = a.GetLength(0)
        if n <> a.GetLength(1) then
            invalidArg "a" "The adjacency matrix must be square"
        if i < 0 || i >= n then
            invalidArg "i" "Invalid index"

    let SetCelebrity (a: bool [,]) (i: int) =
        do checkArgs a i
        let n = Array2D.length1 a
        for r = 0 to (n - 1) do
            a.[r, i] <- true
        for c = 0 to (n - 1) do
            a.[i, c] <- false


    let CheckCelebrity (knows: bool [,]) (i: int): bool =
        do checkArgs knows i
        let crowdKnowsCelebrity () =
            let crowdKnowsCelebrity = knows.[*, i]
            crowdKnowsCelebrity.[i] <- true
            Array.forall id crowdKnowsCelebrity

        let celebrityNotKnowsCrowd () =
            let celebrityNotKnowsCrowd = knows.[i, *]
            celebrityNotKnowsCrowd.[i] <- false
            Array.forall not celebrityNotKnowsCrowd

        crowdKnowsCelebrity () && celebrityNotKnowsCrowd ()


    let FindCelebrity (knows: bool [,]): int option =
        do checkArgs knows 0

        let rec find (x: int option) (y: int option) (s: seq<int>): int option =
            match (x, y) with
            | (Some x, Some y) when knows.[x, y] ->
                find None (Some y) s
            | (Some x, Some y) when knows.[y, x] ->
                find (Some x) None s
            | (Some x, Some y) ->
                find None None s
            | (None, some) | (some, None) when Seq.isEmpty s ->
                some
            | (None, some) | (some, None) ->
                find (Some <| Seq.head s) some (Seq.tail s)

        let n = Array2D.length1 knows
        if n = 1 then
            None
        else
            let candi = find None None { 0 .. (n - 1) }
            match candi with
            | Some c when CheckCelebrity knows c -> candi
            | _ -> None
