using Test

using MultilayerPerceptron

@testset "Xor" begin
    N = 1000

    inputs = unique(Iterators.product(0:1, 0:1))
    train_x = hcat(map(ab -> [Float64.(ab)...], inputs)...)
    train_y = reshape(map(((a, b),) -> Float64(a ⊻ b), inputs), 1, :)

    hidden_layer = Layer((2, 2); activation_fn=tanh, grad_fn=∇tanh)
    output_layer = Layer((1, 2))

    mlp = MLP([hidden_layer, output_layer])
    fit!(mlp, train_x, train_y; learning_rate=0.1, batch_size=2, n_epochs=N)

    test_x, test_y = train_x, train_y
    @test round.(Int, predict(mlp, Float64.(test_x))) == test_y
end
