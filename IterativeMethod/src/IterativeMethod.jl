module IterativeMethod

using LinearAlgebra

export
    is_diagonally_dominant,
    jacobi_method,
    gauss_seidel_method, gauss_seidel_method!

#===== Jacobi method =====#

#=

A x = b
A = D + R
D x = -R x + b
  x = -D^{-1} R x + D^{-1} b
⟹
x = B x + z, where B = -D^{-1} R, z = D^{-1}


x_{i + 1} = B x_i + z
          = B (x^* + e_i) + z
          = x^* + B e_i
⟹
e_{i + 1} = B e_i

=#

function is_diagonally_dominant(A::AbstractMatrix{T})::Bool where T<:AbstractFloat
    A = abs.(A)
    d2 = diag(A) * 2
    all(sum(A, dims=1)' .<= d2) && all(sum(A, dims=2) .<= d2)
end

const MAX_ITERATIONS = 1000

function jacobi_method(
    A::Matrix{T},
    b::Vector{T},
    x0::Vector{T} = zero(b),
)::Vector{T} where T<:AbstractFloat
    (nr, nc) = size(A)
    @assert nr == nc "Jacobi: A is not square."
    if !is_diagonally_dominant(A)
        println("Jacobi: A is not diagonally dominant")
    end

    D = Diagonal(A)
    invD = inv(D)
    negR = D - A
    x = x0
    for _ in 1:MAX_ITERATIONS
        x = invD * (negR * x0 + b)
        if x ≈ x0
            return x
        end
        x0 = x
    end
    x
end

#===== Gauss–Seidel method =====#

#=

In Jacobi method,

    x_i^{(k + 1)} = -1/a_ii * ((L + U)_{i, :} * x^{(k)}) + b_i / a_ii

where $U$ ($L$) is the strictly upper (lower) triangular and $R = L + U$. If in the iteration we
use the elements of $x^{(k+1)}$ that have already been computed to compute the unknown ones of
$x^{(k+1)}$,

    x_i^{(k + 1)} = -1/a_ii * ((L_*)_{i, :} * x^{(k + 1)} + U_{i, :} * x^{(k)}) + b_i / a_ii

where $L_* = D + L$ is a lower triangular matrix. Or more compcatly,

    A x = b
    (L_* + U) x = b
    L_* x = b - U x

    ⟹

    L_* x^{(k + 1)} = b - U x^{(k)}
    x^{(k + 1)} = L_*^{-1} (b - U x^{(k)})

=#

function gauss_seidel_method(A::Matrix{T}, b::Vector{T})::Vector{T} where T<:AbstractFloat
    x0 = zero(b)
    gauss_seidel_method!(A, b, x0)
end

# The initial guess `x0` will be updated in-place.
function gauss_seidel_method!(
    A::Matrix{T},
    b::Vector{T},
    x0::Vector{T},
)::Vector{T} where T<:AbstractFloat
    (nr, nc) = size(A)
    @assert nr == nc "Gauss–Seidel: A is not square."
    n = nr
    if !is_diagonally_dominant(A)
        println("Gauss–Seidel: A is not diagonally dominant")
    end

    x = x0
    for _ in 1:MAX_ITERATIONS
        updated = false
        for r in 1:n
            old = x[r]
            x[r] = (b[r] - ((@view A[r, :])' * x - A[r, r] * x[r])) / A[r, r]
            if !(x[r] ≈ old)
                updated = true
            end
        end
        if !updated
            return x
        end
    end
    x
end

end # module
