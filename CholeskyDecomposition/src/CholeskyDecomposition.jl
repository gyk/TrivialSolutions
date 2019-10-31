raw"""
Computes Cholesky decomposition of a Hermitian positive-definite matrix A, i.e.,

$$
A = L L^*
$$

where $L$ is a lower triangular matrix with real and positive diagonal entries, and $L^*$ denotes
the conjugate transpose of $L$.
"""
module CholeskyDecomposition

using LinearAlgebra

export
    cholesky_outer_product_decompose,
    cholesky_banachiewicz_decompose,
    cholesky_crout_decompose

function get_n(A::Matrix)::Int
    (n_r, n_c) = size(A)
    @assert n_r == n_c "Input matrix is not square"
    n_r
end

"""
The Cholesky (outer-product) algorithm

<https://en.wikipedia.org/wiki/Cholesky_decomposition#The_Cholesky_algorithm>
"""
function cholesky_outer_product_decompose(A::Matrix{T})::LowerTriangular{T} where T<:Number
    n = get_n(A)

    # Some edge case values:
    #
    #     A_1 = A
    #     A_{n + 1} = I(n)
    #     I_i ∈ ℜ_{i ^ 2}
    #     I_0 = ∅
    #     L_0 = I(n)
    #     B_0 = A
    #     B_i ∈ ℂ_{(n - i) ^ 2}
    #     B_n = ∅

    A_i = copy(A)
    A = nothing  # prevents accidental assignment
    L_0 = T.(I(n)) |> Matrix |> LowerTriangular
    L = copy(L_0)  # The product of L1...Ln
    for i in 1:n
        # Makes aliases (no need for `A_ii`)
        b_i = @view A_i[(i + 1):end, i]
        b_i_H = @view A_i[i, (i + 1):end]
        B_i = @view A_i[(i + 1):end, (i + 1):end]

        L_i = copy(L_0)
        sqrtAii = sqrt(A_i[i, i])
        L_i[i, i] = sqrtAii
        L_i[(i + 1):end, i] = b_i / sqrtAii

        L *= L_i

        # Mind the order
        B_i .-= b_i * transpose(b_i_H) / A_i[i, i]  # Ugly, can't do `b_i * b_i_H`
        b_i .= 0.0
        b_i_H .= 0.0
        A_i[i, i] = 1.0
    end
    L
end

"""
The Cholesky-Banachiewicz algorithm

<https://en.wikipedia.org/wiki/Cholesky_decomposition#The_Cholesky–Banachiewicz_and_Cholesky–Crout_algorithms>
"""
function cholesky_banachiewicz_decompose(A::Matrix{T})::LowerTriangular{T} where T<:Number
    n = get_n(A)
    # To write the in-place version, just set `L = A` and do symmetric updating.
    L = zeros(T, n, n) |> LowerTriangular

    # Note that as $A$ is positive-definite, **not positive semi-definite**, $L_{ii}$ will never be
    # zero, so there is no need to check.
    #
    # Also, do NOT use `dot` to compute `L[r, c]`!

    for r in 1:n
        for c in 1:(r - 1)
            L[r, c] = (
                A[r, c] - sum((@view L[r, 1:(c - 1)]) .* conj.(@view L[c, 1:(c - 1)]))
            ) / L[c, c]
        end
        l = @view L[r, 1:(r - 1)]
        L[r, r] = sqrt(A[r, r] - l ⋅ l)
    end
    L
end

"""
The Cholesky-Crout algorithm

It is similar to the Cholesky-Banachiewicz algorithm, but processes column by column instead of row
by row.
"""
function cholesky_crout_decompose(A::Matrix{T})::LowerTriangular{T} where T<:Number
    n = get_n(A)
    L = zeros(T, n, n) |> LowerTriangular
    # Deliberately write the index as `:` rather than `1:(c - 1)`
    for c in 1:n
        l = @view L[c, :]
        L[c, c] = sqrt(A[c, c] - l ⋅ l)
        for r in (c + 1):n
            L[r, c] = (A[r, c] - sum((@view L[r, :]) .* conj.(@view L[c, :]))) / L[c, c]
        end
     end
     L
end

end  # module
