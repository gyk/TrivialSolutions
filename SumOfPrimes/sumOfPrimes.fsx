(**

From Lucy_Hedgehog's post on Project Euler forum about Problem 10:

> Let $S(v,p)$ be the sum of integers in the range $2$ to $v$ that remain after sieving with all
primes smaller than or equal to $p$. That is $S(v, p)$ is the sum of integers up to $v$ that are
either prime or the product of primes larger than $p$.

> $S(v, p)$ is equal to $S(v, p-1)$ if $p$ is not prime or $v$ is smaller than $p^2$. Otherwise ($p$
prime, $p^2 \leq v)\quad  S(v,p)$ can be computed from $S(v, p-1)$ by finding the sum of integers
that are removed while sieving with $p$. An integer is removed in this step if it is the product of
$p$ with another integer that has no divisor smaller than $p$. This can be expressed as

> $S(v, p) = S(v, p-1) - p (S(\lfloor v/p \rfloor, p-1) - S(p-1, p-1))$

**)

open System
open System.Collections.Generic

let sumOfPrimes (n: int64) =
    let r = n |> float |> Math.Sqrt |> int64

    let v =
        let v = [| for i in 1L .. r -> n / i |]
        Array.append v [| for i in (Array.last v - 1L) .. -1L .. 1L -> i |]

    let s = new Dictionary<int64, int64>()
    for i in v do
        s.[i] <- (1L + i) * i / 2L - 1L

    for p in 2L..r do
        if s.[p] > s.[p - 1L] then // p is prime
            let sp = s.[p - 1L]
            let p2 = p * p
            for i in Seq.takeWhile (fun i -> i >= p2) v do
                s.[i] <- s.[i] - p * (s.[i / p] - sp)

    s.[n]

printfn "%i" (sumOfPrimes 1000000000L)
