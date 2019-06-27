using Test
using LubyTransformCode

@testset "Soliton ideal distribution" begin
    N = 10
    soliton_ideal = SolitonIdeal(N)
    @test length(soliton_ideal) == N
    @test sum(soliton_ideal.probabilities) ≈ 1.0
end

@testset "Soliton robust distribution" begin
    N = 20
    soliton_robust = SolitonIdeal(N)
    @test length(soliton_robust) == N
    @test sum(soliton_robust.probabilities) ≈ 1.0
end
