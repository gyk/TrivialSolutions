export GameRules, MCTSNode, MCTS
export
    get_children,
    is_terminal,
    get_reward,
    get_random_child,
    choose_best_move,
    train!

mutable struct MCTSNode{S}
    state::S

    visited_children::Vector{MCTSNode{S}}
    unvisited_children::Union{Nothing, Vector{MCTSNode{S}}}

    n_visits::Int
    reward::Float64

    function MCTSNode(state::S) where {S}
        visited_children = []
        unvisited_children = nothing

        new{S}(state, visited_children, unvisited_children, 0, 0.0)
    end
end

"Can potentially be further expanded"
function is_expandable(node::MCTSNode)::Bool
    isnothing(node.unvisited_children) || !isempty(node.unvisited_children)
end

is_unexplored(node::MCTSNode) = node.n_visits == 0

#===== Interfaces =====#

macro must_impl(def)
    sig = string(def.args[1])
    def.args = [def.args[1], :(error("Method $($(sig)) must be implemented"))]
    :($(esc(def)))
end

abstract type GameRules end

"Returns all children from the given node"
@must_impl function get_children(rules::GameRules, node::MCTSNode)::Vector{MCTSNode}
end

@must_impl function get_random_child(rules::GameRules, node::MCTSNode)
    ::Union{Nothing, MCTSNode}
end

"Checks if the node is in terminal state (game over)"
@must_impl function is_terminal(rules::GameRules, node::MCTSNode)::Bool end

"Returns the reward value for the terminal state"
@must_impl function get_reward(rules::GameRules, node::MCTSNode)::Float64 end


"Monte Carlo tree searcher"
mutable struct MCTS{R<:GameRules}
    game_rules::R
    root::MCTSNode
    exploration_weight::Float64

    function MCTS(game_rules::R, init_state, exploration_weight=sqrt(2)) where R
        new{R}(game_rules, MCTSNode(init_state), exploration_weight)
    end
end

# Start from root node (the current game state) and select successive child nodes until a leaf node
# is reached. A leaf is any node that has a potential child from which no simulation (playout) has
# yet been initiated, or a terminal node.
function select!(mcts::MCTS)::Vector{MCTSNode}
    path = MCTSNode[]
    x = mcts.root
    while true
        push!(path, x)
        if is_terminal(mcts.game_rules, x) || is_expandable(x)
            return path
        end

        for child in x.visited_children
            if is_unexplored(child)
                return path
            end
        end

        # UCT (Upper Confidence bound 1 applied to Trees)
        # https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation
        @assert all(child -> child.n_visits > 0, x.visited_children)
        @assert x.n_visits > 0
        (_, i) = findmax(
            child -> begin
                exploitation = child.reward / child.n_visits
                exploration = mcts.exploration_weight * sqrt(log(x.n_visits) / child.n_visits)
                value = exploitation + exploration
                @assert isfinite(value)
                value
            end,
            x.visited_children
        )
        x = x.visited_children[i]
    end
end

# Unless the leaf ends the game decisively, create one or more child nodes and choose one of them.
function expand!(mcts::MCTS, node::MCTSNode)::Union{Nothing, MCTSNode}
    @assert is_expandable(node) "The node $(node) has already been fully expanded"
    if isnothing(node.unvisited_children)
        node.unvisited_children = get_children(mcts.game_rules, node)
    end

    unvisited = node.unvisited_children
    if isempty(unvisited)
        return nothing
    end
    i = rand(eachindex(unvisited))
    unvisited[i], unvisited[end] = unvisited[end], unvisited[i]
    child = pop!(unvisited)
    push!(node.visited_children, child)
    child
end

# Complete one random playout.
function simulate!(mcts::MCTS, node::MCTSNode)
    invert_reward = true

    while !is_terminal(mcts.game_rules, node)
        node = get_random_child(mcts.game_rules, node)
        invert_reward = !invert_reward
    end
    reward = get_reward(mcts.game_rules, node)

    invert_reward ? -reward : reward
end

# Use the result of the playout to update information in the nodes on the path to the root.
function backpropagate!(_mcts::MCTS, path::Vector{MCTSNode}, reward::Float64)
    for node in reverse(path)
        node.n_visits += 1
        node.reward += reward
        reward = -reward
    end
end

@inline function train_one!(mcts::MCTS)
    path::Vector{MCTSNode} = select!(mcts)
    node::MCTSNode = path[end]
    if !is_terminal(mcts.game_rules, node) && is_expandable(node)
        node = expand!(mcts, node)
        push!(path, node)
    end
    result = simulate!(mcts, node)
    backpropagate!(mcts, path, result)
end

function train!(mcts::MCTS, n_iterations::Int)
    for _ in 1:n_iterations
        train_one!(mcts)
    end
end

function choose_best_move(mcts::MCTS)::MCTSNode
    root = mcts.root

    @assert !is_terminal(mcts.game_rules, root)
    @assert !isempty(root.visited_children) "Please train the model first"
    @assert all(child -> child.n_visits > 0, root.visited_children)

    (_, i) = findmax(child -> child.reward / child.n_visits, root.visited_children)
    root.visited_children[i]
end
