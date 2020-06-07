using MultilayerPerceptron

using MLDatasets: MNIST

N_CLASSES = 10

function preprocess(x, y=nothing)
    n = size(x)[end]
    mat_x = reshape(x, :, n)

    if isnothing(y)
        return mat_x
    end

    mat_y = one_hot(y .+ 1, N_CLASSES)  # digits to 1-based labels
    mat_x, mat_y
end

function mnist_example()
    train_x, train_y = preprocess(MNIST.traindata(Float64)...)

    N_EPOCHS = 10
    n_pixels = size(train_x, 1)
    hidden_layer = Layer((32, n_pixels); activation_fn=relu, grad_fn=∇relu)
    output_layer = Layer((N_CLASSES, 32))

    mlp = MLP([hidden_layer, output_layer])
    fit!(mlp, train_x, train_y;
        loss_fn=logit_cross_entropy,
        learning_rate=5.0, batch_size=64, n_epochs=N_EPOCHS)

    test_x, test_y = begin
        test_x, test_y = MNIST.testdata(Float64)
        test_x = preprocess(test_x)
        test_y .+= 1
        test_x, test_y
    end
    n_test = length(test_y)
    n_correct = 0
    for i in 1:n_test
        x = test_x[:, [i]]
        y = test_y[i]
        pred_label = argmax(vec(predict(mlp, x)))
        if pred_label == y
            n_correct += 1
        end
    end
    println("Accuracy = $(n_correct / n_test)")

    # The current configuration achieves comparable accuracy with its Flux counterpart in
    # https://github.com/FluxML/model-zoo (> 95%).
end

mnist_example()
