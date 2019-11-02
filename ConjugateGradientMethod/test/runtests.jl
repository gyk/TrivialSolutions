using Test
using LinearAlgebra: norm

using ConjugateGradientMethod

@testset "Conjugate Gradient Method" begin
    for i in 1:10
        n = rand(1:50)
        # Generates a random symmetric positive definite matrix
        A = begin
            A = rand(Float64, n, n)
            A * A'
        end
        b = rand(Float64, n)

        x = A \ b
        @test conjugate_gradient(A, b) ≈ x
        @test conjugate_directions(A, b) ≈ x
    end
end
