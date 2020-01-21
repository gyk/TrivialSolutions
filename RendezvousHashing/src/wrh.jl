
#=
Pr(C(x) = i) = w_i / Σ w_i

The derivation is easy, see [wrh] "Proof of Correctness".
=#

export WrhCoordinator, insert_node!, remove_node!, choose_nodes, num_nodes, node_weight, reseed!

# Make it mutable for reseeding
mutable struct WrhNode
    id::String
    seed::UInt64
    weight::Float64
end

"Weighted Rendezvous Hashing"
struct WrhCoordinator <: RvCoordinator
    nodes::Dict{String, WrhNode}

    WrhCoordinator() = new(Dict{String, WrhNode}())
end

function insert_node!(coordinator::WrhCoordinator, id::String, weight::Float64)
    node = WrhNode(id, hash(id), weight)
    coordinator.nodes[id] = node
end

function remove_node!(coordinator::WrhCoordinator, id::String)
    delete!(coordinator.nodes, id)
end

function choose_nodes(
    coordinator::WrhCoordinator,
    data::String,
    n::Union{Int, Nothing}=nothing,
)::Vector{String}
    nodes = [
        begin
            h = hash(data, node.seed)
            h_float = (h & MASK) / MAX_HASH
            s = -node.weight / log(h_float)
            s => id
        end
        for (id, node) in coordinator.nodes
    ]

    n::Int = isnothing(n) ? length(nodes) : n
    partialsort!(nodes, 1:n;
        rev = true  # descending
    ) .|> last
end

function num_nodes(coordinator::WrhCoordinator)::Int
    length(coordinator.nodes)
end

function node_weight(coordinator::WrhCoordinator, id::String)::Float64
    coordinator.nodes[id].weight
end

function reseed!(coordinator::WrhCoordinator)
    for node in values(coordinator.nodes)
        node.seed = rand(UInt64)
    end
end
