"""
Gray Code Generator
===================

## References

- [knuth]: The Art of Computer Programming, Volume 4 Fascicle 2A, 7.2.1.1 Generating all n-tuples.
- [manber]: Introduction to Algorithms: A Creative Approach, 2.9 Gray Codes.
- [wiki]: https://en.wikipedia.org/wiki/Gray_code#Constructing_an_n-bit_Gray_code
"""
module GrayCode

# From [wiki]:
#
# "Once a binary number appears in $G_n$ it appears in the same position in all longer lists; so it
# makes sense to talk about the reflective Gray code value of a number."
#
# "These characteristics suggest a simple and fast method of translating a binary value into the
# corresponding Gray code. Each bit is inverted if the next higher bit of the input value is set to
# one."
#
# From [knuth]:
#
# "[R]eversing the order of Gray binary code is equivalent to complementing the fist bit."
#
# - - - -
#
# We have
#
#     g(i) = b(i) ⊕ b(i + 1)
#
# So g(i) of the MSbit is b(i) as b(i + 1) is 0. And for converting from Gray code to binary
# (c.f. https://math.stackexchange.com/a/1829662):
#
#     b(i) = g(i) ⊕ b(i + 1)
#
# or,
#
#     b(i) = g(i) ⊕ g(i + 1) ⊕ g(i + 2) ⊕ ...

#===== Gray code <-> Binary =====#

# b -> g  (n-th is 1-based)
"Computes the `n`-th reflective gray code."
function gray_nth(n::Integer)::Vector{Int8}
    @assert n > 0
    n -= 1
    g = xor(n, n >>> 1)
    digits(Int8, g, base=2)
end

# g -> b
function gray_to_binary(g::Vector{Int8})::Vector{Int8}
    b = copy(g)
    for i in (length(g) - 1):-1:1
        b[i] = xor(g[i], b[i + 1])
    end
    b
end

#===== Constructs Gray code by recursion =====#

# A slow implementation, just for proof-of-concept. See [manber].
function gray_codes_of_len(len::Integer)::Vector{Vector{Int8}}
    @assert iseven(len) "Gray code of odd length does not exist."
    @assert len > 0 "Length should be greater than 0."
    gray_codes_of_len_r(len)
end

function gray_codes_of_len_r(len::Integer)::Vector{Vector{Int8}}
    if len == 0
        return [[]]
    elseif len == 2
        g =
        [
            Int8[0],
            Int8[1],
        ]
        return g
    end

    if isodd(len)
        _2k = len - 1
        g_2k = gray_codes_of_len_r(_2k)
        if ispow2(_2k)
            g =
            [
                [[0; g] for g in g_2k]...,
                [1; g_2k[end]],
            ]
            return g
        else
            # There are some unused strings of length `ceil(log2(k * 2))`, one of which is connected
            # to one of the used strings.

            # Oops, this construction is useful for the proof but cannot be elegantly expressed as
            # code.
            len_pow2 = nextpow(2, _2k)
            g_pow2 = gray_codes_of_len_r(len_pow2)  # slow, fvck
            used = Set(g_2k)
            for (s, t) in [(i, mod1(i + 1, len_pow2)) for i in 1:len_pow2]
                if g_pow2[s] in used && !(g_pow2[t] in used)
                    index_2k = findfirst(x -> x == g_pow2[s], g_2k)
                    g =
                    [
                        g_2k[(index_2k + 1):end]
                        g_2k[1:index_2k]
                        [g_pow2[t]]
                    ]
                    return g
                end
            end
            error("Should not reach here.")
        end
    end

    half_len = div(len, 2)
    g_half = gray_codes_of_len_r(half_len)
    g_half_rev = reverse(g_half)

    [
        [[0; g] for g in g_half];
        [[1; g] for g in g_half_rev];
    ]
end

#===== Gray code iterating =====#

# c.f. [knuth] Algorithm G.
mutable struct GrayCodeIter
    n::Int
    code::Union{UInt128, Nothing}
    parity::Int8

    GrayCodeIter(n::Int) = new(n, 0, 0)
end

function Base.iterate(iter::GrayCodeIter, state=iter)
    if iter.code == nothing
        nothing
    else
        curr_code = iter.code
        iter.parity ⊻= 1
        if iter.parity == 1
            iter.code ⊻= 1
        elseif iter.code == 1 << (iter.n - 1)
            iter.code = nothing
        else
            iter.code ⊻= curr_code ⊻ (curr_code - 1) + 1
        end
        (curr_code, iter)
    end
end

Base.length(iter::GrayCodeIter) = UInt128(2) ^ iter.n

# TODO: [knuth] Fig. 14

#===== Unit Tests =====#
using Test
using Random: seed!

# Helpers for testing
function diff_one(a::Vector{T}, b::Vector{T})::Bool where T<:Integer
    len_diff = length(a) - length(b)
    if len_diff == 0
        return sum(xor.(a, b)) == 1
    elseif len_diff == 1
        # does nothing
    elseif len_diff == -1
        a, b = b, a
    else
        return false
    end

    a[end] == 1 && @view(a[1:(end - 1)]) == b
end

function binary_array_to_value(ba::Vector{Int8})::UInt64
    @assert length(ba) <= 64
    reduce((acc, x) -> (acc << 1) + x, @view ba[end:-1:1]; init=UInt64(0))
end

function check_grayness(gray_codes::Vector{Vector{Int8}})
    len = length(gray_codes)
    for i in 1:len
        @test diff_one(gray_codes[i], gray_codes[mod1(i + 1, len)])
    end
    @test length(unique(map(binary_array_to_value, gray_codes))) == len
end

@testset "N-th Gray code" begin
    seed!()
    N = 2^16
    for _ in 1:100
        n = rand(1:N)
        n_minus1 = mod1(n - 1, N)
        n_plus1 = mod1(n + 1, N)
        g = gray_nth(n)
        g_minus1 = gray_nth(n_minus1)
        g_plus1 = gray_nth(n_plus1)
        @test diff_one(g_minus1, g)
        @test diff_one(g, g_plus1)

        b = gray_to_binary(g)
        nb = binary_array_to_value(b) + 1
        @test n == nb
    end
end

@testset "Gray code of given length" begin
    for len in 2:2:64
        gray_codes = gray_codes_of_len(len)
        check_grayness(gray_codes)
    end
end

@testset "Gray code - Chinese ring puzzle" begin
    for n in 2:8
        gc_gen = GrayCodeIter(n)
        gray_codes = [digits(Int8, g, base=2, pad=n) for g in gc_gen]
        check_grayness(gray_codes)
    end
end
end  # module
