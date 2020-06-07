using MultilayerPerceptron
using Random: seed!, shuffle

using Makie

# Ref: scikit-learn's make_moons
function make_moons(n_samples::Int; noise=0.1)::Tuple{Matrix{Float64}, BitArray}
    seed!()
    n_concave = n_samples ÷ 2
    n_convex = n_samples - n_concave
    🌛 = begin
        angles = LinRange(0, π, n_concave)
        hcat(cos.(angles), sin.(angles))'
    end
    🌜 = begin
        angles = LinRange(0, π, n_convex)
        hcat(1.0 .- cos.(angles), (1.0 - 0.5) .- sin.(angles))'
    end
    X = hcat(🌛, 🌜)
    Y = vcat(falses(n_concave), trues(n_convex))
    X .+= randn(size(X)) * noise

    rnd_ind = shuffle(1:n_samples)
    X = X[:, rnd_ind]
    Y = reshape(Y[rnd_ind], 1, :)

    (X, Y)
end

function moons_example()
    (train_x, train_y) = make_moons(250)

    N = 500
    hidden_layer1 = Layer((3, 2); activation_fn=logistic, grad_fn=∇logistic)
    hidden_layer2 = Layer((3, 3); activation_fn=logistic, grad_fn=∇logistic)
    output_layer = Layer((1, 3))

    mlp = MLP([hidden_layer1, hidden_layer2, output_layer])
    fit!(mlp, train_x, train_y;
        loss_fn=logit_binary_cross_entropy,
        learning_rate=0.2, batch_size=5, n_epochs=N)

    (test_x, test_y) = make_moons(250)
    pred_y = predict(mlp, test_x) .> 0.5

    test_y, pred_y = vec(test_y), vec(pred_y)

    AbstractPlotting.__init__()
    scene = Scene()
    tp, fn, tn, fp =
        @. test_y & pred_y, test_y & (!pred_y), (!test_y) & (!pred_y), (!test_y) & pred_y
    any(tp) && scatter!(scene, test_x[:, tp]'; color=:red)
    any(tn) && scatter!(scene, test_x[:, tn]'; color=:green)
    any(fn) && scatter!(scene, test_x[:, fn]'; color=:red4)
    any(fp) && scatter!(scene, test_x[:, fp]'; color=:green1)
    display(scene)
    println("TP = $(sum(tp)), FN = $(sum(fn)); TN = $(sum(tn)), FP = $(sum(fp))")
end

moons_example()
