module TicTacToe

using MonteCarloTreeSearch
import MonteCarloTreeSearch:
    get_children,
    is_terminal,
    get_reward,
    get_random_child,
    train!

export TicTacToeRules

export get_children, is_terminal, get_reward, get_random_child

const EMPTY = Int8(0)
const BLACK = Int8(1)
const WHITE = Int8(-1)

struct GameState
    board::Matrix{Int8}
    is_terminal::Bool
    turn::Int8
    n_win::Int
    n_draw::Int

    function GameState()
        board = fill(EMPTY, (3, 3))
        turn = BLACK

        new(board, false, turn, 0, 0)
    end

    function GameState(board, turn)
        is_terminal = !isnothing(get_winner(board))
        new(board, is_terminal, turn, 0, 0)
    end
end

function get_symbol(cell::Int8)
    Dict(-1 => 'O', 0 => '.', 1 => 'X')[cell]
end

Base.show(io::IO, game_state::GameState) = begin
    println(io, "Board:")
    for r in 1:3
        print(io, "  ")
        for c in 1:3
            symbol = get_symbol(game_state.board[r, c])
            print(io, "$symbol ")
        end
        println(io)
    end
    println(io, "  turn = $(get_symbol(game_state.turn)), is_terminal = $(game_state.is_terminal)")
    game_state.board
end

function get_moves(game_state::GameState)::Vector{Tuple{Int,Int}}
    [(r, c) for r in 1:3 for c in 1:3 if game_state.board[r, c] == EMPTY]
end

function make_move(game_state::GameState, (r, c)::Tuple{Int,Int})::GameState
    new_board = copy(game_state.board)
    new_board[r, c] = game_state.turn
    new_turn = -game_state.turn
    GameState(new_board, new_turn)
end

function get_lines(board::Matrix{Int8})
    Iterators.Flatten((
        (board[r, :] for r in 1:3), # rows
        (board[:, c] for c in 1:3), # columns
        ([board[d, d] for d in 1:3],), # diagonal
        ([board[r, c] for (r, c) in zip(1:3, 3:-1:1)],), # anti-diagonal
    ))
end

# Assuming the board is valid, returns
#
# - BLACK/WHITE if the winner is BLACK/WHITE
# - EMPTY if it's a draw
# - nothing if it's not terminal
function get_winner(board::Matrix{Int8})::Union{Int8,Nothing}
    for line in get_lines(board)
        if allequal(line) && first(line) != EMPTY
            return first(line)
        end
    end
    any(==(EMPTY), board) ? nothing : EMPTY
end

#===== GameRules =====#

struct TicTacToeRules <: GameRules end

function get_children(rules::TicTacToeRules, node::MCTSNode{GameState})::Vector{MCTSNode}
    s::GameState = node.state
    children = GameState[]
    for move in get_moves(s)
        new_state = make_move(s, move)
        push!(children, new_state)
    end
    map(MCTSNode, children)
end

function get_random_child(rules::TicTacToeRules, node::MCTSNode{GameState})::Union{Nothing,MCTSNode}
    s::GameState = node.state
    if s.is_terminal
        return nothing
    end

    moves = get_moves(s)
    s = make_move(s, rand(moves))
    MCTSNode(s)
end

"Checks if the node is in terminal state (game over)"
function is_terminal(rules::TicTacToeRules, node::MCTSNode)::Bool
    s::GameState = node.state
    s.is_terminal
end

"Returns the reward value for the terminal state"
function get_reward(rules::TicTacToeRules, node::MCTSNode)::Float64
    s::GameState = node.state
    winner = get_winner(s.board)
    if isnothing(winner)
        error("Try to get reward at non-terminal node")
    end

    if winner == -s.turn
        -1.0
    elseif winner == EMPTY
        0.0
    else
        error("Reached illegal state")
    end
end

#===== Playing =====#

function play_against_mcts()
    ttt_rules = TicTacToeRules()
    init_state = GameState()
    mcts = MCTS(ttt_rules, init_state)

    s = init_state
    println(s)
    while true
        println("\n========\n")

        while true
            print("Your move: ")
            human_move = eval(Meta.parse(readline()))
            if typeof(human_move) != Tuple{Int,Int}
                println("Good game.")
                return
            elseif !checkbounds(Bool, s.board, human_move...) || s.board[human_move...] != EMPTY
                println("Illegal move. Try again.")
            else
                s = make_move(s, human_move)
                break
            end
        end

        print(s)
        println("--------")
        if s.is_terminal
            break
        end

        mcts.root = MCTSNode(s)
        train!(mcts, 250)
        computer_move = MonteCarloTreeSearch.choose_best_move(mcts)
        s = computer_move.state
        println("Computer move: ")
        print(s)
        if s.is_terminal
            break
        end
    end

    println("\nWinner: $(get_symbol(get_winner(s.board)))")
end

end
