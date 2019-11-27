"""
Elliptic Curve
==============

References
----------

- https://en.wikipedia.org/wiki/Elliptic_curve
- "An Introduction to the Theory of Elliptic Curves", Joseph H. Silverman
- https://andrea.corbellini.name/2015/05/17/elliptic-curve-cryptography-a-gentle-introduction/
"""
module EllipticCurveCrypto

include("field.jl")

export
    Point, EllipticCurve, is_on_curve,
    ec_zero, ec_add, ec_neg, ec_scalar_mul

struct Point{T}
    x::T
    y::T
end

# `T` might be mutable (e.g. `BigInt`) and compare using object identity by default.
function Base.:(==)(a::Point{T}, b::Point{T}) where T
    a.x == b.x && a.y == b.y
end

function Base.:(≈)(a::Point{T}, b::Point{T}) where T
    a.x ≈ b.x && a.y ≈ b.y
end

"""
Elliptic curve (with characteristic >= 5) `y ^ 2 = x ^ 3 + a * x + b`.
"""
struct EllipticCurve{T}
    field::Field{T}

    a::T
    b::T

    function EllipticCurve(f::F, a::T, b::T) where {T, F<:Field{T}}
        a = f_from(f, a)
        b = f_from(f, b)
        if f_add(f,
            f_mul(f, f_pow(f, a, 3), f_from(f, T(4))),
            f_mul(f, f_pow(f, b, 2), f_from(f, T(27)))) == f_zero(f)
            error("The curve is singular")
        end
        new{T}(f, a, b)
    end
end

function is_on_curve(ec::EllipticCurve{T}, p::Point{T})::Bool where T
    if p == ec_zero(ec)
        return true
    end

    f = ec.field
    a = ec.a
    b = ec.b
    x = p.x
    y = p.y
    lhs = f_pow(f, y, 2)
    rhs = f_add(f,
        f_add(f, f_pow(f, x, 3), f_mul(f, x, a)),
        b)
    lhs == rhs
end

# Zero, also the infinity.
function ec_zero(ec::EllipticCurve{T})::Point{T} where T
    z = f_zero(ec.field)
    Point(z, z)
end

function ec_add(ec::EllipticCurve{T}, p1::Point{T}, p2::Point{T})::Point{T} where T
    f = ec.field
    z = ec_zero(ec)

    s = if p1 == z
        return p2
    elseif p2 == z
        return p1
    elseif p1.x == p2.x
        if f_add(f, p1.y, p2.y) == f_zero(f)
            return z
        else
            # Doubling
            (x, y) = (p1.x, p1.y)
            numer = f_add(f, f_mul(f, f_from(f, T(3)), f_pow(f, x, 2)), ec.a)
            denom = f_mul(f, f_from(f, T(2)), y)
            f_div(f, numer, denom)
        end
    else
        f_div(f, f_sub(f, p2.y, p1.y), f_sub(f, p2.x, p1.x))
    end

    x = f_sub(f, f_mul(f, s, s), f_add(f, p1.x, p2.x))
    y = f_sub(f, f_mul(f, s, f_sub(f, p1.x, x)), p1.y)
    Point(x, y)
end

function ec_neg(ec::EllipticCurve{T}, p::Point{T})::Point{T} where T
    Point(p.x, f_neg(ec.field, p.y))
end

# Double-and-add algorithm
function ec_scalar_mul(ec::EllipticCurve{T}, p::Point{T}, s::Int)::Point{T} where T
    acc = ec_zero(ec)
    while s != 0
        if s & 1 != 0
            acc = ec_add(ec, acc, p)
        end
        p = ec_add(ec, p, p)
        s >>= 1
    end
    acc
end

end # module
