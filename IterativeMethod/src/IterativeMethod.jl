module IterativeMethod

using LinearAlgebra

export
    is_diagonally_dominant,
    jacobi_method

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
    if !is_diagonally_dominant(A)
        println("Jacobi: the input matrix is not diagonally dominant")
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

end # module
