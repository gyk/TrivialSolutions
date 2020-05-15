"""
A multilayer perceptron.
"""
module MultilayerPerceptron

include("activation.jl")
include("layer.jl")

export MLP, fit!, predict

struct MLP
    layers::Vector{Layer}
end

function MLP(layers::Vector{Tuple{Int, Int}})
    layers = [Layer(sz) for sz in layers]
    MLP(layers)
end

function fit!(
    mlp::MLP,
    train_x::AbstractMatrix{Float64}, train_y::AbstractMatrix{Float64},
    ;
    loss_fn::Function = (ŷ, y) -> 0.5 * sum((y - ŷ) .^ 2),
    ∇loss_fn::Function = (ŷ, y) -> ŷ - y,
    learning_rate::Float64 = 0.001,
    batch_size::Int = 1000,
    n_epochs::Int = 10,
    reporting_interval = 1000,
)
    (_, n) = size(train_x)
    batch_iter = Iterators.partition(1:n, batch_size)
    n_batches = 0
    for epoch in 1:n_epochs
        for cols in batch_iter
            batch_x = @view train_x[:, cols]
            batch_y = @view train_y[:, cols]
            for l in mlp.layers
                batch_x = forward!(l, batch_x)
            end
            batch_ŷ = batch_x

            loss = loss_fn(batch_ŷ, batch_y)
            (n_batches += 1) % reporting_interval == 0 ? println("#$n_batches: $loss") : nothing

            ∂e_over_∂y = ∇loss_fn(batch_ŷ, batch_y)
            for l in Iterators.reverse(mlp.layers)
                ∂e_over_∂y = backward!(l, ∂e_over_∂y, learning_rate)
            end
        end
    end
end

function predict(mlp::MLP, test_x::AbstractMatrix{Float64})::Matrix{Float64}
    x = test_x
    for l in mlp.layers
        x = forward!(l, x; training=false)
    end
    x
end

end
