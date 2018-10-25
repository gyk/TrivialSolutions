"""
CORDIC (COordinate Rotation DIgital Computer), a.k.a. Volder's algorithm, for computing `sin` and
`cos` functions efficiently.
"""
module CORDIC

export cordic

# Plagiarizing @njuffa's answer from https://stackoverflow.com/a/23097989/.
#
# These coefficients are obtained by Remez algorithm rather than from Taylor series.
function arctan(x::Float64)::Float64
    # argument reduction:
    #
    # arctan (-x) = -arctan(x)
    # arctan (1/x) = 1/2 * pi - arctan (x), when x > 0
    z = abs(x)
    a = (z > 1.0) ? 1.0 / z : z

    # evaluate minimax polynomial approximation
    s = a * a  # a ^ 2
    q = s * s  # a ^ 4
    o = q * q  # a ^ 8

    # use Estrin's scheme for low-order terms
    p = fma(fma(fma(-0x1.53e1d2a25ff34p-16, s, 0x1.d3b63dbb65af4p-13),
                q,
                fma(-0x1.312788dde0801p-10, s, 0x1.f9690c82492dbp-9)),
            o,
            fma(fma(-0x1.2cf5aabc7cef3p-7, s, 0x1.162b0b2a3bfcep-6),
                q,
                fma(-0x1.a7256feb6fc5cp-6, s, 0x1.171560ce4a483p-5)))

    # use Horner's scheme for high-order terms
    p = fma(fma(fma(fma(fma(fma(fma(fma(fma(fma(fma(fma(p, s,
            -0x1.4f44d841450e1p-5), s,
            +0x1.7ee3d3f36bb94p-5), s,
            -0x1.ad32ae04a9fd1p-5), s,
            +0x1.e17813d66954fp-5), s,
            -0x1.11089ca9a5bcdp-4), s,
            +0x1.3b12b2db51738p-4), s,
            -0x1.745d022f8dc5cp-4), s,
            +0x1.c71c709dfe927p-4), s,
            -0x1.2492491fa1744p-3), s,
            +0x1.99999999840d2p-3), s,
            -0x1.555555555544cp-2) * s, a, a)
    # back substitution based on argument reduction
    r = (z > 1.0) ? (0x1.921fb54442d18p+0 - p) : p
    copysign(r, x)
end

ANGLES = @. arctan(exp2(-(0:27)))
K_VALUES = cumprod(@. 1.0 / sqrt(1.0 + exp2(-(0:2:50))))

"Returns a pair of `(sin(beta), cos(beta))` using CORDIC."
function cordic(beta::Float64, n_iterations::Integer=25)::Tuple{Float64, Float64}
    if beta < -pi / 2.0
        return .-cordic(beta + pi, n_iterations)
    elseif beta > pi / 2.0
        return .-cordic(beta - pi, n_iterations)
    end

    v = [1.0, 0.0]
    angle = ANGLES[1]

    i = 0
    while i < n_iterations
        σ = sign(beta)
        if σ == 0.0
            break
        end

        x = v[1] - σ * ldexp(v[2], -i)
        y = σ * ldexp(v[1], -i) + v[2]
        v = [x, y]
        beta -= σ * angle
        i += 1

        # +1 because the iterating variable starts from 0 (2 ^ 0, 2 ^ (-1), ...).
        if i + 1 > length(ANGLES)
            angle /= 2.0
        else
            angle = ANGLES[i + 1]
        end
    end

    if i > 0
        v *= K_VALUES[min(i, length(K_VALUES))]
    end
    (v[2], v[1])
end

const flatten = Iterators.flatten
function smoke()
    X = range(-pi*4, stop=pi*4, length=800)
    println("arctan error: ", max(@. abs(arctan(X) - atan(X))...))
    println("cordic error: ", max(abs.(flatten(cordic.(X)) .- flatten(sincos.(X)))...))
end

end  # module
