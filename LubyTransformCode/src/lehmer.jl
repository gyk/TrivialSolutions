export Lehmer, random_sample

# MINSTD
const M_BIT_LEN = 31
const M_PLUS_1 = UInt64(2) ^ M_BIT_LEN
const LCG_M = M_PLUS_1 - UInt64(1)  # Mersenne prime, so smaller numbers are always coprime to it
const LCG_A = UInt64(7) ^ 5

"Lehmer RNG, a special case of Linear congruential generator where c = 0."
mutable struct Lehmer
    x::UInt32

    Lehmer(seed::UInt32) = new(seed)
end

function Base.iterate(l::Lehmer, state=l)
    # Fast computes `(a * x) % m` when `m = (2 ^ e - 1)`:
    #
    #     r ⧋ (a * x) % m  s.t. ∃ k: (a * x) = k * m + r
    #
    #     ∃ k: a * x = k * (2 ^ e - 1) + r  ⟹
    #     ∃ k: a * x = k * (2 ^ e) + (r - k)
    #
    # Sometimes, `r - k` is negative, so we have
    #
    #     ∃ k: a * x = (k - 1) * (2 ^ e) + (2 ^ e + r - (k - 1) - 1)
    #
    # Since `r - k << (2 ^ e)`,
    #
    #     k = (a * x) ÷ (2 ^ e)
    #     r = (a * x) % (2 ^ e) + k

    ax = LCG_A * l.x
    k = ax >> 31
    r = (ax & LCG_M) + k
    rr = r + UInt64(1)
    if !iszero(rr & M_PLUS_1)
        r = rr & LCG_M
    end
    l.x = r

    (r, l)
end

UINT32_MAX = typemax(UInt32)

"Randomly samples `k` indices without replacement from 1 to n by Fisher–Yates shuffle."
function random_sample(lehmer::Lehmer, n::UInt32, k::UInt32)::Vector{UInt32}
    samples = collect(UInt32(1):n)

    # Random values from RNG which are greater than `skip_threshold` will be skipped. For dealing
    # with modulo bias.
    for i in 1:k
        n_choices = n - i + 1
        remainder = UINT32_MAX % n_choices
        skip_threshold = UINT32_MAX - (remainder + 1) % n_choices
        j = i + first(Iterators.filter(x -> x <= skip_threshold, lehmer)) % n_choices
        samples[i], samples[j] = samples[j], samples[i]
    end

    samples[1:k]
end

# For testing
function next_lehmer(x::UInt32)::UInt32
    UInt32((LCG_A * x) % LCG_M)
end
