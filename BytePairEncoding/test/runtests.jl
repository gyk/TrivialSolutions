using Test

using BytePairEncoding

include("prepare_data.jl")

corpus = [
    "This is the Hugging Face Course.",
    "This chapter is about tokenization.",
    "This section shows several tokenizer algorithms.",
    "Hopefully, you will be able to understand how they are trained and generate tokens.",
]

@testset "Smoke" begin
    enc = Encoder(nothing, nothing)
    word_freqs = compute_word_freqs(enc, corpus)
    token_freqs = convert(Dict{Vector{Token}, Int}, word_freqs)
    println("token_freqs = "); display(token_freqs)
    (bpe_merges, vocab) = merge_vocab!(token_freqs, 50)
    @test length(bpe_merges) == 19
    @test length(vocab) == 50

    println("================")
    display(sort!([join(x) for x in vocab[32:end]]))
    println("----------------")

    set_bpe_ranks!(enc, bpe_merges)

    println("Tokenization:")
    display([tokenize_one(enc, "This is not a token.")])
    display([tokenize_one(enc, "This is n0t a t0ken.")])
end

@testset "Pretrained" begin
    token_encoder = load_encoder();
    @assert length(token_encoder) == 50257

    bpe_merges = load_bpe_merges();
    @assert length(bpe_merges) == 50000

    enc = Encoder(token_encoder, bpe_merges)
    text = "Hello!! I'm not Andrej Karpathy. It's 2022. w00t :D 🤗"
    @test tokenize(enc, text) == [
        15496, 3228, 314, 1101, 407, 10948, 73, 509, 5117, 10036, 13, 632, 338, 33160, 13, 266, 405,
        83, 1058, 35, 12520, 97, 245,
    ]
end
