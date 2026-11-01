const Rref = GaussianElimination.RrefLinearAlgebra
const Modern = ModernLinearAlgebra

@testset "RrefLinearAlgebra utilities" begin
    @testset "LU and Cholesky solve agree with RREF" begin
        A = [4.0 1.0; 1.0 3.0]
        b = [1.0, 2.0]
        expected = Modern.solve_system(A, b)

        @test Rref.solve_system(A, b) ≈ expected
        @test Rref.solve_system(A, b) ≈ Modern.solve_system(A, b; method=:cholesky)
        @test_throws ArgumentError Rref.solve_system([1.0 2.0; 2.0 4.0], b)
    end

    @testset "SVD rank agrees with RREF pivot count" begin
        A = Float64[
            1 2 3 4
            2 4 6 8
            0 1 1 1
        ]
        @test Rref.numerical_rank(A) == Modern.numerical_rank(A)
    end

    @testset "SVD null space agrees with RREF null space" begin
        A = Float64[
            1 2 0 3
            0 0 1 4
        ]
        rref_basis = Rref.null_space(A)
        svd_basis = Modern.null_space(A)

        @test size(svd_basis) == size(rref_basis)
        @test A * rref_basis ≈ zeros(size(A, 1), size(rref_basis, 2)) atol=1e-10
        @test A * svd_basis ≈ zeros(size(A, 1), size(svd_basis, 2)) atol=1e-10

        # The bases need not match column-for-column, so compare their
        # orthogonal projection matrices instead.
        rref_q = Matrix(qr(rref_basis).Q)[:, 1:size(rref_basis, 2)]
        @test rref_q * rref_q' ≈ svd_basis * svd_basis'
    end

    @testset "Factorization-based inverse agrees with RREF" begin
        A = Float64[
            2 1
            5 3
        ]
        expected = Modern.matrix_inverse(A)

        @test Rref.matrix_inverse(A) ≈ expected
        @test A * Rref.matrix_inverse(A) ≈ Matrix{Float64}(I, size(A)...)
    end
end