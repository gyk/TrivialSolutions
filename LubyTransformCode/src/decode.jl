import Base: <

using DataStructures: MutableBinaryMinHeap, push!, pop!, top, _heap_bubble_up!
using DataStructures: DefaultDict

export decode

# Can't come up with a better name
struct Glass
    g_index::Int  # indexing into the `Glass` vector
    indices::Set{Int}
    data::Vector{UInt8}  # data being decoded in progress
end

@inline function heapify!(h::MutableBinaryMinHeap{T}, i::Int) where T
    _heap_bubble_up!(h.comparer, h.nodes, h.node_map, h.node_map[i])
end

function fill_glass(drop::WaterDrop, n_blocks::Int, glass_index::Int)::Glass
    indices = generate_indices(drop.index, n_blocks, Int(drop.degree))
    Glass(glass_index, Set(indices), drop.data)
end

degree(g::Glass) = length(g.indices)
<(g1::Glass, g2::Glass) = degree(g1) < degree(g2)

function percolate!(g::Glass, block_index::Int, data::Vector{UInt8})::Bool
    if block_index ∈ g.indices
        delete!(g.indices, block_index)
        g.data .⊻= data
        true
    else
        false
    end
end

# `n_blocks` is sent to the receiver before the actual sending of data packets.
function decode(water_drops::Vector{WaterDrop}, n_blocks::Int)::Union{Nothing, Vector{UInt8}}
    decoded = Vector{Union{Nothing, Vector{UInt8}}}(nothing, n_blocks)

    glass_heap = MutableBinaryMinHeap{Glass}()

    # Block index -> set of glass mapping
    block_to_glasses_dict = DefaultDict{Int, Set{Glass}}(Set())

    for (i, drop) in enumerate(water_drops)
        glass = fill_glass(drop, n_blocks, i)
        for ii in glass.indices
            push!(block_to_glasses_dict[ii], glass)
        end
        @assert push!(glass_heap, glass) == i
    end

    while !isempty(glass_heap)
        top_degree = degree(top(glass_heap))
        if top_degree > 1
            break
        elseif top_degree == 0
            pop!(glass_heap)
            continue
        end

        glass = pop!(glass_heap)
        block_index = first(glass.indices)
        for glass_neighbor in block_to_glasses_dict[block_index]
            if glass_neighbor != glass
                if percolate!(glass_neighbor, block_index, glass.data)
                    heapify!(glass_heap, glass_neighbor.g_index)
                end
            end
            delete!(block_to_glasses_dict, glass_neighbor)
        end
        decoded[block_index] = glass.data
    end

    if any(decoded .== nothing)
        nothing
    else
        vcat(decoded...)
    end
end
