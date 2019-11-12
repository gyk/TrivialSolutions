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
        f_iterative = fft_iterative(t)
        @test f_naive ≈ f_direct
        @test f_recursive ≈ f_direct
        @test f_iterative ≈ f_direct

        t_naive = ifft_recursive_naive(f_naive)
        t_recursive = ifft_recursive(f_recursive)
        t_iterative = ifft_iterative(f_iterative)
        @test t_naive ≈ t
        @test t_recursive ≈ t
        @test t_iterative ≈ t

        # Polynomial multiplication
        p1 = rand(n)
        p2 = rand(n)
        x = rand(n)
        prod = @. eval_poly($Ref(p1), x) * eval_poly($Ref(p2), x)
        p = poly_mul(p1, p2)
        prod_fft = eval_poly.(Ref(p), x)
        @test prod ≈ prod_fft
    end
end
