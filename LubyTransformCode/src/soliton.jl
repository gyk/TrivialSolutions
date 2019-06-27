using LinearAlgebra: normalize!

export Soliton, SolitonIdeal, SolitonRobust, get_probabilities

abstract type Soliton end

#=

Derivation of the ideal soliton distribution:

(See [mackay] Exercise 50.2)

It's easy to see that at the t-th iteration, when t out of K packets have been recovered, the
expected number of packets of degree d reduced to (d - 1) is

$$
h_t(d) (d / (K - t))
$$

So in order to have $\forall i \in \{ 0, ..., K - 1\}, h_t(1) = 1$, we start with $h_0(1) = 1$ and
$h_0(2) = K / 2$. In general,

$$
h_t(d) = (K - t) / ((d - 1) * d)
$$

This can be proved using mathematical induction, that is, because of

$$
h_{t + 1}(d) = h_t(d) * (1 - d / (K - t))   + h_t(d + 1) * ((d + 1) / (K - t))
$$

we can verify the equation holds for d = 2, and by

$$
(K - t) / ((d - 1) * d) * (1 - d / (K - t)) + h_t(d + 1) * ((d + 1) / (K - t)) = (K - (t + 1)) / ((d - 1) * d)
$$

which is simplified to

$$
h_t(d + 1) = (K - t) / (d * (d + 1))
$$

so it holds for d = 2, 3, ..., K.

Also, it's easy to see the soliton distribution sums to 1 by `1/(d * (d - 1)) = 1/(d - 1) - 1/d`.
=#

"The ideal soliton distribution."
struct SolitonIdeal <: Soliton
    probabilities::Vector{Float64}

    function SolitonIdeal(n::Int)
        probabilities = [1 / (k * (k - 1)) for k in 1:n]
        probabilities[1] = 1 / n

        new(probabilities)
    end
end

Base.length(soliton::SolitonIdeal) = length(soliton.probabilities)
Base.getindex(soliton::SolitonIdeal, i::Int) = soliton.probabilities[i]

function get_probabilities(soliton::SolitonIdeal)
    soliton.probabilities
end

const ROBUST_FAILURE_PROB = 0.01

#=

The derivation of the robust soliton distribution is similar to the ideal distribution, but it aims
to have the expected number of 1-degree packets be

$$
h_t(1) = 1 + S
$$

See [mackay] Exercise 50.4 for details.

=#

"The robust soliton distribution."
struct SolitonRobust <: Soliton
    probabilities::Vector{Float64}

    function SolitonRobust(n::Int, delta::Float64=0.01)
        # $S ≈ 2$ in [mackay] Eq. (50.4)
        m = n ÷ 2 + 1
        probabilities = zeros(Float64, n)
        probabilities[1:(m - 1)] = [1 / (i * m) for i in 1:(m - 1)]
        probabilities[m] = log(n / (m * delta)) / m

        ideal_prob = SolitonIdeal(n).probabilities
        probabilities .+= ideal_prob
        normalize!(probabilities, 1)

        new(probabilities)
    end
end

Base.length(soliton::SolitonRobust) = length(soliton.probabilities)
Base.getindex(soliton::SolitonRobust, i::Int) = soliton.probabilities[i]

function get_probabilities(soliton::SolitonRobust)
    soliton.probabilities
end
