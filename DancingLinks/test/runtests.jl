using DancingLinks.Sudoku

using Test

DUMMY = zeros(Int, 9, 9)

# From https://norvig.com/sudoku.html
A_TYPICAL_PUZZLE = [
    4 0 0 0 0 0 8 0 5
    0 3 0 0 0 0 0 0 0
    0 0 0 7 0 0 0 0 0
    0 2 0 0 0 0 0 6 0
    0 0 0 0 8 0 4 0 0
    0 0 0 0 1 0 0 0 0
    0 0 0 6 0 3 0 7 0
    5 0 0 2 0 0 0 0 0
    1 0 4 0 0 0 0 0 0
]

# Arto Inkala's "the most difficult sudoku-puzzle known so far"
HARDEST_PUZZLE_2006 = [
    8 5 0 0 0 2 4 0 0
    7 2 0 0 0 0 0 0 9
    0 0 4 0 0 0 0 0 0
    0 0 0 1 0 7 0 0 2
    3 0 5 0 0 0 9 0 0
    0 4 0 0 0 0 0 0 0
    0 0 0 0 8 0 0 7 0
    0 1 7 0 0 0 0 0 0
    0 0 0 0 3 6 0 4 0
]

# Arto Inkala's "the most difficult puzzle I've ever created"
HARDEST_PUZZLE_2010 = [
    0 0 5 3 0 0 0 0 0
    8 0 0 0 0 0 0 2 0
    0 7 0 0 1 0 5 0 0
    4 0 0 0 0 5 3 0 0
    0 1 0 0 7 0 0 0 6
    0 0 3 2 0 0 0 8 0
    0 6 0 5 0 0 0 0 9
    0 0 4 0 0 0 0 3 0
    0 0 0 0 0 9 7 0 0
]

NO_SOLUTION = ones(Int, 9, 9)


dummy = create_sudoku(DUMMY)
a_typical_puzzle = create_sudoku(A_TYPICAL_PUZZLE)
hardest_puzzle_2006 = create_sudoku(HARDEST_PUZZLE_2006)
hardest_puzzle_2010 = create_sudoku(HARDEST_PUZZLE_2010)
no_solution = create_sudoku(NO_SOLUTION)

@test check_solution(solve_sudoku!(dummy), DUMMY)
@test check_solution(solve_sudoku!(a_typical_puzzle), A_TYPICAL_PUZZLE)
@test check_solution(solve_sudoku!(hardest_puzzle_2006), HARDEST_PUZZLE_2006)
@test check_solution(solve_sudoku!(hardest_puzzle_2010), HARDEST_PUZZLE_2010)

@test solve_sudoku!(no_solution) == nothing
