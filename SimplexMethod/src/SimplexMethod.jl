"""
Simplex Method
==============

References
----------

- CLRS's Introduction to Algorithms, Chapter 29.
- https://people.richland.edu/james/ictcm/2006/simplex.html
- http://www.phpsimplex.com/en/simplex_method_theory.htm

"""
module SimplexMethod

using LinearAlgebra

export simplex_method, find_basic_indices, find_optimal_x

#=

The standard form of linear programming:

    max    c^T x
    s.t.   A x = b
           x >= 0

Each intersection point (vertex of the feasible region) can be identified by $n - m$ variables being
0, i.e., $n - m$ non-basic variables. The optimal solution is at an extreme point of the simplex.
The algorithm starts from the origin (a basic feasible solution), iterates through the extreme
points until no improvement can be made.

Let `sB` be the bit vector indicating basic variables, then `sNB = !.sB` indicates the indices of
non-basic variables.

    b = A[:, sB] * x[sB] + A[:, sNB] * x[sNB]

    c' * x = c[sB]' * x[sB] + c[sNB]' * x[sNB]
           = c[sB]' * inv(A[:, sB]) * (b - A[:, sNB] * x[sNB]) + c[sNB]' * x[sNB]
           = c[sB]' * inv(A[:, sB]) * b + (c[sNB] - A[:, sNB]' * inv(A[:, sB])' * c[sB])' * x[sNB]

Basic V.S. Non-basic
--------------------

- Basic variables: nonzero (elementary, foundational, or important)
- Non-basic variables: always zero
- One basic variable for each row of the tableau
- The objective function is always basic in the bottom row
- Entering: non-basic -> basic
- Leaving: basic -> non-basic

- - - -

(Only the slack type implemented)

| Type of inequality |    Type of variable  |
|--------------------|----------------------|
|          ≥         | -surplus +artificial |
|          =         |      +artificial     |
|          ≤         |        +slack        |

=#

function find_basic_indices(S::AbstractMatrix{T})::Vector{Int} where T<:AbstractFloat
    (nr, nc) = size(S)
    indices = zeros(Int, nr)
    for c in 1:nc
        zero_cnt = 0
        one_idx = nothing
        for r = 1:nr
            if S[r, c] ≈ one(T)
                one_idx = r
            elseif S[r, c] ≈ zero(T)
                zero_cnt += 1
            end
        end
        if zero_cnt == nr - 1 && !isnothing(one_idx)
            indices[one_idx] = c
        end
    end
    indices
end

# `S` and `b` should be in the final configuration in the tableau.
function find_optimal_x(
    S::AbstractMatrix{T},
    b::AbstractVector{T},
)::Vector{T} where T<:AbstractFloat
    basic_indices = find_basic_indices(S)
    (m, m_plus_n) = size(S)
    x = zeros(T, m_plus_n)
    x[basic_indices] .= b
    x[1:(m_plus_n - m)]  # Removes slack variables
end

@enum LPResult begin
    # Infinite
    Unbounded
    # Infeasible
end

function simplex_method(
    A::AbstractMatrix{T},
    b::AbstractVector{T},
    c::AbstractVector{T},
)::Union{LPResult, Tuple{T, Vector{T}}} where T<:AbstractFloat
    (m, n) = size(A)
    tableau = zeros(T, (m + 1, n + m + 1))  # introduces m slack variables
    tableau[1:m, 1:n] = A
    tableau[1:m, (n + 1):(end - 1)] = I(m)
    tableau[end, 1:n] = -c'
    tableau[1:m, end] = b

    # Make some aliases
    S = @view tableau[1:(end - 1), 1:(end - 1)]  # the slack form
    coeff = @view tableau[end, 1:n]  # (negative, indeed) coefficients
    bias = @view tableau[1:m, end]

    while true
        (entering_val, entering_idx) = findmin(coeff)
        # There are no more negative coefficients, which means we cannot make the objective larger.
        if entering_val >= zero(T)
            z = tableau[end]
            x = find_optimal_x(S, bias)
            return (z, x)
        end

        # Pivoting. Similar to Gaussian elimination.
        pivot_row = nothing
        pivot_val = typemax(T)
        # Finds the tightest bound
        for r in 1:m
            if S[r, entering_idx] > zero(T)
                t = bias[r] / S[r, entering_idx]
                if t < pivot_val
                    pivot_row = r
                    pivot_val = t
                end
            end
        end

        # If the whole column is negative, the value can grow as large as possible without violating
        # the nonnegative constriaints.
        if isnothing(pivot_row)
            return Unbounded
        end

        # Normalizes row
        tableau[pivot_row, :] .*= 1 / tableau[pivot_row, entering_idx]
        for r in 1:(m + 1)  # including the last row
            if r != pivot_row
                tableau[r, :] .-= tableau[pivot_row, :] * tableau[r, entering_idx]
            end
        end
    end
end

end # module
