"""
Bitap Algorithm (https://en.wikipedia.org/wiki/Bitap_algorithm)
"""
module Bitap

const CHAR_MAX = 256  # ASCII

function bitap_naive(s::AbstractVector{UInt8}, p::AbstractVector{UInt8})::Union{Int, Nothing}
    p_len = length(p)
    marker = falses(p_len)
    for (i, c) in enumerate(s)
        # WTH? No in-place `circshift!`?
        marker = circshift(marker, 1)
        marker[1] = true
        marker = @. (c == p) & marker
        if marker[p_len]
            return i + 1 - p_len
        end
    end
    nothing
end


const MSB1 = typemin(Int64)

# This implementation is terrible. Better to use the "counterintuitive" semantics for 0/1 as in the
# Wikipedia article.
"Returns the first matched index, or `nothing` if no match is found."
function bitap(s::AbstractVector{UInt8}, p::AbstractVector{UInt8})::Union{Int, Nothing}
    p_len = length(p)
    if p_len >= 64  # The MSBit is wasted
        error("The pattern is too long!")
    end
    pattern_masks = Int64[MSB1 for _ in 1:CHAR_MAX]
    m = MSB1
    for (i, c) in enumerate(p)
        pattern_masks[c] |= MSB1 >>> i
    end

    success = MSB1 >>> p_len
    for (i, c) in enumerate(s)
        m >>= 1  # arithmetic shift
        m &= pattern_masks[c]

        if m & success != 0
            return i + 1 - p_len
        end
    end
    nothing
end

const WORD_LEN = ndigits(~UInt(0), base=2)

function bitap_fuzzy_k_substitution(s::AbstractVector{UInt8},
                                    p::AbstractVector{UInt8},
                                    k::Int)::Union{Int, Nothing}
    p_len = length(p)
    if p_len > WORD_LEN
        error("The pattern is too long!")
    end
    pattern_masks = [~UInt(1) for _ in 1:CHAR_MAX]
    for (i, c) in enumerate(p)
        pattern_masks[c] &= ~(UInt(1) << (i - 1))
    end

    # `m[j]` becomes 0 after `j` time(s) character mismatch. So `m[k + 1]` can withstand `k`
    # substitutions.
    m = [~UInt(1) for _ in 1:(k + 1)]
    for (i, c) in enumerate(s)
        old_m = m[1]
        m[1] = (m[1] | pattern_masks[c]) << 1

        # propagates to larger indices
        for j in 2:(k + 1)
            tmp = m[j]
            m[j] = (old_m & (m[j] | pattern_masks[c])) << 1
            old_m = tmp
        end

        if m[k + 1] & (UInt(1) << p_len) == 0
            return i + 1 - p_len
        end
    end
    nothing
end

# Unit tests
using Test

s2b(s::String) = Vector{UInt8}(s)

@testset "Bitap" begin
    s = s2b("JavaScript")
    p = s2b("Java")
    @test bitap_naive(s, p) ==
          bitap(s, p) == 1

    s = s2b("Visual Basic")
    p = s2b("Basic")
    @test bitap_naive(s, p) ==
          bitap(s, p) == 8

    s = s2b("JavaScript")
    p = s2b("VBScript")
    @test bitap_naive(s, p) ==
          bitap(s, p) == nothing
end

@testset "Bitap - Fuzzy" begin
    s = s2b("Haystack")
    p = s2b("Haskell")
    @test bitap_fuzzy_k_substitution(s, p, 5) == 1
    @test bitap_fuzzy_k_substitution(s, p, 5 + 1) == 1
    @test bitap_fuzzy_k_substitution(s, p, 5 - 1) == nothing
end

# TODO: QuickCheck tests.

end # module
