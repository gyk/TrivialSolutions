"""
MT19937 (32 bits)
"""

module MersenneTwister

export MtParam, MtRandom, mt19937_param, extract_number!

# Further reading (why Mersenne Twister sucks):
#
# https://cs.stackexchange.com/questions/50059/why-is-the-mersenne-twister-regarded-as-good

# Warning: Bad design. The type of parameters should not be fixed so we can easily extend it to the
# 64-bit version.
"Parameters for Mersenne Twister"
struct MtParam
    "Word size"
    w::UInt32  # This field makes no sense

    "Degree of recurrence"
    n::UInt32

    "Middle word"
    m::UInt32

    "Separation point of one word"
    r::UInt32

    "Coefficients of the rational normal form twist matrix"
    a::UInt32

    "TGFSR(R) tempering bitmasks `b`"
    b::UInt32

    "TGFSR(R) tempering bitmasks `c`"
    c::UInt32

    "TGFSR(R) tempering bit shifts `s`"
    s::UInt32

    "TGFSR(R) tempering bit shifts `t`"
    t::UInt32

    "Additional MT tempering bit shifts/masks `u`"
    u::UInt32

    "Additional MT tempering bit shifts/masks `d`"
    d::UInt32

    "Additional MT tempering bit shifts/masks `l`"
    l::UInt32

    "(Not part of the algorithm)"
    f::UInt32
end

function mt19937_param()::MtParam
    (w, n, m, r) = (UInt32(32), UInt32(624), UInt32(397), UInt32(31))
    a = 0x9908_B0DF
    (u, d) = (UInt32(11), 0xFFFF_FFFF)
    (s, b) = (UInt32(7), 0x9D2C_5680)
    (t, c) = (UInt32(15), 0xEFC6_0000)
    l = UInt32(18)
    f = 0x6c07_8965

    MtParam(
        w, n, m, r,
        a, b, c,
        s, t,
        u, d, l,
        f,
    )
end

mutable struct MtRandom
    param::MtParam
    state::Vector{UInt32}
    index::UInt32
    lower_mask::UInt32
    upper_mask::UInt32

    function MtRandom(seed::UInt32 = UInt32(5489), param::MtParam = mt19937_param())
        index = UInt32(0)  # Rust has got `NonNull`, but inferior PLs don't.
        lower_mask = (UInt32(1) << param.r) - UInt32(1)
        upper_mask = ~lower_mask
        @assert UInt32((1 << param.w) - 1) == upper_mask | lower_mask

        state = zeros(UInt32, param.n)
        state[1] = seed
        for i in UInt32(2) : param.n
            state[i] = param.f * (state[i - 1] ⊻ (state[i - 1] >> (param.w - 2))) + (i - UInt32(1))
        end

        new(param, state, index, lower_mask, upper_mask)
    end
end

function extract_number!(mt::MtRandom)::UInt32
    if iszero(mt.index)
        twist!(mt)
    end

    y = mt.state[mt.index]
    y ⊻= (y >> mt.param.u) & mt.param.d
    y ⊻= (y << mt.param.s) & mt.param.b
    y ⊻= (y << mt.param.t) & mt.param.c
    y ⊻= (y >> mt.param.l)

    mt.index = (mt.index + UInt32(1)) % (mt.param.n + UInt32(1))
    y
end

function twist!(mt::MtRandom)
    @inbounds for i in 1:mt.param.n
        x = (mt.state[i] & mt.upper_mask) |
            (mt.state[mod1(i + 1, mt.param.n)] & mt.lower_mask)
        xA = x >> 1
        if isodd(x)
            xA ⊻= mt.param.a
        end
        mt.state[i] = mt.state[mod1(i + mt.param.m, mt.param.n)] ⊻ xA
    end
    mt.index = UInt32(1)
end

end  # module
