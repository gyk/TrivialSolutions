# Minimal implementation of 3-layer MLP that solves Xor problem.

X = [[0, 0], [0, 1], [1, 0], [1, 1]]
Y = (x -> [xor(x...)]).(X)
η = 0.1
W = rand(2, 3)
V = rand(1, 3)
W ∗ x = W * [x; 1]
for _ in 1:1000, (x, y) in zip(X, Y)
    z = W ∗ x
    h = tanh.(z)
    o = V ∗ h
    ∇o = o - y
    ∇h = ∇o * V[:, 1:(end - 1)]
    ∇V = ∇o * [h; 1]'
    ∇W = (@. ∇h * (1.0 - h' ^ 2))' * [x; 1]'
    V .-= η * ∇V
    W .-= η * ∇W
end
predict(x) = round.(Int, V ∗ tanh.(W ∗ x))
@assert predict.(X) == Y
