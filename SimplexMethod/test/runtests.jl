using Test
using LinearAlgebra: norm
using Random: seed!

using SimplexMethod

@testset "Smoke" begin
    A = Float64[
        1   2
        1   1
        3   2
    ]
    b = Float64[16, 9, 24]
    c = Float64[40, 30]
    @test simplex_method(A, b, c)[1] ≈ 330.0

    A = Float64[
        1   1   3
        2   2   5
        4   1   2
    ]
    b = Float64[30, 24, 36]
    c = Float64[3, 1, 2]
    @test simplex_method(A, b, c)[1] ≈ 28.0

    A = Float64[
        2   1
        2   3
        3   1
    ]
    b = Float64[18, 42, 24]
    c = Float64[3, 2]
    @test simplex_method(A, b, c)[1] ≈ 30.0
end

@testset "Randomized" begin
    # JuliaOpt/JuMP seems too heavyweight so roll my own test routine.
    seed!()
    N_TESTS = 10
    N_PERTURBATIONS = 5
    for _ in 1:N_TESTS
        n = rand(10:20)
        m = rand(1:(n - 1))
        A = rand(m, n)
        b = rand(m)
        c = abs.(rand(n))

        (z, x) = simplex_method(A, b, c)
        @test c' * x ≈ z
        lambda = 1.0e-3

        for _ in 1:N_PERTURBATIONS
            delta = rand(n)
            delta .*= lambda / norm(delta)
            xd = x + delta
            @test any(xd .< 0.0) || any(A * xd .> b) || c' * xd <= z
        end
    end
end
