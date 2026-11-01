module ModernLinearAlgebra

using LinearAlgebra

export solve_system, numerical_rank, null_space, matrix_inverse

#==

Obsolete RREF Method V.S. Modern Production Standard

- **Solving $Ax = b$**
  - RREF: Transform augmented matrix $[A \mid b]$ to RREF
  - Modern: LU Factorization (with partial pivoting) or Cholesky (for symmetric positive-definite)
- **Determining Matrix Rank**
  - RREF: Count pivot columns in RREF
  - Modern: Singular Value Decomposition (SVD) or Rank-Revealing QR Factorization
- **Finding Null Space / Basis**
  - RREF: Express free variables from RREF
  - Modern: SVD (right-singular vectors corresponding to zero singular values)
- **Computing Matrix Inverse**
  - RREF: Transform $[A \mid I] \to [I \mid A^{-1}]$ via RREF
  - Modern: LU Factorization (solving $AX = I$ directly)

==#

function solve_system(A::AbstractMatrix, b::Union{AbstractVector, AbstractMatrix}; method=:lu)
    factorization = if method === :lu
        lu(A)
    elseif method === :cholesky
        cholesky(Symmetric(A))
    else
        throw(ArgumentError("method must be :lu or :cholesky"))
    end

    factorization \ b
end

numerical_rank(A::AbstractMatrix; kwargs...) = LinearAlgebra.rank(A; kwargs...)
null_space(A::AbstractMatrix; kwargs...) = LinearAlgebra.nullspace(A; kwargs...)
matrix_inverse(A::AbstractMatrix) = LinearAlgebra.inv(A)

end # module ModernLinearAlgebra