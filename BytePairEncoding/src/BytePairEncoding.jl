"""
Byte-Pair Encoding

## References

- https://github.com/karpathy/minGPT/blob/master/mingpt/bpe.py
- https://huggingface.co/learn/nlp-course/chapter6/5
- http://ethen8181.github.io/machine-learning/deep_learning/subword/bpe.html

"""
module BytePairEncoding

export Encoder,
    Token,
    EOT,
    set_bpe_ranks!,
    compute_word_freqs,
    merge_vocab!,
    tokenize_one,
    tokenize

using OffsetArrays
import IterTools

"End of Text"
const EOT = Char(0xFFF)

function iter_pairs(word)
    IterTools.partition(word, 2, 1)
end

function reverse_mapping(m)
    Dict(x => i for (i, x) in pairs(m))
end

function bytes_to_unicode()::AbstractVector{Int}
    bytes = OffsetArray([i - 1 for i in 1:256], -1)
    flags = OffsetArray(trues(256), -1)

    for rg ∈ [Int('!'):Int('~'), Int('¡'):Int('¬'), Int('®'):Int('ÿ')]
        flags[rg] .= false
    end

    bytes[flags] .= 255 .+ (1:sum(flags))
    bytes
end

const PATTERN = begin
    alternatives = [
        "'s", "'t", "'re", "'ve", "'m", "'ll", "'d",
        raw" ?\p{L}+",
        raw" ?\p{N}+",
        # optional space, then 1+ things that are NOT a whitespace, letter or number
        raw" ?[^\s\p{L}\p{N}]+",
        # 1+ whitespace characters (e.g. space or tab) UNLESS they are followed by non-whitespace
        raw"\s+(?!\S)",
        raw"\s+",
    ]
    join(alternatives, "|") |> Regex
end

function bpe(tokens, bpe_ranks)
    while true
        p = iter_pairs(tokens)
        if isempty(p)
            break
        end

        bigram = argmin(x -> get(bpe_ranks, x, typemax(Int)), p)
        if !haskey(bpe_ranks, bigram)
            break
        end

        old_len = length(tokens)
        tokens = merge(tokens, bigram)
        @assert length(tokens) < old_len
    end
    tokens
end

const Token = Union{Char, Vector{Char}}

function Base.convert(::Type{Token}, s::AbstractString)
    a = collect(s)
    if length(a) == 1
        only(a)
    else
        a
    end
end

function merge(tokens::Vector{<:Token}, pair::Tuple{<:Token, <:Token})::Vector{Token}
    new_tokens = Token[]
    i = 1
    while i <= length(tokens)
        if (tokens[i], get(tokens, i + 1, nothing)) == pair
            push!(new_tokens, [tokens[i]..., tokens[i + 1]...])
            i += 2
        else
            push!(new_tokens, tokens[i])
            i += 1
        end
    end
    new_tokens
end

mutable struct Encoder
    byte_encoder::Dict{UInt8, Char}
    byte_decoder::Dict{Char, UInt8}

    token_encoder::Union{Dict{String, Int}, Nothing}
    token_decoder::Union{Dict{Int, String}, Nothing}

    bpe_ranks::Union{Dict{Tuple{Token, Token}, Int}, Nothing}

    pattern::Regex

    function Encoder(
        token_encoder::Union{Dict{String, Int}, Nothing},
        bpe_merges::Union{Vector{Tuple{Token, Token}}, Nothing}
    )
        b2u_mapping = bytes_to_unicode()
        byte_encoder = Dict(UInt8(b) => Char(u) for (b, u) in pairs(b2u_mapping))
        byte_decoder = Dict(Char(u) => UInt8(b) for (b, u) in pairs(b2u_mapping))

        token_decoder = if isnothing(token_encoder)
            nothing
        else
            reverse_mapping(token_encoder)
        end

        bpe_ranks = if isnothing(bpe_merges)
            nothing
        else
            reverse_mapping(bpe_merges)
        end

        new(
            byte_encoder,
            byte_decoder,

            token_encoder,
            token_decoder,

            bpe_ranks,
            PATTERN,
        )
    end
end

function set_bpe_ranks!(enc::Encoder, bpe_merges::Union{Vector{Tuple{Token, Token}}, Nothing})
    enc.bpe_ranks = reverse_mapping(bpe_merges)
end

function compute_word_freqs(enc::Encoder, corpus::AbstractVector{String})
    freqs = Dict{Vector{Char}, Int}()
    for text ∈ corpus
        for m ∈ eachmatch(enc.pattern, text)
            s = m.match

            bytes = Vector{UInt8}(s)
            s_u = map(bytes) do b
                enc.byte_encoder[b]
            end

            freqs[s_u] = get(freqs, s_u, 0) + 1
        end
    end
    freqs
end

function alphabet_from_tokens(d)
    alphabet = Token[]
    append!(alphabet, unique(x for x in Iterators.flatten(keys(d))))
    push!(alphabet, EOT)
    alphabet
end

function compute_pair_freqs(token_freqs::Dict{Vector{Token}, Int})
    freqs = Dict{Tuple{Token, Token}, Int}()
    for (word, cnt) ∈ token_freqs
        for bigram ∈ iter_pairs(word)
            freqs[bigram] = get(freqs, bigram, 0) + cnt
        end
    end
    freqs
end

function merge_pair!(subword_freqs::Dict{Vector{Token}, Int}, pair::Tuple{Token, Token})
    xformed = Dict{Vector{Token}, Int}()
    for (word, cnt) ∈ subword_freqs
        new_word = merge(word, pair)
        if new_word != word
            xformed[new_word] = get(xformed, new_word, 0) + cnt
            delete!(subword_freqs, word)
        end
    end
    mergewith!(+, subword_freqs, xformed)
end

function merge_vocab!(
    subword_freqs::Dict{Vector{Token}, Int},
    vocab_size::Int,
)::Tuple{Vector{Tuple{Token, Token}}, Vector{Token}}
    vocab = alphabet_from_tokens(subword_freqs)
    vocab_size = max(length(vocab), vocab_size)
    merges = Tuple{Token, Token}[]

    while length(vocab) < vocab_size
        pair_freqs = compute_pair_freqs(subword_freqs)
        best_pair = argmax(pair_freqs)
        merge_pair!(subword_freqs, best_pair)
        push!(merges, best_pair)
        push!(vocab, [best_pair[1]..., best_pair[2]...])
    end

    (merges, vocab)
end

function tokenize_one(enc::Encoder, s::String)
    if isnothing(enc.bpe_ranks)
        return nothing
    end

    bytes = Vector{UInt8}(s)
    s_u = map(bytes) do b
        enc.byte_encoder[b]
    end

    bpe(s_u, enc.bpe_ranks)
end

function tokenize(enc::Encoder, text::String)
    res = Int[]
    if isnothing(enc.bpe_ranks) || isnothing(enc.token_encoder)
        return nothing
    end

    for m ∈ eachmatch(enc.pattern, text)
        s = m.match

        bytes = Vector{UInt8}(s)
        s_u = map(bytes) do b
            enc.byte_encoder[b]
        end

        s_u = bpe(s_u, enc.bpe_ranks)
        append!(res, [enc.token_encoder[join(t)] for t in s_u])
    end
    res
end

end # module BytePairEncoding
