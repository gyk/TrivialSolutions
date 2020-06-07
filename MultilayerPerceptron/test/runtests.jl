using Test

using MultilayerPerceptron

#===== Helpers =====#
function cross_entropy(ŷ::AbstractMatrix{Float64}, y::AbstractMatrix{Float64})::Float64
    n_batches = size(ŷ, 2)
    -sum(@. y * log(ŷ)) / n_batches
end

function binary_cross_entropy(ŷ::Float64, y::Bool)::Float64
    ϵ = eps(ŷ)
    -log(ϵ + (y ? ŷ : 1.0 - ŷ))
end

# https://math.stackexchange.com/a/2503773
function ∇binary_cross_entropy(ŷ::Float64, y::Bool)::Float64
    let y = Float64(y)
        (ŷ - y) / (ŷ - ŷ * ŷ)
    end
end

@testset "Activation" begin
    sz = (5, 3)
    y = rand(Float64, sz) * 10
    ŷ = rand(Float64, sz) * 10
    (e, _) = logit_cross_entropy(ŷ, y)
    @test e ≈ cross_entropy(softmax(ŷ), y)

    len = 5
    ŷ = rand(Float64, 1, len)
    y = rand(Bool, 1, len)
    (e, ∇) = logit_binary_cross_entropy(ŷ, y)
    logistic_ŷ = logistic.(ŷ)
    @test e ≈ sum(binary_cross_entropy.(logistic_ŷ, y)) / len
    @test ∇ ≈ @. ∇binary_cross_entropy(logistic_ŷ, y) * ∇logistic(ŷ, logistic_ŷ)
end

@testset "Xor" begin
    N = 1000

    inputs = unique(Iterators.product(0:1, 0:1))
    train_x = hcat(map(ab -> [Float64.(ab)...], inputs)...)
    train_y = reshape(map(((a, b),) -> Float64(a ⊻ b), inputs), 1, :)

    hidden_layer = Layer((2, 2); activation_fn=tanh, grad_fn=∇tanh)
    output_layer = Layer((1, 2))

    mlp = MLP([hidden_layer, output_layer])
    fit!(mlp, train_x, train_y; learning_rate=0.2, batch_size=2, n_epochs=N)

    test_x, test_y = train_x, train_y
    @test round.(Int, predict(mlp, Float64.(test_x))) == test_y
end
