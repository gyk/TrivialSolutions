# Activation funcitons `y = σ(x)` and the corresponding gradient functions `y' = ∇σ(x, y)`.

export
    ∇tanh,
    logistic, ∇logistic,
    relu, ∇relu,
    softplus, ∇softplus,
    ∇cos,
    log_logistic, ∇log_logistic

# tanh: built-in
@inline function ∇tanh(x::Float64, y::Float64)::Float64
    1.0 - y ^ 2
end

@inline function logistic(x::Float64)::Float64
    1.0 / (1.0 + exp(-x))
end

@inline function ∇logistic(x::Float64, y::Float64)::Float64
    y * (1.0 - y)
end

@inline function relu(x::Float64)::Float64
    max(x, 0.0)
end

@inline function ∇relu(x::Float64, y::Float64)::Float64
    x >= 0.0 ? 1.0 : 0.0
end

@inline function softplus(x::Float64)::Float64
    log(1.0 + exp(x))
end

@inline function ∇softplus(x::Float64, y::Float64)::Float64
    logistic(x)
end

# cos: built-in
@inline function ∇cos(x::Float64, y::Float64)::Float64
    -sin(x)
end

@inline function log_logistic(x::Float64)::Float64
    x - softplus(x)
end

@inline function ∇log_logistic(x::Float64, y::Float64)::Float64
    1.0 / (1.0 + exp(x))
end
