export Layer, forward!, backward!

"A fully-connected layer"
mutable struct Layer
    weights::Matrix{Float64}  # W
    biases::Matrix{Float64}  # b
    activation_fn::Function  # σ
    grad_fn::Function  # ∇σ, or dy/dz

    # Varying
    inputs::Matrix{Float64}  # x
    weighted_sums::Matrix{Float64}  # z = W * x
    activations::Matrix{Float64}  # y = σ(z)
end

# Weight initialization:
#
# - The mean of the activations should be zero.
# - The variance of the activations should stay the same across every layer.
function Layer(
    sz::Tuple{Int, Int};
    activation_fn::Function = identity,
    grad_fn::Function = (_, _) -> 1.0,
)
    (n_out, n_in) = sz
    weights = randn(n_out, n_in) .* sqrt(2.0 / (n_out + n_in))  # Xavier initialization
    biases = zeros(n_out, 1)

    inputs, weighted_sums, activations = map(1:3) do _
        Matrix{Float64}(undef, 0, 0)
    end

    Layer(weights, biases, activation_fn, grad_fn,
        inputs, weighted_sums, activations)
end

"""
Does the forward pass.

x: n_in × batch_size
Return value: n_out × batch_size
"""
function forward!(l::Layer, x::AbstractMatrix{Float64}; training::Bool=true)::Matrix{Float64}
    (d, n) = size(x)

    W, b, σ = l.weights, l.biases, l.activation_fn
    z = W * x .+ b
    y = σ.(z)

    if training
        l.inputs = x
        l.weighted_sums = z
        l.activations = y
    end

    y
end

# Learning
# --------
#
# Computes gradients by back-propagation, optimizes with (stochastic) gradient descent.
#
# - Connection: Node (i) -> Node (j)
# - e: error, computed by loss/cost function
# - z: weighted sum, y: activation. y = σ(z). z is logit if σ is sigmoid
# - ∇σ: a function to compute dy/dz that takes arguments of both z and y
#
# Computes `∂e/∂y_i`:
#
#     ∂e/∂y_i = Σ_j w_{ji} ∂e/∂z_j
#     ∂e/∂z_j = ∂e/∂y_j ⋅ ∂y_j/∂z_j
#
#     ⟹
#
#     ∂e/∂y_i = Σ_j w_{ji} ∂e/∂y_j ⋅ ∇σ(z_j, y_j)
#
# Computes `Δw_{ji}` after obtaining `∂e/∂y_i`:
#
#     Δw_{ji} = -η (∂e/∂w_{ji})
#             = -η (∂e/∂z_j) y_i
#     ∂e/∂z_j = ∂e/∂y_j ⋅ ∂y_j/∂z_j
#
#     ⟹
#
#     Δw_{ji} = -η (∂e/∂z_j) y_i
#             = -η (∂e/∂y_j ⋅ ∇σ(z_j, y_j)) y_i
#
# Here the weights are updated layer by layer. In Flux, they are handled in a holistic manner so the
# code is much more concise there.

"""
Given ∂e/∂y of the next layer, does back-propagation, and returns ∂e/∂y of this layer."

∂e_over_∂y: n_out × batch_size
Return value: n_in × batch_size
"""
function backward!(l::Layer, ∂e_over_∂y::AbstractMatrix{Float64}, η::Float64)::Matrix{Float64}
    # Architecture: Layer i -> Layer j. BP: Layer j ⋯> Layer i
    W, b = l.weights, l.biases
    y_i, z_j, y_j = l.inputs, l.weighted_sums, l.activations
    ∇σ, ∇y_j = l.grad_fn, ∂e_over_∂y

    ∇σ_j = ∇σ.(z_j, y_j)
    ∇z_j = ∇y_j .* ∇σ_j
    ∇y_i = W' * ∇z_j
    ∇W = ∇z_j * y_i'  # sum of all data in the batch
    ∇b = sum(∇z_j, dims=2)
    W .-= η * ∇W
    b .-= η * ∇b
    ∇y_i
end
