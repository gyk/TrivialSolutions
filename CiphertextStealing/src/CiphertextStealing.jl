"""
Ciphertext stealing

- Swaps the final two ciphertext blocks unconditionally [^1]
- Uses standard CBC interface [^2]
- In case the plaintext is one block long or less, the IV acts as the prior block and is modified

[^1]: https://en.wikipedia.org/wiki/Ciphertext_stealing#CS3
[^2]: https://en.wikipedia.org/wiki/Ciphertext_stealing#CBC_implementation_notes
"""
module CiphertextStealing

using Nettle: encrypt, decrypt, Encryptor, Decryptor
using PaddedViews: PaddedView

export aes_128_cbc_encode_cts!, aes_128_cbc_decode_cts!

#===== Helpers =====#

function swap!(a::AbstractVector{T}, b::AbstractVector{T}) where T
    for i in eachindex(a, b)
        @inbounds a[i], b[i] = b[i], a[i]
    end
end

function aes_128_ecb_encode(
    plaintext::AbstractVector{UInt8},
    key::AbstractVector{UInt8}
)::Vector{UInt8}
    @assert length(plaintext) % 16 == 0 && length(key) == 16
    enc = Encryptor("AES128", key)
    encrypt(enc, plaintext)
end

function aes_128_ecb_decode(
    ciphertext::AbstractVector{UInt8},
    key::AbstractVector{UInt8}
)::Vector{UInt8}
    @assert length(ciphertext) % 16 == 0 && length(key) == 16
    dec = Decryptor("AES128", key)
    decrypt(dec, ciphertext)
end

#===== The standard AES-128 CBC routine =====#

function aes_128_cbc_encode(
    plaintext::AbstractVector{UInt8},
    key::Vector{UInt8},
    iv::Vector{UInt8},
)::Vector{UInt8}
    @assert length(plaintext) % 16 == 0 && length(key) == 16 && length(iv) == 16

    ciphertext = UInt8[]
    sizehint!(ciphertext, length(plaintext))

    last_block = copy(iv)
    for b in Iterators.partition(plaintext, 16)
        last_block .⊻= b
        last_block = aes_128_ecb_encode(last_block, key)
        append!(ciphertext, last_block)
    end

    ciphertext
end

function aes_128_cbc_decode(
    ciphertext::AbstractVector{UInt8},
    key::Vector{UInt8},
    iv::Vector{UInt8},
)::Vector{UInt8}
    @assert length(ciphertext) % 16 == 0 && length(key) == 16 && length(iv) == 16

    plaintext = UInt8[]
    sizehint!(plaintext, length(ciphertext))

    last_block = iv
    for b in Iterators.partition(ciphertext, 16)
        dec_block = aes_128_ecb_decode(b, key) .⊻ last_block
        append!(plaintext, dec_block)
        last_block = b
    end

    plaintext
end

#===== Ciphertext Stealing =====#

# It will modify IV if the plaintext is one block or shorter.
function aes_128_cbc_encode_cts!(
    plaintext::AbstractVector{UInt8},
    key::Vector{UInt8},
    iv::Vector{UInt8},
)::Vector{UInt8}
    len = length(plaintext)
    @assert len > 0
    padded_len = len + mod(-len, 16)
    ciphertext = aes_128_cbc_encode(PaddedView(UInt8(0), plaintext, (padded_len,)), key, iv)

    ultimate = @view ciphertext[(end - 16 + 1):end]
    penultimate = @views len > 16 ? ciphertext[(end - 16 * 2 + 1):(end - 16)] : iv[:]
    swap!(ultimate, penultimate)
    resize!(ciphertext, len)

    ciphertext
end

# It will modify the penultimate block or (if the ciphertext is one block or shorter) IV.
function aes_128_cbc_decode_cts!(
    ciphertext::AbstractVector{UInt8},
    key::Vector{UInt8},
    iv::Vector{UInt8},
)::Vector{UInt8}
    len = length(ciphertext)
    @assert len > 0
    padding_len = mod(-len, 16)
    ultimate_len = 16 - padding_len
    padded_len = len + padding_len

    cipher_ultimate = @view ciphertext[(end - ultimate_len + 1):end]
    cipher_penultimate =
        if len > 16
            @view ciphertext[(end - ultimate_len - 16 + 1):(end - ultimate_len)]
        else
            @view iv[:]
        end
    decrypt_ultimate = aes_128_ecb_decode(cipher_penultimate, key)  # Performance penalty

    cipher_penultimate[1:ultimate_len] .= cipher_ultimate
    cipher_penultimate[(end - padding_len + 1):end] .= decrypt_ultimate[(end - padding_len + 1):end]

    plaintext = aes_128_cbc_decode(PaddedView(UInt8(0), ciphertext, (padded_len,)), key, iv)
    resize!(plaintext, len)
    plaintext[(end - ultimate_len + 1):end] .= cipher_ultimate .⊻ decrypt_ultimate[1:ultimate_len]

    plaintext
end

end # module
