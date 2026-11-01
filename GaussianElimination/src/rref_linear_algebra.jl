module RrefLinearAlgebra

using LinearAlgebra
import ..GaussianElimination: rref!

export solve_system, numerical_rank, null_space, matrix_inverse

"""
    solve_system(A, b)

Solve a consistent system `A * x = b` with a unique solution by reducing the
augmented matrix `[A b]` to RREF. Multiple right-hand sides are supported.
"""
function solve_system(A::AbstractMatrix, b::Union{AbstractVector, AbstractMatrix})
    n_rows, n_cols = size(A)
    size(b, 1) == n_rows || throw(DimensionMismatch("A and b have incompatible dimensions"))
    n_rows >= n_cols || throw(ArgumentError("A must have full column rank for a unique solution"))
    numerical_rank(A) == n_cols || throw(ArgumentError("A must have full column rank for a unique solution"))

    reduced = rref!(hcat(Float64.(A), Float64.(b)))
    for row ∈ 1:n_rows
        coefficients = @view reduced[row, 1:n_cols]
        rhs = @view reduced[row, (n_cols + 1):end]
        if all(x -> isapprox(x, 0.0), coefficients) && any(x -> !isapprox(x, 0.0), rhs)
            throw(ArgumentError("system has no solution"))
        end
    end

    solution = reduced[1:n_cols, (n_cols + 1):end]
    b isa AbstractVector ? vec(solution) : solution
end

"""
    numerical_rank(A)

Compute the numerical rank of `A` by counting the nonzero rows of its RREF.
"""
function numerical_rank(A::AbstractMatrix)
    reduced = rref!(Float64.(A))
    count(row -> any(x -> !isapprox(x, 0.0), row), eachrow(reduced))
end

"""
    null_space(A)

Return a basis for the null space of `A`, constructed from the free columns
of its RREF. Basis columns are not generally orthonormal.
"""
function null_space(A::AbstractMatrix)
    reduced = rref!(Float64.(A))
    n_rows, n_cols = size(reduced)
    pivot_rows = Tuple{Int, Int}[]

    for row ∈ 1:n_rows
        pivot_col = findfirst(x -> !isapprox(x, 0.0), @view reduced[row, :])
        pivot_col === nothing || push!(pivot_rows, (row, pivot_col))
    end

    pivot_cols = [pivot_col for (_, pivot_col) ∈ pivot_rows]
    free_cols = setdiff(1:n_cols, pivot_cols)
    basis = zeros(Float64, n_cols, length(free_cols))

    for (basis_col, free_col) ∈ enumerate(free_cols)
        basis[free_col, basis_col] = 1.0
        for (pivot_row, pivot_col) ∈ pivot_rows
            basis[pivot_col, basis_col] = -reduced[pivot_row, free_col]
        end
    end

    basis
end

"""
    matrix_inverse(A)

Compute the inverse of a nonsingular square matrix by reducing `[A I]` to
RREF.
"""
function matrix_inverse(A::AbstractMatrix)
    n_rows, n_cols = size(A)
    n_rows == n_cols || throw(DimensionMismatch("A must be square"))

    identity = Matrix{Float64}(I, n_rows, n_cols)
    reduced = rref!(hcat(Float64.(A), identity))
    left = @view reduced[:, 1:n_cols]
    isapprox(left, identity) || throw(SingularException(n_rows))
    reduced[:, (n_cols + 1):end]
end

end # module RrefLinearAlgebra
