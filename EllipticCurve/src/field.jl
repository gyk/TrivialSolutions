export
    Field, f_inner_type, f_from,
    f_zero, f_one, f_add, f_neg, f_sub, f_mul, f_inv, f_div, f_pow,
    PrimeField, RealField, RationalField

# Dynamic PLs can model this more concisely. An example in Python:
# <https://jeremykun.com/2014/03/13/programming-with-finite-fields/>.

#===== Field =====#
abstract type Field{T} end

function f_inner_type(f::Field{T})::Type where T
    T
end

@inline function f_from(f::Field{T}, x::T) where T
    x
end

@inline function f_zero(f::Field{T})::T where T
    zero(T)
end

@inline function f_one(f::Field{T})::T where T
    one(T)
end

@inline function f_add(_f::Field{T}, a::T, b::T) where T
    a + b
end

@inline function f_neg(_f::Field{T}, a::T) where T
    -a
end

@inline function f_sub(f::Field{T}, a::T, b::T) where T
    f_add(f, a, f_neg(f, b))
end

@inline function f_mul(_f::Field{T}, a::T, b::T)::T where T
    a * b
end

@inline function f_inv(_f::Field{T}, a::T) where T
    inv(a)
end

@inline function f_div(f::Field{T}, a::T, b::T) where T
    f_mul(f, a, f_inv(f, b))
end

function f_pow(f::Field{T}, a::T, p::Int) where T
    acc = f_one(f)
    while p != 0
        if p & 1 != 0
            acc = f_mul(f, acc, a)
        end
        a = f_mul(f, a, a)
        p >>= 1
    end
    acc
end

#===== Prime Field =====#
"GF(p)"
struct PrimeField{T<:Integer} <: Field{T}
    p::T
end

function f_from(f::PrimeField{T}, x::T) where T
    mod(x, f.p)
end

function f_add(f::PrimeField{T}, a::T, b::T)::T where T
    mod(a + b, f.p)
end

function f_neg(f::PrimeField{T}, a::T)::T where T
    mod(-a, f.p)
end

function f_mul(f::PrimeField{T}, a::T, b::T)::T where T
    # Uses Egyptian multiplication to prevent overflow.
    res = zero(T)
    m = f.p
    while a != 0
        if a & 1 != 0
            if b >= m - res
                res -= m
            end
            res += b
        end
        a >>= 1

        temp_b = b
        if b >= m - b
            temp_b -= m
        end
        b += temp_b
    end
    res
end

function f_inv(f::PrimeField{T}, a::T)::T where T
    m = f.p
    mod(gcdx(a, m)[2], m)
end

function f_pow(f::PrimeField{T}, a::T, p::Int) where T
    powermod(a, p, f.p)
end

#===== Real Field =====#
struct RealField{T<:AbstractFloat} <: Field{T}
end

#===== Rational Field =====#
struct RationalField{T<:Rational} <: Field{T}
end
