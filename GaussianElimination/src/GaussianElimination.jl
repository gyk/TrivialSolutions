module GaussianElimination

function rref!(A::AbstractMatrix{Float64})
    n_rows, n_cols = size(A)
    if n_rows == 0 || n_cols == 0
        return A
    end

    col, row = 1, 1
    pivot_cols = Int[]
    while row <= n_rows && col <= n_cols
        # Find pivot
        m, max_row = findmax(abs, @view A[row:end, col])
        max_row += row - 1
        if m ≈ 0.0
            A[row:end, col] .= 0.0
            col += 1
            continue
        end

        if max_row != row
            A[[row, max_row], col:end] = A[[max_row, row], col:end]
        end

        # Pivot normalization
        @view(A[row, (col + 1):end]) .*= 1.0 / A[row, col]
        A[row, col] = 1.0

        for r ∈ (row + 1):n_rows
            if A[r, col] ≈ 0.0
                continue
            end
            factor = A[r, col]
            @views A[r, (col + 1):end] .-= A[row, (col + 1):end] * factor
        end
        @view(A[(row + 1):end, col]) .= 0.0

        push!(pivot_cols, col)
        row += 1
        col += 1
    end

    for pivot_row ∈ length(pivot_cols):-1:1
        pivot_col = pivot_cols[pivot_row]
        for r ∈ (pivot_row - 1):-1:1
            if A[r, pivot_col] ≈ 0.0
                continue
            end
            factor = A[r, pivot_col]
            @views A[r, (pivot_col + 1):end] .-= A[pivot_row, (pivot_col + 1):end] * factor
        end
        @views A[1:(pivot_row - 1), pivot_col] .= 0.0
    end

    A
end

include("rref_linear_algebra.jl")

end # module GaussianElimination
