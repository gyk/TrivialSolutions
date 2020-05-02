module Forward

export Dual, ind_var

struct Dual{T<:AbstractFloat} <: AbstractFloat
    value::T
    grad::T
end

#===== Operations =====#
# https://en.wikipedia.org/wiki/Automatic_differentiation#Automatic_differentiation_using_dual_numbers

import Base: +, -, *, /, ^
u::Dual + v::Dual = Dual(u.value + v.value, u.grad + v.grad)
u::Dual - v::Dual = Dual(u.value - v.value, u.grad - v.grad)
u::Dual * v::Dual = Dual(u.value * v.value, v.value * u.grad + u.value * v.grad)
u::Dual / v::Dual = Dual(u.value * v.value, (v.value * u.grad - u.value * v.grad) / (v.value ^ 2))

Base.sin(u::Dual) = Dual(sin(u.value), u.grad * cos(u.value))
Base.cos(u::Dual) = Dual(cos(u.value), -u.grad * sin(u.value))

Base.exp(u::Dual) = begin
    exp_x = exp(u.value)
    Dual(exp_x, u.grad * exp_x)
end
Base.log(u::Dual) = Dual(log(u.value), u.grad / u.value)

u::Dual ^ k::Int = Dual(u.value ^ k, k * (u.value ^ (k - 1)) * u.grad)

#===== Conversions =====#

function Base.convert(::Type{Dual{T}}, x::Dual) where T
    Dual(convert(T, x.value), convert(T, x.grad))
end

function Base.convert(::Type{Dual{T}}, x::AbstractFloat) where T
    Dual(convert(T, x), zero(T))
end

function Base.promote_rule(::Type{Dual{T}}, ::Type{U}) where {T, U}
    Dual{promote_type(T, U)}
end

"Independent variable"
ind_var(x::AbstractFloat) = Dual(x, one(x))

end
