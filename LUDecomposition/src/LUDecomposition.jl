"LU Decomposition"
module LUDecomposition

using LinearAlgebra: dot

function get_n(A::Matrix)::Int
    (n_r, n_c) = size(A)
    @assert n_r == n_c "Input matrix is not square"
    n_r
end

"Row permutation"
struct Permutation
    indices::Vector{Int}
    n_pivots::Int
end

raw"""
LU factorization with partial pivoting.

`A` is changed to $(L - E) + U$ s.t. $P A = L U$.
"""
function lu_decompose!(A::Matrix{<:AbstractFloat})::Union{Permutation, Nothing}
    n = get_n(A)
    p = collect(1:n)
    n_pivots = n  # for computing the determinant

    @inbounds for c in 1:n
        # Using ArrayView here doesn't help.
        # See https://github.com/JuliaLang/julia/issues/19198#issuecomment-257986870.
        (max_value, c_max) = findmax(abs.(A[c:n, c]))
        if max_value < eps()
            return nothing
        end
        c_max += c - 1

        if c_max != c
            @views A[[c, c_max], :] .= A[[c_max, c], :]
            p[c], p[c_max] = p[c_max], p[c]
            n_pivots += 1
        end

        # `A[r, c]` is assigned to 0 by `A[r, c] -= A[c, c] * (A[r, c] / A[c, c])`, so the element
        # in `L` is `(A[r, c] / A[c, c])`.
        rg = (c + 1):n;
        @views A[rg, c] /= A[c, c]
        @. @views A[rg, rg] -= A[rg, c] * A[c, rg]'
    end

    Permutation(p, n_pivots)
end

raw"""
Solves $A x = b$.

**Precondition**: `LU` is obtained by appling `lu_decompose!` on `A`.
"""
function lu_solve(LU::Matrix{T}, perm::Permutation, b::Vector{T})::Vector{T} where T<:AbstractFloat
    n = get_n(LU)

    # transforms `b`, stored in `x`
    x = b[perm.indices]
    for r in 1:n
        @views x[r] -= dot(LU[r, 1:(r - 1)], x[1:(r - 1)])
    end

    # computes `x`
    for r in n:-1:1
        p = @views dot(LU[r, (r + 1):n], x[(r + 1):n])
        x[r] = (x[r] - p) / LU[r, r]
    end

    x
end

function lu_det(LU::Matrix{T}, n_pivots::Int)::T where T<:AbstractFloat
    n = get_n(LU)
    det = foldl(*, LU[i, i] for i in 1:n)
    if iseven(n - n_pivots)
        det
    else
        -det
    end
end

#===== Unit Tests =====#
using Test

using LinearAlgebra: Diagonal, I, LowerTriangular, UpperTriangular
using LinearAlgebra: det  # for reference implementation
using Random: seed!

@testset "LU decomposition" begin
    n = 32
    seed!()
    A = rand(n, n)
    b = rand(n)

    LU = copy(A)
    perm = lu_decompose!(LU)
    if perm != nothing
        L = LowerTriangular(LU) - Diagonal(LU) + I
        U = UpperTriangular(LU)
        @test L * U ≈ A[perm.indices[:], :]

        @test lu_det(LU, perm.n_pivots) ≈ det(A)

        x = lu_solve(LU, perm, b)
        @test A * x ≈ b
    end
end

end # module
