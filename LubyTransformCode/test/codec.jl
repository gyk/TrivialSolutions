using Test
using LubyTransformCode

@testset "Encoder & Decoder" begin
    data = b"""A fountain (from the Latin "fons" (genitive "fontis"), a source or spring) is a piece
    of architecture which pours water into a basin or jets it into the air to supply drinking water
    and/or for a decorative or dramatic effect."""

    (drops, n_blocks) = encode(data)
    # `drops` is serialized and sent via network.
    decoded = decode(drops, n_blocks)
    if decoded != nothing
        @test decoded[1:length(data)] == data
    else
        println("Decoding failed.")
    end
end
