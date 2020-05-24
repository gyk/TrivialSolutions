using MultilayerPerceptron
using Random: shuffle

using Makie

function sine_example()
    N = 2000

    train_x = (0.0:0.1:(2π + 0.1))' |> collect |> shuffle
    train_y = sin.(train_x)

    hidden_layer1 = Layer((5, 1); activation_fn=logistic, grad_fn=∇logistic)
    hidden_layer2 = Layer((3, 5); activation_fn=logistic, grad_fn=∇logistic)
    output_layer = Layer((1, 3))

    mlp = MLP([hidden_layer1, hidden_layer2, output_layer])
    fit!(mlp, train_x, train_y; learning_rate=0.1, batch_size=5, n_epochs=N)

    test_x = (0.0:0.1:(2π + 0.1))' |> collect
    test_y = sin.(test_x)

    # Make PackageCompiler-precompiled Makie show the window.
    # See https://github.com/JuliaPlots/Makie.jl/issues/300.
    AbstractPlotting.__init__()

    scene = Scene()
    lines!(scene, test_x[:], test_y[:]; color=:blue)
    lines!(scene, test_x[:], predict(mlp, Float64.(test_x))[:]; color=:red)
    scene_legend = legend(scene.plots[2:end], ["sin(x)", "ŷ"])
    vbox(scene, scene_legend)
end

sine_example()
