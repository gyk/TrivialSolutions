module Backward

export Var, grad!

mutable struct Var{T<:AbstractFloat} <: AbstractFloat
    value::T
    grad::Union{Nothing, T}
    children::Vector{Tuple{Var{T}, T}}
end

Var(x::T) where T<:AbstractFloat = Var(x, nothing, Tuple{Var{T}, T}[])

function grad!(v::Var)
    if isnothing(v.grad)
        v.grad = sum(partial * grad!(u) for (u, partial) in v.children)
    end
    v.grad
end

import Base: +, -, *, /, ^
function +(u::Var{T}, v::Var{T}) where T<:AbstractFloat
    z = Var(u.value + v.value)
    push!(u.children, (z, one(T)))
    push!(v.children, (z, one(T)))
    z
end
function -(u::Var{T}, v::Var{T}) where T<:AbstractFloat
    z = Var(u.value - v.value)
    push!(u.children, (z, one(T)))
    push!(v.children, (z, -one(T)))
    z
end
function *(u::Var{T}, v::Var{T}) where T<:AbstractFloat
    z = Var(u.value * v.value)
    push!(u.children, (z, v.value))
    push!(v.children, (z, u.value))
    z
end
function /(u::Var{T}, v::Var{T}) where T<:AbstractFloat
    z = Var(u.value / v.value)
    # dz = d(u / v) = (du * v - u * dv) / v^2
    push!(u.children, (z, one(T) / v.value))
    push!(v.children, (z, -u.value / (v.value ^ 2)))
    z
end

function ^(u::Var, k::Int)
    z = Var(u.value ^ k)
    push!(u.children, (z, k * (u.value ^ (k - 1))))
    z
end

function Base.sin(u::Var)
    z = Var(sin(u.value))
    push!(u.children, (z, cos(u.value)))
    z
end
function Base.cos(u::Var)
    z = Var(cos(u.value))
    push!(u.children, (z, -sin(u.value)))
    z
end

function Base.exp(u::Var)
    exp_u = exp(u.value)
    z = Var(exp_u)
    push!(u.children, (z, exp_u))
    z
end
function Base.log(u::Var)
    z = Var(log(u.value))
    push!(u.children, (z, inv(u.value)))
    z
end

end
