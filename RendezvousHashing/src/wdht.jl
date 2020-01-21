#=

The "Logarithmic Method" in [wdht].

=#

export WdhtCoordinator, insert_node!, remove_node!, choose_nodes, num_nodes, node_weight, reseed!

# Make it mutable for reseeding
mutable struct WdhtNode
    id::String
    pos::Float64
    weight::Float64
end

"Weighted Distributed Hash Tables"
struct WdhtCoordinator <: RvCoordinator
    nodes::Dict{String, WdhtNode}

    WdhtCoordinator() = new(Dict{String, WdhtNode}())
end

function hash1f(x::String)::Float64
    h = hash(x)
    (h & MASK) / MAX_HASH
end

function insert_node!(coordinator::WdhtCoordinator, id::String, weight::Float64)
    node = WdhtNode(id, hash1f(id), weight)
    coordinator.nodes[id] = node
end

function remove_node!(coordinator::WdhtCoordinator, id::String)
    delete!(coordinator.nodes, id)
end

function choose_nodes(
    coordinator::WdhtCoordinator,
    data::String,
    n::Union{Int, Nothing}=nothing,
)::Vector{String}
    h = hash1f(data)
    nodes = [
        begin
            s = -log(mod(1.0 - (h - node.pos), 1.0)) / node.weight
            s => id
        end
        for (id, node) in coordinator.nodes
    ]

    n::Int = isnothing(n) ? length(nodes) : n
    last.(partialsort!(nodes, 1:n))
end

function num_nodes(coordinator::WdhtCoordinator)::Int
    length(coordinator.nodes)
end

function node_weight(coordinator::WdhtCoordinator, id::String)::Float64
    coordinator.nodes[id].weight
end

function reseed!(coordinator::WdhtCoordinator)
    for node in values(coordinator.nodes)
        node.pos = rand()
    end
end
