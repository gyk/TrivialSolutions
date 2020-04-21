
using Test

using CiphertextStealing
using Random: randstring

@testset "Smoke" begin
    for text_len in 1:100
        plaintext = Vector{UInt8}(randstring(text_len))
        iv = rand(UInt8, 16)
        key = rand(UInt8, 16)

        iv_backup = copy(iv)
        ciphertext = aes_128_cbc_encode_cts!(plaintext, key, iv)
        @test length(ciphertext) == text_len
        @test (text_len > 16) == (iv == iv_backup)
        iv_backup = copy(iv)
        deciphered = aes_128_cbc_decode_cts!(ciphertext, key, iv)
        @test (text_len > 16) == (iv == iv_backup)
        @test deciphered == plaintext
    end
end
