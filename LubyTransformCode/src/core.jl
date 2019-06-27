using StatsBase: sample, Weights

const PACKET_SIZE = 8
const WATER_WASTING_FACTOR = 2.0

struct WaterDrop
    "The index of the first block, doubled as RNG seed"
    index::UInt32

    "The number of blocks"
    degree::UInt32

    "The block data XORed together"
    data::Vector{UInt8}
end

function get_block(data::AbstractVector{UInt8}, block_size::Integer, i::Integer)::SubArray{UInt8, 1}
    view(data, (block_size * (i - 1) + 1 : block_size * i))
end

function generate_degrees(soliton::Soliton, n_samples::Int)::Vector{Int}
    prob = get_probabilities(soliton)
    sample(1:length(prob), Weights(prob), n_samples)
end

"`n`: maximum index number."
function generate_indices(seed::UInt32, n::Int, n_samples::Int)::Vector{Int}
    lehmer = Lehmer(seed)
    Int.(random_sample(lehmer, UInt32(n), UInt32(n_samples)))
end
