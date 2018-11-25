module Sudoku

using DancingLinks

export create_sudoku, solve_sudoku!, check_solution

const L = 3
const N = L * L

# For each label, there are 9 positions to place. There are 9 labels in each sub-grid. And there
# are 9 sub-grids in total.
const MAX_N_ROWS = N * N * N

# From https:#en.wikipedia.org/wiki/Exact_cover#Sudoku:
#
# - Row-Column: Each intersection of a row and column must contain exactly one number.
# - Row-Number: Each row must contain each number exactly once.
# - Column-Number: Each column must contain each number exactly once.
# - Box-Number: Each box must contain each number exactly once.
const MAX_N_COLS = N * N * 4

# `+ 1` for the root. `* 4` because there are 4 data objects linked together in each row.
const MAX_N = 1 + MAX_N_COLS + MAX_N_ROWS * 4

const Coord = Tuple{Int, Int}

struct SudokuSolver
    d::DLinks
    names::Vector{Tuple{Coord, Int}}  # the metadata, for outputing result
end

function create_sudoku(s::Array{Int})::SudokuSolver
    @assert size(s) == (N, N) "Invalid input"

    # allocates dancing links
    d = let
        L = Vector{Int}(undef, MAX_N)
        R = Vector{Int}(undef, MAX_N)
        U = Vector{Int}(undef, MAX_N)
        D = Vector{Int}(undef, MAX_N)

        h = 0
        C = Vector{Int}(undef, MAX_N)
        S = zeros(Int, MAX_N_COLS)

        DLinks(L, R, U, D, h, C, S)
    end
    names = Vector{Tuple{Coord, Int}}(undef, MAX_N)

    init_headers!(d, MAX_N_COLS)
    i = d.h

    for r in 1:N
        for c in 1:N
            cons = compute_constrait_indices(r, c)

            n_list = if s[r, c] == 0  # empty
                1:N
            else
                n = s[r, c]
                n:n
            end

            for n in n_list
                n_ofs = [n, n, n, 1]
                for ii in 1:4
                    DancingLinks.insert!(d,
                        i + ii, i + mod1(ii - 1, 4), i + mod1(ii + 1, 4),
                        cons[ii] + n_ofs[ii])
                    names[i + ii] = ((r, c), n)
                end
                i += 4
            end
        end
    end

    SudokuSolver(d, names)
end

const N2 = N * N

@inline function compute_constrait_indices(r::Int, c::Int)::Tuple{Int, Int, Int, Int}
    offset = 0
    row_cons = offset + N * (r - 1)

    offset += N2
    col_cons = offset + N * (c - 1)

    offset += N2
    box_cons = offset + N * ((r - 1) ÷ L * L + (c - 1) ÷ L)

    offset += N2
    r_c_cons = offset + ((r - 1) * N + (c - 1))

    (row_cons, col_cons, box_cons, r_c_cons)
end

function solve_sudoku!(sudoku::SudokuSolver)::Union{Array{Int}, Nothing}
    sudoku_solution = Int[]
    solved = dlx!(sudoku.d, sudoku_solution)
    if solved
        sol = zeros(Int, N, N)
        for r in sudoku_solution
            (coord, n) = sudoku.names[r]
            sol[coord...] = n
        end
        sol
    else
        println(stderr, "No solution.")
        nothing
    end
end

const ALL_NUMBERS = Set(1:N)

function check_solution(s::Array{Int}, puzzle::Array{Int})::Bool
    @assert size(s) == (N, N) "Invalid input"

    # Rows
    if !all(map(s -> s == ALL_NUMBERS, mapslices(Set, s, dims=2)))
        return false
    end

    # Columns
    if !all(map(s -> s == ALL_NUMBERS, mapslices(Set, s, dims=1)))
        return false
    end

    # Boxes
    for r in 1:L
        for c in 1:L
            if Set(view(s, (1:L) .+ L * (r - 1), (1:L) .+ L * (c - 1))) != ALL_NUMBERS
                return false
            end
        end
    end

    # Conforms to the completed grids
    all(@. (s == puzzle) | (puzzle == 0))
end

end  # module
