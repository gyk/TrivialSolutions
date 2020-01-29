/// Aho-Corasick algorithm
module ACAutomata

// A better purely functional implementaion in Haskell:
// <https://github.com/dzchoi/Aho-Corasick-algorithm-in-Haskell/>

open FSharpx.Collections

type State = int
type StateVec = PersistentVector<Map<char, State>>

let root: State = 0
let rootMap: StateVec = PersistentVector.singleton Map.empty

type ACAutomaton =
    { gotoMap: StateVec
      failureMap: Map<State, State>
      outputMap: Map<State, string> }

let private addWord (m: StateVec) (word: char list) : (StateVec * State) =
    let rec go (m: StateVec) s w =
        match w with
        | [] -> (m, s)
        | (c :: cs) ->
            match Map.tryFind c (m.[s]) with
            | Some s' -> go m s' cs
            | None ->
                let s' = PersistentVector.length m
                let m = PersistentVector.update s (Map.add c s' m.[s]) m
                let m = PersistentVector.conj Map.empty m
                go m s' cs
    go m root word

let private buildGotoOutputMap (words: seq<string>) : (StateVec * Map<State, string>) =
    let gm = rootMap
    let om = Map.empty
    ((gm, om), words)
    ||> Seq.fold (fun (gm, om) w ->
        let (gm, s) = addWord gm <| List.ofSeq w
        let om = Map.add s w om
        (gm, om)
    )

let private buildFailureMap (gotoMap: StateVec) : Map<State, State> =
    let rec findSuffix (failureMap: Map<State, State>)
                       (parentSuffix: State option)
                       (ch: char)
                       : State =
        match parentSuffix with
        | None -> root
        | Some p ->
            match Map.tryFind ch gotoMap.[p] with
            | Some x -> x
            | None -> findSuffix failureMap (Map.tryFind p failureMap) ch

    let rec go (queue: Queue<State>) (failureMap: Map<State, State>) : Map<State, State> =
        if Queue.isEmpty queue then
            failureMap
        else
            let head = Queue.head queue
            let tail = Queue.tail queue
            let (tail, failureMap) =
                ((tail, failureMap), seq { for KeyValue(ch, s) in gotoMap.[head] -> (head, ch, s) })
                ||> Seq.fold (fun (q, fm) (sFrom, ch, sTo) ->
                        let sSuffix = findSuffix fm (Map.tryFind sFrom fm) ch
                        (Queue.conj sTo q, Map.add sTo sSuffix fm)
                    )
            go tail failureMap

    let q = Queue.ofList([root])
    go q Map.empty

let private outputAll (ac: ACAutomaton) (s: State) : string list =
    let rec go s acc =
        if s = root then
            acc
        else
            let acc' =
                match Map.tryFind s ac.outputMap with
                | Some o -> o::acc
                | None -> acc
            let s' = Option.defaultValue root <| Map.tryFind s ac.failureMap
            go s' acc'
    go s List.empty

let buildAutomaton (words: seq<string>) : ACAutomaton =
    let (gm, om) = buildGotoOutputMap words
    let fm = buildFailureMap gm
    { gotoMap = gm
      failureMap = fm
      outputMap = om }

let drawAutomaton (ac: ACAutomaton) =
    printfn "digraph D {"
    for (sBegin, m) in Seq.indexed ac.gotoMap do
        for KeyValue(ch, sEnd) in m do
            printfn "  %d -> %d [label=\"%c\"]" sBegin sEnd ch
    printfn ""
    for KeyValue(sBegin, sEnd) in ac.failureMap do
        printfn "  %d -> %d [color=blue, style=dashed]" sBegin sEnd
    printfn ""
    for KeyValue(s, _) in ac.outputMap do
        printfn "  %d [shape=doublecircle]" s
    printfn "}"

let search (text: string) (ac: ACAutomaton) : (int * string) list =
    let rec go (s: State)
               (w: (int * char) list)
               (acc: (int * string) list)
               : (int * string) list =
        match w with
        | [] -> List.rev acc
        | ((i, c)::w') ->
            match Map.tryFind c ac.gotoMap.[s] with
            | Some s' ->
                let acc' = (List.map (fun x -> (i, x)) <| outputAll ac s') @ acc
                go s' w' acc'
            | None ->
                match Map.tryFind s ac.failureMap with
                | Some s' -> go s' w acc
                | None ->
                    if s = root then
                        go root w' acc
                    else
                        go root w acc

    let text = List.ofSeq <| Seq.indexed text
    go root text List.empty
