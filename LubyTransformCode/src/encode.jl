export encode

function encode(data::AbstractVector{UInt8})::Tuple{Vector{WaterDrop}, Int}
    if length(data) % PACKET_SIZE != 0
        data = [data; zeros(UInt8, PACKET_SIZE - length(data) % PACKET_SIZE)]
    end

    n_blocks = length(data) ÷ PACKET_SIZE
    n_blocks_sent = Int(n_blocks * WATER_WASTING_FACTOR)

    soliton = SolitonRobust(n_blocks)
    degrees = generate_degrees(soliton, n_blocks_sent)

    drops = Vector{Union{Nothing, WaterDrop}}(nothing, n_blocks_sent)

    for i in 1:n_blocks_sent
        degree = degrees[i]
        seed = UInt32(i)
        indices = generate_indices(seed, n_blocks, degree)
        mixed = foldl((a, b) -> a .⊻ b,
            map(i -> get_block(data, PACKET_SIZE, i), indices);
            init=zeros(UInt8, PACKET_SIZE))
        drops[i] = WaterDrop(seed, UInt32(degree), mixed)
    end

    (drops, n_blocks)
end
