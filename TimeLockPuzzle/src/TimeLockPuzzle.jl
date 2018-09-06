"""
Time-lock Puzzle
================

This module reimplements Ron Rivest's "LCS35 Time Capsule" given at the 35th birthday of MIT's
Laboratory for Computer Science.

# What are missing in the code:

1. Estimate wall time needed to crack the puzzle according to Moore's law ("The free lunch is over",
   anyway).
2. Error checking during computation.
3. Attach information that allows one to factor `n`.

# References

- LCS35 Time Capsule Crypto-Puzzle (http://people.csail.mit.edu/rivest/lcs35-puzzle-description.txt)
- Time-lock encryption (http://www.gwern.net/Self-decrypting-files)
"""
module TimeLockPuzzle

using Primes: nextprime

PRIME_LENGTH = 1024
TWO_POWER = big(1) << PRIME_LENGTH

# The `Puzzle` struct can be (de)serialized but the code is omitted here.
"The output of the generated puzzle"
struct Puzzle
    "The modulo"
    n::BigInt

    "The time (steps of computation) expected to crack the puzzle"
    t::BigInt

    "Encrypted secret message, encoded as `BigInt`"
    enc_message::BigInt
end

# The string encoding is UTF-8. For secret messages written in Eastern-asian languages, UTF-16 is
# preferred, but the Julia community discriminates against the poor UTF-16 and puts it into
# "LegacyStrings.jl".


# Steps to create the puzzle:
#
# 1. Encrypt message `M` with key `K` using a symmetric encryption algorithm
#
#         C_M = Encrypt(K, M)
#
# 2. Encrypt the key
#
#         C_K = K + a ^ (2^t)  (mod n)
#
#     By Euler's theorem, to compute this efficiently, one can first compute
#
#         e = 2 ^ t  (mod phi(n))
#
#     and then
#
#         b = a ^ e  (mod n)
#
# 3. The output of the puzzle is
#
#         (n, a, t, C_M, C_K)
#
# --------------------------------------------------------------------------------------------------
#
# The implementation is slightly different from the description in the paper. Here `a` is always 2,
# `C_K` is always 0, and the encrytion algorithm is just XOR. Therefore the actual output tuple is
# `(n, t, C_M)`.
function create_puzzle(p_seed::BigInt,
                       q_seed::BigInt,
                       t::BigInt,
                       secret::String)::Union{Puzzle, Nothing}
    @assert p_seed != q_seed "Two identical seeds"

    # 5 has maximal order modulo 2^k (Let's assume it's right).
    p = nextprime(powermod(big(5), p_seed, TWO_POWER))
    q = nextprime(powermod(big(5), q_seed, TWO_POWER))

    n = p * q
    # Euler's totient function
    phi = (p - 1) * (q - 1)

    # Generates the puzzle
    u = powermod(big(2), t, phi)
    w = powermod(big(2), u, n)

    secret_bytes = Vector{UInt8}(secret)
    secret_big = convert(BigInt, secret_bytes)
    if secret_big > n
        return nothing
    end

    enc_secret_big = xor(secret_big, w)
    Puzzle(n, t, enc_secret_big)
end

# The puzzle can be solved by performing t successive squarings modulo n, beginning with 2.
#
#     W(0) = 2
#     W(i+1) = W(i)^2  (mod n)    for i>0
#
# There is no known way to perform this more quickly without knowing the factorization of n.
function solve_puzzle(puzzle::Puzzle)::String
    t = puzzle.t
    n = puzzle.n

    k = big(2)
    for _i in 1:t
        k = (k * k) % n
    end

    dec_message = xor(puzzle.enc_message, k)
    String(convert(Vector{UInt8}, dec_message))
end

import Base: convert

"`BigInt` -> `Vector{UInt8}` conversion"
function convert(::Type{Vector{UInt8}}, x::BigInt)
    sz = div(ndigits(x, base=2) + 8 - 1, 8)
    bytes = UInt8[]
    sizehint!(bytes, sz)
    while x != 0
        push!(bytes, x & 255)
        x >>= 8
    end
    reverse!(bytes)
end

"`Vector{UInt8}` -> `BigInt` conversion"
function convert(::Type{BigInt}, v::Vector{UInt8})
    foldl((acc, b) -> (acc << 8) + b, v; init=big(0))
end

function run()
    t = big(1048576)  # A distant future
    maybe_puzzle = create_puzzle(big(17070415), big(17830918), t,
        "I have proven Euler's sum of powers conjecture.")  # Some nonsense
    if maybe_puzzle == nothing
        error("Cannot create the puzzle")
    end

    dec_msg = solve_puzzle(maybe_puzzle)
    println("The secret message is: \"$dec_msg\"")
end

end  # module
