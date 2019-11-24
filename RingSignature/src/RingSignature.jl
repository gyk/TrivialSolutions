module RingSignature

#=
Ring signature scheme:

- Uniform and has no center
- Set-up free, no prearranged groups of users
- Signer-ambiguous

# References

- Rivest R.L., Shamir A., Tauman Y. (2001) How to Leak a Secret.
=#

include("util.jl")
include("rsa.jl")

using SHA

using RingSignature.Util

export RingContext, ring_sign, ring_verify

#=
The example code from Wikipedia uses a hash function in place of a symmetric encryption function.

Now that the hash is not reversible, you can't really "solve" the ring equation -- it's more of a
"draw the circles around the arrow after you shoot it" approach. That is, you compute `E_k(u)` for
a randomly genarated `u`, tweak the XOR term, and finally "close the ring" at the signer.

See "Rivest's ring signatures with hashes instead of symmetric encryption"
(<https://crypto.stackexchange.com/q/52608>) for a detailed analysis.
=#

struct RingContext
    n::Int
    upper::BigInt
    rsa_list::Vector{RSA}

    function RingContext(n::Int, key_size::Int)
        upper = big(2) ^ (key_size - 1)
        rsa_list = [RSA(key_size) for _ in 1:n]
        new(n, upper, rsa_list)
    end
end

# Computes `E_k(m)`.
function encrypt(ring_ctx::RingContext, k::Vector{UInt8}, m::BigInt)::BigInt
    m = convert(Vector{UInt8}, m)
    convert(BigInt, sha1(vcat(m, k)))  # Manually digest twice to eliminate concatenation
end

# Computes `y = g_i(x)`.
#
# The original paper uses an extended trap-door function. However, as the hash function is no longer
# strictly equiprobable, it seems OK to use the vanilla trap-door, right?
function trapdoor(ring_ctx::RingContext, i::Int, x::BigInt)::BigInt
    rsa_encrypt(ring_ctx.rsa_list[i], x)
end

# Computes `x = g_s^{-1}(y)`. Only can be called by the signer.
function backdoor(ring_ctx::RingContext, signer::Int, y::BigInt)::BigInt
    rsa_decrypt(ring_ctx.rsa_list[signer], y)
end

function ring_sign(
    ring_ctx::RingContext,
    message::Vector{UInt8},
    signer::Int,
)::Tuple{BigInt, Vector{BigInt}}
    k = sha1(message)

    n = ring_ctx.n
    x = zeros(BigInt, n)

    u = rand(big(0):ring_ctx.upper)
    iv = v = encrypt(ring_ctx, k, u)
    for i in vcat((signer + 1):n, 1:(signer - 1))
        x[i] = rand(big(0):ring_ctx.upper)
        y = trapdoor(ring_ctx, i, x[i])
        v = encrypt(ring_ctx, k, v ⊻ y)
        if i == n
            iv = v
        end
    end
    x[signer] = backdoor(ring_ctx, signer, v ⊻ u)
    (iv, x)
end

function ring_verify(
    ring_ctx::RingContext,
    message::Vector{UInt8},
    sig::Tuple{BigInt, Vector{BigInt}}
)::Bool
    k = sha1(message)
    (v, x) = sig
    n = ring_ctx.n
    y = [trapdoor(ring_ctx, i, x[i]) for i in 1:n]
    v_expected = v
    for i in 1:n
        v = encrypt(ring_ctx, k, v ⊻ y[i])
    end
    v == v_expected
end

end # module
