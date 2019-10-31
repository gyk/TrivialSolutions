using Test
using LinearAlgebra

using CholeskyDecomposition

@testset "Cholesky decomposition" begin
    for i in 1:5
        n = rand(1:25)
        # Generates a random hermitian positive definite matrix
        A = begin
            L = rand(Complex{Float64}, n, n)

            # Makes it diagonally dominant
            (L + L') / sqrt(8.0) + I(n) * n
        end

        @assert ishermitian(A) && isposdef(A)

        @test begin
            cholesky_outer_product_decompose(A) ≈
            cholesky_banachiewicz_decompose(A) ≈
            cholesky_crout_decompose(A) ≈
            cholesky(A).L
        end
    end
end
