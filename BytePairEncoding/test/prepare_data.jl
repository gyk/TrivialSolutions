import Downloads
import JSON

ENCODER_URL = raw"https://openaipublic.blob.core.windows.net/gpt-2/models/124M/encoder.json"
VOCAB_URL = raw"https://openaipublic.blob.core.windows.net/gpt-2/models/124M/vocab.bpe"

ENCODER_FILE = last(splitdir(ENCODER_URL))
VOCAB_FILE = last(splitdir(VOCAB_URL))

function download_datasets(; force = false)
    encoder_path = joinpath(@__DIR__, ENCODER_FILE)
    vocab_path = joinpath(@__DIR__, VOCAB_FILE)

    progress_fn(filename) = (total, now) -> begin
        print("\rDownloading $filename: $now / $total")
        print("\u1b[K")
    end

    if !isfile(encoder_path) || force
        Downloads.download(ENCODER_URL, encoder_path; progress = progress_fn(ENCODER_FILE));
    end
    println()

    if !isfile(vocab_path) || force
        Downloads.download(VOCAB_URL, vocab_path; progress = progress_fn(VOCAB_FILE));
    end
    println()
end

function load_bpe_merges(file_path = joinpath(@__DIR__, VOCAB_FILE))
    Tuple{Token, Token}[
        (
            (l, r) = split(line);
            (convert(Token, l), convert(Token, r))
        )
        for line in Iterators.drop(eachline(file_path), 1)
    ]
end

function load_encoder(file_path = joinpath(@__DIR__, ENCODER_FILE))
    d = JSON.parsefile(file_path; dicttype = Dict{String, Int})
    eot = d["<|endoftext|>"]
    d[String([EOT])] = eot
    delete!(d, "<|endoftext|>")
    d
end
