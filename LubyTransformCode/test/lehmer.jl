using Test
using LubyTransformCode

using LubyTransformCode: next_lehmer

@testset "Lehmer RNG" begin
    seeds = UInt32[
        0x00:0xFF;
        (0x7FFF_FFFF - 0xFF):(0x7FFF_FFFF + 0xFF);
        (0xFFFF_FFFF - 0xFF):0xFFFF_FFFF;
    ]

    for seed in seeds
        lehmer = Lehmer(seed)
        N = 5

        random_list = []
        for x in Iterators.take(lehmer, N)
            push!(random_list, x)
        end

        expected = []
        x = seed
        for i in 1:N
            x = next_lehmer(x)
            push!(expected, x)
        end

        @test random_list == expected
    end
end

@testset "Lehmer random sample: smoke test" begin
    seed = UInt32(42)
    lehmer = Lehmer(seed)
    n = UInt32(20)
    k = UInt32(10)
    samples = random_sample(lehmer, n, k)
    @test length(samples) == k && all(1 .<= samples .<= n)
end
