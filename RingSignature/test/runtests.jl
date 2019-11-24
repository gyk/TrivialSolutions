using Test

using RingSignature

@testset "Smoke" begin
    N = 8
    msg1 = Vector{UInt8}("XKeyScore allows the NSA to read anyone's email in the world.")
    msg2 = Vector{UInt8}("The NSA can spy on you through Angry Birds.")

    ctx = RingContext(N, 1024)
    for i in 1:N
        s1 = ring_sign(ctx, msg1, i)
        s2 = ring_sign(ctx, msg2, i)
        @test ring_verify(ctx, msg1, s1) && ring_verify(ctx, msg2, s2)
        @test !ring_verify(ctx, msg1, s2) && !ring_verify(ctx, msg2, s1)
    end
end
