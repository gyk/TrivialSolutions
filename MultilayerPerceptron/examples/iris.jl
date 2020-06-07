using MultilayerPerceptron

using MLDatasets: Iris
using Random: randperm

function iris_example()
    features = begin
        features = Iris.features()
        normalize!(features)
        features
    end
    (n_features, n_samples) = size(features)
    n_classes = 0
    labels = begin
        labels = Iris.labels()
        label_dict = Dict(label => i for (i, label) in enumerate(Set(labels)))
        n_classes = length(label_dict)
        map(l -> label_dict[l], labels)
    end
    oh_labels = one_hot(labels, n_classes)

    # Prepares training and test set
    n_test = n_samples ÷ 3
    n_train = n_samples - n_test
    ind_train, ind_test = begin
        ind = randperm(n_samples)
        sort(ind[1:n_train]), sort(ind[(n_train + 1):end])
    end
    @assert length(ind_test) == n_test

    train_x = features[:, ind_train]
    train_y = labels[ind_train]
    oh_train_y = oh_labels[:, ind_train]

    test_x = features[:, ind_test]
    test_y = labels[ind_test]
    oh_test_y = oh_labels[:, ind_test]

    # The model contains a single output layer, which is equivalent to logistic regression.
    output_layer = Layer((n_classes, n_features))

    mlp = MLP([output_layer])
    fit!(mlp, train_x, oh_train_y;
        loss_fn=logit_cross_entropy,
        learning_rate=0.2, batch_size=5, n_epochs=200)

    oh_pred_y = softmax(predict(mlp, test_x))
    pred_y = inv_one_hot(oh_pred_y)

    n_correct = sum(pred_y .== test_y)
    println("Accuracy = $(n_correct / n_test)")

    confusion_matrix = oh_test_y * oh_pred_y'
    println("Confusion matrix =")
    display(Float16.(confusion_matrix))

    # The accuracy is usually above 90% (it varies from 70% - ~100%).
end

iris_example()
