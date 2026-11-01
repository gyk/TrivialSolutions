function is_rref(A::AbstractMatrix; atol=1e-10)
    all(isfinite, A) || return false

    previous_pivot_col = 0
    saw_zero_row = false
    n_rows = size(A, 1)
    for row in 1:n_rows
        pivot_col = findfirst(
            x -> !isapprox(x, 0.0; atol=atol, rtol=0.0),
            view(A, row, :),
        )

        if pivot_col === nothing
            saw_zero_row = true
            continue
        end

        saw_zero_row && return false
        pivot_col > previous_pivot_col || return false
        isapprox(A[row, pivot_col], 1.0; atol=atol, rtol=0.0) || return false

        for other_row in 1:n_rows
            other_row == row && continue
            isapprox(A[other_row, pivot_col], 0.0; atol=atol, rtol=0.0) || return false
        end

        previous_pivot_col = pivot_col
    end

    true
end

function preserves_row_space(A::AbstractMatrix, R::AbstractMatrix; atol=1e-10)
    A_float = Float64.(A)
    rank_A = rank(A_float; atol=atol)
    rank_R = rank(R; atol=atol)
    rank_stack = rank(vcat(A_float, R); atol=atol)
    rank_A == rank_R == rank_stack
end

@testset "GaussianElimination.rref!" begin
    @testset "Wikipedia smoke test" begin
        A = Float64[
             2  1 -1   8
            -3 -1  2 -11
            -2  1  2  -3
        ]
        expected = Float64[
            1 0 0  2
            0 1 0  3
            0 0 1 -1
        ]

        result = GaussianElimination.rref!(A)

        @test result === A
        @test A ≈ expected
    end

    @testset "basic canonical examples" begin
        examples = [
            (
                [0.0 2.0; 0.0 4.0],
                [0.0 1.0; 0.0 0.0],
            ),
            (
                [1.0 2.0; 2.0 4.0],
                [1.0 2.0; 0.0 0.0],
            ),
            (
                [1.0 0.0; 0.0 2.0],
                [1.0 0.0; 0.0 1.0],
            ),
            (
                [0.0 1.0 2.0; 0.0 0.0 3.0],
                [0.0 1.0 0.0; 0.0 0.0 1.0],
            ),
        ]

        for (source, expected) in examples
            result = GaussianElimination.rref!(copy(source))
            @test result ≈ expected
            @test is_rref(result)
        end
    end

    @testset "edge-shaped and structured matrices" begin
        matrices = [
            zeros(Int, 0, 0),
            zeros(Int, 0, 4),
            zeros(Int, 4, 0),
            zeros(Int, 4, 5),
            [7;;],
            [0;;],
            [1 2 3 4 5],
            reshape([1, 2, 3, 4, 5], 5, 1),
            [1 2 3; 2 4 6; 0 1 1],
            [1 0 0; 0 2 0; 0 0 0; 0 0 4],
            [0 1 0 2; 0 0 1 3],
        ]

        for source in matrices
            actual = Float64.(source)
            result = GaussianElimination.rref!(actual)
            @test result === actual
            @test is_rref(result)
            @test preserves_row_space(source, result)
            @test GaussianElimination.rref!(copy(result)) ≈ result
        end
    end

    @testset "random dense matrices" begin
        rng = MersenneTwister(0x5eed)
        for _ in 1:500
            n_rows = rand(rng, 0:7)
            n_cols = rand(rng, 0:7)
            source = rand(rng, n_rows, n_cols)
            actual = copy(source)
            result = GaussianElimination.rref!(actual)
            @test result === actual
            @test is_rref(result)
            @test preserves_row_space(source, result)
            @test GaussianElimination.rref!(copy(result)) ≈ result
        end
    end

    @testset "random row-equivalent matrices" begin
        rng = MersenneTwister(0xdecafbad)
        for _ in 1:200
            n_rows = rand(rng, 1:6)
            n_cols = rand(rng, 1:7)
            source = rand(rng, n_rows, n_cols)

            # Apply elementary row operations to create a different representation
            # of the same system before checking its canonical RREF.
            transformed = copy(source)
            for _ in 1:rand(rng, 0:8)
                if n_rows == 1
                    transformed[1, :] .*= rand(rng, (-3.0, -2.0, -1.0, 1.0, 2.0, 3.0))
                    continue
                end

                operation = rand(rng, 1:3)
                first_row, second_row = randperm(rng, n_rows)[1:2]
                if operation == 1
                    transformed[[first_row, second_row], :] = transformed[[second_row, first_row], :]
                elseif operation == 2
                    transformed[first_row, :] .*= rand(rng, (-3.0, -2.0, -1.0, 1.0, 2.0, 3.0))
                else
                    transformed[first_row, :] .+= rand(rng, (-3.0, -2.0, -1.0, 1.0, 2.0, 3.0)) .* transformed[second_row, :]
                end
            end

            expected = GaussianElimination.rref!(copy(source))
            GaussianElimination.rref!(transformed)
            @test transformed ≈ expected atol=1e-9 rtol=1e-9
            @test is_rref(transformed; atol=1e-9)
            @test preserves_row_space(source, transformed; atol=1e-9)
        end
    end
end
