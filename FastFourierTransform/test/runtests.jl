using Test

using FastFourierTransform

@testset "FFT Recursive Naive" begin
    for i in 1:5
        n = 2 ^ rand(0:10)
        t = complex(rand(n))
        f_direct = dft(t)
        @test idft(f_direct) ≈ t

        f_naive = fft_recursive_naive(t)
        f_recursive = fft_recursive(t)
        @test f_naive ≈ f_direct
        @test f_recursive ≈ f_direct

        t_naive = ifft_recursive_naive(f_naive)
        t_recursive = ifft_recursive(f_recursive)
        @test t_naive ≈ t
        @test t_recursive ≈ t
    end
end
