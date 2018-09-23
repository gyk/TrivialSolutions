# Counting Inversions
#
# This implementation assumes all the values in the collection are distinct.

function count_inversions_naive(a::AbstractVector)::Int
    cnt = 0
    n = length(a)
    for i in 1:(n - 1)
        cnt += sum(a[i] .> @view a[(i + 1):n])
    end
    cnt
end

"Merge sorts `a` and returns its number of inversions."
function count_inversions_mergesort!(a::AbstractVector)::Int
    aux = zeros(eltype(a), length(a))
    ms_inv_r!(a, aux)
end

function ms_inv_r!(a::AbstractVector, aux::AbstractVector)::Int
    n = length(a)
    if n <= 1
        return 0
    end

    m = div(n, 2)
    cnt = @views ms_inv_r!(a[1:m], aux[1:m]) +
                 ms_inv_r!(a[(m + 1):n], aux[(m + 1):n])

    i = 1
    j = m + 1
    for k in 1:n
        if i > m
            aux[k] = a[j]
            j += 1
        elseif j > n
            aux[k] = a[i]
            i += 1
        elseif a[i] < a[j]
            aux[k] = a[i]
            i += 1
        else
            aux[k] = a[j]
            j += 1
            cnt += m - i + 1
        end
    end
    a .= aux

    cnt
end

# Plargarized from https://stackoverflow.com/a/23201616
function count_inversions_fenwick(a::AbstractVector)::Int
    n = length(a)
    cnt = 0
    count_tree = zeros(Int, n)
    ranks = Dict(v => i for (i, v) in enumerate(sort(a)))
    for x in Iterators.reverse(a)
        r = ranks[x]
        i = r - 1
        while i > 0
            cnt += count_tree[i]
            i -= i & (-i)
        end

        i = r
        while i <= n
            count_tree[i] += 1
            i += i & (-i)
        end
    end
    cnt
end


#===== Unit Tests =====#

using Test
using Random: seed!, shuffle!

@testset "Count inversions" begin
    n = 1000
    seed!()
    a = collect(1:n)
    shuffle!(a)

    n_inversions_naive = count_inversions_naive(a)
    n_inversions_fenwick = count_inversions_fenwick(a)
    n_inversions_mergesort = count_inversions_mergesort!(a)
    @test n_inversions_naive == n_inversions_mergesort == n_inversions_fenwick
    @test issorted(a)
end
