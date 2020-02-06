open System
open ThreeColoringBinaryTree

[<EntryPoint>]
let main argv =
    let line = Console.ReadLine()
    if not <| isNull line then
        printfn "%d" <| countGreenColoringStr line
    0
