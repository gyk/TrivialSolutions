using Test
using LinearAlgebra

using IterativeMethod

@testset "Jacobi method" begin
    for i in 1:5
        n = rand(1:25)

        # Generates a random diagonally dominant matrix
        A = rand(Float64, n, n) + I(n) * n
        b = rand(Float64, n)
        x = jacobi_method(A, b)
        @test A * x ≈ b
    end
end
