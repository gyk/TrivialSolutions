using Test
using MersenneTwister

@testset "MT19937" begin
    mt = MtRandom()

    # https://oeis.org/A221557
    N = 624
    seq = [extract_number!(mt) for i in 1:(N * 2 + 1)]
    @test seq[1:3] == [0xD091BB5C, 0x22AE9EF6, 0xE7E1FAEE]
    @test seq[N] == 0xEFA14DFF
    @test seq[N + 1] == 0xF914DC58
    @test seq[N * 2 + 1] == 0x155F212F
end
