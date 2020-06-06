# Preprocessing and postprocessing helpers

export normalize!, one_hot, inv_one_hot

function normalize!(x::AbstractArray{Float64})
    (d, n) = size(x)
    @assert n > 1
    μ = sum(x, dims=1) ./ n
    x .-= μ
    σ = @. sqrt($sum(x ^ 2, dims=1) / (n - 1))
    x ./= σ
end

function one_hot(y::AbstractVector{Int}, n_classes::Int)::Matrix{Float64}
    n = length(y)
    one_hot_y = zeros(n_classes, n)
    # Creates one-hot vectors. Better to make it an `AbstractVector`.
    one_hot_y[CartesianIndex.(y, 1:n)] .= 1.0
    one_hot_y
end

function inv_one_hot(y::AbstractMatrix{Float64})::Vector{Int}
    vec(mapslices(argmax, y, dims=1))
end
