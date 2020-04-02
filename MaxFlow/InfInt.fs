module InfInt

open System

[<CustomComparison; CustomEquality>]
type InfInt =
    | Infinite
    | Finite of int
    | NegInf

    static member (+) (x1: InfInt, x2: InfInt) : InfInt =
        match (x1, x2) with
        | (Finite i1, Finite i2) -> Finite (i1 + i2)

        | (Infinite, NegInf)
        | (NegInf, Infinite) -> failwith "NaN"

        | (Infinite, _)
        | (_, Infinite) -> Infinite

        | (NegInf, _)
        | (_, NegInf) -> NegInf


    static member (-) (x1: InfInt, x2: InfInt) : InfInt =
        match (x1, x2) with
        | (Finite i1, Finite i2) -> Finite (i1 - i2)

        | (Infinite, Infinite)
        | (NegInf, NegInf) -> failwith "NaN"

        | (Infinite, _) -> Infinite
        | (_, Infinite) -> NegInf

        | (NegInf, _) -> NegInf
        | (_, NegInf) -> Infinite


    static member (~-) (x: InfInt) =
        match x with
        | Infinite -> NegInf
        | NegInf -> Infinite
        | Finite i -> Finite (-i)

    interface IComparable<InfInt> with
        member this.CompareTo that =
            match (this, that) with
            | (Finite i1, Finite i2) -> compare i1 i2

            | (Infinite, Infinite) -> 0
            | (NegInf, NegInf) -> 0

            | (Infinite, _) -> 1
            | (_, Infinite) -> -1

            | (NegInf, _) -> -1
            | (_, NegInf) -> 1


    interface IComparable with
        member this.CompareTo obj =
            match obj with
            | null                -> 1
            | :? InfInt as that -> (this :> IComparable<_>).CompareTo that
            | _                   -> invalidArg "obj" "Cannot be compared"

    override this.Equals obj =
        match obj with
        | :? InfInt as that -> (this :> IComparable<_>).CompareTo that = 0
        | _                   -> false

    override this.GetHashCode() =
        let x = match this with
                | Finite i -> i
                | Infinite -> Int32.MaxValue
                | NegInf -> Int32.MinValue
        x.GetHashCode()

    override this.ToString() =
        match this with
        | Infinite -> "Inf"
        | NegInf -> "-Inf"
        | Finite x -> x.ToString()

    member this.ToOption () : int option =
        match this with
        | Finite i -> Some i
        | _ -> None

    static member op_Explicit x =
        match x with
        | Finite i -> i
        | _ -> failwith "Try to convert infinite value to integer"
