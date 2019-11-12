"""
# Cooley–Tukey FFT algorithm

## References

- [clrs]: Cormen, Thomas H., Charles E. Leiserson, Ronald L. Rivest, and Clifford Stein.
  Introduction to algorithms. MIT press, 2009.
- [manber]: Manber, Udi. Introduction to algorithms: a creative approach. Addison-Wesley Longman
  Publishing Co., Inc., 1989.
- [wiki]: https://en.wikipedia.org/wiki/Cooley–Tukey_FFT_algorithm
"""
module FastFourierTransform

using OffsetArrays

export
    Direction, Forward, Backward,
    dft, idft,
    fft_recursive_naive, ifft_recursive_naive,
    fft_recursive, ifft_recursive,
    fft_iterative, ifft_iterative

#=

Primitive nth root of unity (can be either clockwise or counterclockwise):

    w_n = exp(-im * 2π / n)

Cancellation lemma ([clrs] Lemma 30.3):

    w_{n d}^{d k} = exp(-im * 2π * (k d)/(n d)) = w_n^k

Halving lemma ([clrs] Lemma 30.5) (by Cancellation lemma we have $(w_n^k)^2 = w_{n/2}^k$):

      { (w_n^k)^2 for k in 0..(n - 1) }
    = { w_{n/2}^k for k in 0..(n/2 - 1) } ∪ { w_{n/2}^k for k in (n/2)..(n - 1) }
    = { w_{n/2}^k for k in 0..(n/2 - 1) }

Summation lemma ([clrs] Lemma 30.6):

      \sum_{j = 0}^{n - 1} w_n^{j k}
    = ((w_n^k)^n - 1) / (w_n^k - 1)
    = (1^k - 1) / (w_n^k - 1)
    = 0

Danielson–Lanczos(?) lemma ([manber] Eq. 9.8):

    P(x) = P_e(x^2) + x * P_o(x^2)

So the problem of computing (note it's a list instead of a set)

    [ P(w_n^i) for i in 0..(n - 1) ]

reduces to

    [ P_e((w_n^i)^2) + w_n^i * P_o((w_n^i)^2) for i in 0..(n - 1) ]

which by Halving lemma further reduces to (also uses [clrs] Corollary 30.4)

      [ P_e(w_{n/2}^i) + w_n^i * P_o(w_{n/2}^i) for i in 0..(n - 1) ]
    = [ P_e(w_{n/2}^i) + w_n^i * P_o(w_{n/2}^i) for i in 0..(n/2 - 1) ] ++
      [ P_e(w_{n/2}^i) - w_n^i * P_o(w_{n/2}^i) for i in 0..(n/2 - 1) ]

The inverse of DFT matrix `V^(-1)`:

    V_ij(w) = w^{i j}
    V^{-1}_ij(w) = 1/n V_ij(1/w) = 1/n w^{-i j}
    (V V^{-1})_ij(w) = 1/n w_{i k} w^{-k j}  ...(*)

    (*) = 1/n n = 1,  if i = j
    (*) = 1/n n = 1/n \sum_{k = 0}^{n - 1} (k d) = 0,  if i - j = d ≠ 0  (by Summation lemma)

=#

# All `OffsetArray`s are 0-based.

@inline function zero_based(A::AbstractArray)::OffsetArray
    (r, c) = size(A) .- 1
    OffsetArray(A, 0:r, 0:c)
end

@inline function zero_based(v::AbstractVector)::OffsetVector
    OffsetVector(v, 0:(length(v) - 1))
end

function divide(W::OffsetArray{T})::Tuple{OffsetArray{T}, OffsetArray{T}} where T
    (n, nn) = size(W)
    @assert n == nn && n > 1 && iseven(n) "Invalid input"

    W_e = @view parent(W)[1:(n ÷ 2), 1:2:end]
    W_o = @view parent(W)[1:(n ÷ 2), 2:2:end]
    (W_e, W_o) .|> zero_based
end

function divide_vec(
    x::OffsetVector{T}
)::Tuple{OffsetVector{T}, OffsetVector{T}} where T
    n = length(x)
    # `n` can be 1 -- an edge case
    @assert (n == 1) || (n > 1 && iseven(n)) "Invalid input"

    x_e = @view parent(x)[1:2:end]
    x_o = @view parent(x)[2:2:end]
    (x_e, x_o) .|> zero_based
end

function bit_reverse(x::Int, bit_len::Int)::Int
    y = 0
    for i in 1:bit_len
        y <<= 1
        y |= x & 1
        x >>= 1
    end
    y
end

function bit_reverse_copy(a::OffsetVector{T})::OffsetVector{T} where T
    n = length_checked(a)
    bit_len = trailing_zeros(n)
    b = zero(a)
    for i in 0:(n - 1)
        b[bit_reverse(i, bit_len)] = a[i]
    end
    b
end

@enum Direction Forward Backward

function dft_matrix(T::Type, n::Int, dir::Direction)::OffsetArray{Complex{T}}
    W = OffsetArray(Array{Complex{T}, 2}(undef, n, n), 0:(n - 1), 0:(n - 1))

    # Sets `W_ij = exp(-im * 2π * i*j/n)` (forward). It is already O(n^2).
    for i in 0:(n - 1)
        for j in i:(n - 1)
            W[i, j] = W[j, i] =
                if dir == Forward
                    exp((-2π)im * (i * j / n))
                else
                    # (!) Do not put `/ n` here.
                    exp((2π)im * (i * j / n))
                end
        end
    end

    W
end

function dft_vector(T::Type, n::Int, dir::Direction)::OffsetVector{Complex{T}}
    # Sets `w_i = exp(-im * 2π * i/n)` (forward).
    #
    # Type annotation is required for `n == 1`.
    w::Vector{Complex{T}} =
        if dir == Forward
            [exp((-2 * T(π))im * i / n) for i in 0:(n ÷ 2 - 1)]
        else
            # (!) Do not put `/ n` here as unlike `W`, `V[:, 0]` is not 0
            [exp((2 * T(π))im * i / n) for i in 0:(n ÷ 2 - 1)]
        end
    OffsetVector(w, 0:(n ÷ 2 - 1))
end

function length_checked(a::AbstractVector)::Int
    n = length(a)
    @assert ispow2(n) "Coefficient length is not a power of 2"
    n
end

#===== DFT (by direct matrix-vector multiplication) =====#

# Reference implementation, for verification.
function dft(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    W = dft_matrix(T, n, Forward)
    parent(W) * a
end

function idft(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    W = dft_matrix(T, n, Backward)
    parent(W) * a / n
end

#===== FFT (by recursing on DFT matrix) =====#
#
# This section follows the explanation in [manber] 9.6.

function fft_recursive_naive(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    length_checked(a)
    fft_recursive_naive_impl(a, Forward)
end

function ifft_recursive_naive(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    fft_recursive_naive_impl(a, Backward) / n
end

function fft_recursive_naive_impl(
    a::Vector{Complex{T}},
    dir::Direction,
)::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    a = zero_based(a)

    W = dft_matrix(T, n, dir)

    function fft_recursive_naive_r!(
        W::OffsetArray{Complex{T}},
        a::OffsetVector{Complex{T}},
    )::Vector{Complex{T}} where T<:AbstractFloat
        local n = length(a)
        if n == 1
            return [W[0, 0] * a[0]]
        end

        (W_e, W_o) = divide(W)
        (a_e, a_o) = divide_vec(a)

        # Warning: Tricky code. Should also use `W_e` to compute `p_o`, and scales the result with
        # `w`. This is due to the odd sub matrix (`W_o`) no longer holds the recursing property.
        w = parent(W)[1:(n ÷ 2), 2]
        p_e = fft_recursive_naive_r!(W_e, a_e)
        p_o = fft_recursive_naive_r!(W_e, a_o) .* w

        [
            p_e + p_o
            p_e - p_o
        ]
    end

    fft_recursive_naive_r!(W, a)
end

#===== FFT (the "standard" recursive version) =====#

function fft_recursive(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    w = dft_vector(T, n, Forward)
    fft_recursive_r(zero_based(a), w)
end

function ifft_recursive(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    w = dft_vector(T, n, Backward)
    fft_recursive_r(zero_based(a), w) / n
end

function fft_recursive_r(
    a::OffsetVector{Complex{T}},
    w::OffsetVector{Complex{T}},
)::Vector{Complex{T}} where T<:AbstractFloat
    n = length(a)
    if n == 1
        return [a[0]]
    end

    (a_e, a_o) = divide_vec(a)
    (w_e, _) = divide_vec(w)  # relies on DFT matrix's special structure
    p_e = fft_recursive_r(a_e, w_e)
    p_o = fft_recursive_r(a_o, w_e)

    [
        p_e .+ parent(w) .* p_o
        p_e .- parent(w) .* p_o
    ]
end

#===== FFT (the iterative version) =====#

function fft_iterative(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    fft_iterative_impl(a, Forward)
end

function ifft_iterative(a::Vector{Complex{T}})::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    fft_iterative_impl(a, Backward) / n
end

function fft_iterative_impl(
    a::Vector{Complex{T}},
    dir::Direction,
)::Vector{Complex{T}} where T<:AbstractFloat
    n = length_checked(a)
    log2n = trailing_zeros(n)

    a = zero_based(a)
    a = bit_reverse_copy(a)
    w = dft_vector(T, n, dir)

    # The `m` here is actually `1/2 m` in [clrs].
    for s in 1:log2n
        m = 2 ^ (s - 1)
        k = 0
        while k < n
            # butterfly operation
            for i = 0:(m - 1)
                # Indexes `w_{2 ^ s}^i` into vector `w_n`, so its step is `2 ^ (log2n - s)`.
                t = w[(2 ^ (log2n - s)) * i] * a[k + i + m]
                u = a[k + i]
                a[k + i] = u + t
                a[k + i + m] = u - t
            end

            k += m * 2
        end
    end
    parent(a)
end

end # module
