# Magic Square Generator
# ======================
#
# # Reference
#
# - Moler, Cleve B. Experiments with MATLAB. Society for Industrial and Applied Mathematics, 2011.

# The JuliaLang community is famous for naming their functions as something like
# `verylongfunctionnamethatistotallyunreadable` and abusing unicode characters all over the source.
# A more appropriate name for this is probably `is🎩`, but let's stick with the old style for now.
function is_magic(m::AbstractMatrix{<:Integer})
    n_r, n_c = size(m)
    # Is square?
    if n_r != n_c
        return false
    end

    n = n_r
    magic_const = (1 + n ^ 2) * n ÷ 2

    # Are all rows equal to magic constant?
    if !all(sum(m, dims=2) .== magic_const)
        return false
    end
    # Are all columns equal to magic constant?
    if !all(sum(m, dims=1) .== magic_const)
        return false
    end
    # And the two diagonals?
    if sum([m[i, i] for i in 1:n]) != magic_const
        return false
    end
    if sum([m[p...] for p in zip(1:n, n:-1:1)]) != magic_const
        return false
    end

    true
end

# Odd ordered magic square generator
#
# It is easy to see the correctness of this algorithm. For example, compare the elements in each
# column with the one to the northeast of itself, there are `n - 1` elements that are 1 less while
# exactly 1 that is `n - 1` larger, which makes the two columns add up to the same value.

"Generates a magic square of an odd order `n` using Siamese method (De la Loubère method)."
function odd_magic(n::Integer)
    @assert isodd(n)

    m = zeros(typeof(n), n, n)
    r, c = 1, div(n + 1, 2)

    for i in 1 : n*n
        m[r, c] = i

        # No need to do bounds checking, as only the last one will fall out of the board.
        p = r + 1, c
        r, c = mod1(r - 1, n), mod1(c + 1, n)
        if m[r, c] != 0
            r, c = p
        end
    end

    m
end

# A vectorized version of `odd_magic`.
function odd_magic_vec(n::Integer)
    @assert isodd(n)
    i = 1:n
    offset = div(n - 3, 2)
    A = @. mod(i + i' + offset, n)
    B = @. mod(i + i' * 2 - 2, n)
    @. n * A + B + 1
end

# TODO: Even ordered magic square generator
function singly_even_magic(n::Integer)
    error("unimplemented")
end

function doubly_even_magic(n::Integer)
    error("unimplemented")
end

function magic(n::Integer)
    if isodd(n)
        odd_magic(n)
    else
        half_n = div(n, 2)
        if isodd(half_n)
            singly_even_magic(n)
        else
            doubly_even_magic(n)
        end
    end
end

# Unit tests
using Test

@testset "Odd magic square tests" begin
    orders = 1:2:21
    for n in orders
        m = odd_magic(n)
        @test m == odd_magic_vec(n)
        @test is_magic(m)
    end
end
