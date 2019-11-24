export RSA, rsa_encrypt, rsa_decrypt, coprime_inv_mod

using Primes: nextprime

using RingSignature.Util

struct EGCDResult{T<:Integer}
    "Bézout coefficient x"
    x::T

    "Bézout coefficient y"
    y::T

    "greatest common divisor"
    gcd::T

    "a / gcd"
    quot_a::T

    "b / gcd"
    quot_b::T
end

#=

s` is the coefficient of `a` throughout the process of successive divisions, so is `t` to `b`.

$r_k = a s_k + b t_k$ always holds (easy to prove by induction).

See https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm#Proof for details.

=#
"Extended GCD"
function egcd(a::T, b::T)::EGCDResult{T} where T<:Integer
    (r0, r) = (a, b)
    (s0, s) = (one(T), zero(T))
    (t0, t) = (zero(T), one(T))

    while !iszero(r)
        q = r0 ÷ r
        (r0, r) = (r, r0 - r * q)
        (s0, s) = (s, s0 - s * q)
        (t0, t) = (t, t0 - t * q)
    end

    EGCDResult(s0, t0, r0, t, s)
end

#=
When a and b are coprimes,

    a x + b y = gcd(a, b)  =>  a x = 1 (mod b)
=#

"Precondition: `x` and `m` are coprime"
function coprime_inv_mod(x::T, m::T)::T where T<:Integer
    inv_x = egcd(x, m).x
    inv_x < 0 ? inv_x + m : inv_x
end

"Generates a `n_bits`-bit random prime"
function random_prime(n_bits::Int)::BigInt
    # √2 × 2^(n_bits - 1)
    lower = BigInt(round(2 ^ (n_bits - 0.5)))
    upper = big(2) ^ n_bits - 1
    while true
        p = nextprime(rand(lower:upper))
        if p <= upper
            return p
        end
    end
end

struct RSA
    "Key size in bits"
    key_size::Int

    "The `(e, n)` pair"
    public_key::Tuple{BigInt, BigInt}

    "The `(d, n)` pair"
    private_key::Tuple{BigInt, BigInt}

    function RSA(key_size::Int, e::BigInt=big(65537))
        if key_size % 8 != 0
            error("`key_size` is not a multiple of 8")
        end

        while true
            p = random_prime(key_size ÷ 2)
            q = random_prime(key_size ÷ 2)
            if p == q
                continue
            end

            # Better to use Carmichael's totient
            totient = (p - 1) * (q - 1)
            if egcd(e, totient).gcd != 1
                continue
            end
            # FIXME: also need to check the #bits of `p - q` is enough

            n = p * q
            d = coprime_inv_mod(e, totient)
            pub_key = (e, n)
            pri_key = (d, n)
            return new(key_size, pub_key, pri_key)
        end
    end
end

function rsa_encrypt(rsa::RSA, m::BigInt)::BigInt
    (e, n) = rsa.public_key
    powermod(m, e, n)
end

function rsa_decrypt(rsa::RSA, c::BigInt)::BigInt
    (d, n) = rsa.private_key
    powermod(c, d, n)
end

function rsa_encrypt(rsa::RSA, m_bytes::Vector{UInt8})::Vector{UInt8}
    m = convert(BigInt, m_bytes)
    c = rsa_encrypt(rsa, m)
    convert(Vector{UInt8}, c)
end

function rsa_decrypt(rsa::RSA, c_bytes::Vector{UInt8})::Vector{UInt8}
    c = convert(BigInt, c_bytes)
    m = rsa_decrypt(rsa, c)
    convert(Vector{UInt8}, m)
end
