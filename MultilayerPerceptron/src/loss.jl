using LinearAlgebra: Diagonal

# Loss function should return a pair of (e, ∂e/∂ŷ).
export
    mse,
    softmax, log_softmax,
    logit_cross_entropy,
    logit_binary_cross_entropy


"Mean squared error loss"
@inline mse(ŷ, y) = (0.5 * sum((y - ŷ) .^ 2), ŷ - y)

#=====

**Softmax** turns (multinomial) logit into probability:

    softmax(x)_i = exp(x_i) / Σ exp(x_i)

**Cross entropy** evaluates the expected coding length of data following distribution p when a wrong
distribution q is assumed:

    H(p, q) = -E_p[log(q)]
            = -Σ p log(q)
            = H(p) + D_KL(p || q)
            = -Σ p log(p) + Σ p log(p/q)

**Binary cross entropy** is the special case of cross entropy for 2-class classification. It is
applied on a single sigmoid output rather than a vector of size 2 as in the softmax case.

To mitigate numerical instabilities, computing by a composed function (prefixed with "logit_") is
usually preferred:

    logit_cross_entropy(ŷ, y) := cross_entropy(softmax(ŷ), y)
    logit_binary_cross_entropy(ŷ, y) := binary_cross_entropy(logistic(ŷ), y)

Softmax is invariant under translation by the same value in each coordinate. The standard logistic
function is a special case of softmax where one variable is fixed at 0.

=====#


function softmax(x::AbstractMatrix{Float64})::Matrix{Float64}
    max_x = maximum(x, dims=1)
    exp_x = exp.(x .- max_x)
    exp_x ./ sum(exp_x, dims=1)
end

function log_softmax(x::AbstractMatrix{Float64})::Matrix{Float64}
    x_ = x .- maximum(x, dims=1)
    x_ .- log.(sum(exp.(x_), dims=1))
end

#=

Derivation:

    p_i = softmax(y)_i  ⟹
    ∂p_i/∂y_j = [i = j] p_i - p_i p_j

    ∂e/∂y_j = Σ_i ∂e/∂p_i ⋅ ∂p_i/∂y_j

Or in the form of matrix calculus,

    ∂e/∂y = ∂e/∂p ⋅ ∂p/∂y

And

    e = -sum(y .* log(p)) / n  ⟹
    ∂e/∂p = -y / n * (1/p)

Also note that $∂p/∂y ∈ ℜ_{d × d}$, so if mini-batch is used it is impossible to be expressed in
matrix form. We directly write `∂e/∂p ⋅ ∂p/∂y` of one sample as

      (∂e/∂p) ⋅ (diag(p) - p ⋅ p')
    = ∇p .* p - sum(∇p .* p) * p    # a ℜ_d vector

The mini-batch case can be written as

    ... = ∇p .* p - sum(∇p .* p, dims=1) .* p    # a ℜ_{d × n} matrix

=#
function logit_cross_entropy(
    ŷ::AbstractMatrix{Float64},
    y::AbstractMatrix{Float64},
)::Tuple{Float64, Matrix{Float64}}
    n_batches = size(ŷ, 2)
    log_p = log_softmax(ŷ)
    e = -sum(y .* log_p) / n_batches

    p = softmax(ŷ)
    ∇p = @. -y / n_batches * inv(p)
    t = ∇p .* p
    ∇y = t - sum(t, dims=1) .* p

    (e, ∇y)
end

#=
    logit_binary_cross_entropy(ŷ, 0)
        = -log(1 - logistic(ŷ))
        = -log(1 / (1 + exp(ŷ)))
        = -(0 - log(1 + exp(ŷ)))
        = -(ŷ - log(1 + exp(ŷ))) + ŷ
        = -log_logistic(ŷ) + ŷ
=#
function logit_binary_cross_entropy(
    ŷ::AbstractMatrix{Float64},
    y::AbstractMatrix{Bool},
)::Tuple{Float64, Matrix{Float64}}
    @assert size(ŷ, 1) == 1
    t = -log_logistic.(ŷ)
    ny = .!y
    t[ny] .+= ŷ[ny]
    e = sum(t) / size(ŷ, 2)

    ∂t_over_∂y = -∇log_logistic.(ŷ, -t)
    ∂t_over_∂y[ny] .+= 1.0
    ∇y = ∂t_over_∂y

    (e, ∇y)
end


#=

Addendum
--------

The derivation of the gradient of softmax + cross-entropy can be found in:

- https://stats.stackexchange.com/questions/235528/backpropagation-with-softmax-cross-entropy
- https://charlee.li/how-to-compute-the-derivative-of-softmax-and-cross-entropy/
- http://denizyuret.github.io/Knet.jl/stable/softmax/#Softmax-1

Copy the LaTeX here:

$$
\begin{aligned}
\frac{\partial}{\partial z_k}\text{CE} &= \frac{\partial}{\partial z_k}\sum_{j=1}^n
\big(- y_j \log \sigma(z_j) \big) \\  &= -\sum_{j=1}^n y_j \frac{\partial}{\partial z_k} \log
\sigma(z_j) && \cdots \text{addition rule, } -y_j \text{ is constant}\\  &= -\sum_{j=1}^n y_j
\frac{1}{\sigma(z_j)} \cdot \frac{\partial}{\partial z_k} \sigma(z_j) && \cdots \text{chain rule}\\
&= -y_k \cdot \frac{\sigma(z_k)(1-\sigma(k))}{\sigma(z_k)} –  \sum_{j \neq k} y_j \cdot
\frac{-\sigma(z_j)\sigma(z_k)}{\sigma(z_j)} && \cdots \text{consier both }j = k \text{ and } j \neq
k \\  &= -y_k \cdot (1-\sigma(z_k)) + \sum_{j \neq k} y_j \sigma(z_k) \\  &= -y_k + y_k \sigma(z_k)
+  \sum_{j \neq k} y_j \sigma(z_k) \\  &= -y_k + \sigma(z_k) \sum_j y_j.
\end{aligned}
$$

=#
