module BitonicSort

"Bitonic sort"
function bitonic_sort!(a::AbstractVector, ascending::Bool=true)
    n = length(a)
    if n == 1
        return
    end
    @assert nextpow(2, n) == n "The length of `a` is not power of 2."
    half_n = n >>> 1

    bitonic_sort!(@view(a[1:half_n]), ascending)
    bitonic_sort!(@view(a[(half_n + 1):n]), !ascending)
    bitonic_merge!(a, ascending)
end

"""
Bitonic merge

**Precondition**: `a` is bitonic.
**Postcondition**: `a` is sorted in given order.
"""
function bitonic_merge!(a::AbstractVector, ascending::Bool=true)
    n = length(a)
    if n == 1
        return
    end
    half_n = n >>> 1

    for i in 1:half_n
        if xor(a[i] < a[i + half_n], ascending)
            a[i], a[i + half_n] = a[i + half_n], a[i]
        end
    end
    bitonic_merge!(@view(a[1:half_n]), ascending)
    bitonic_merge!(@view(a[(half_n + 1):n]), ascending)
end

################################################################

#====
Another bitonic sort implementation using OpenCL-like vectorized operations.
It can serve as a prototype of OpenCL code (or not, since Julia is 1-based).

# Reference

- OpenCL in Action, Matthew Scarpino, Chapter 11
====#

MASK1 = [2, 1, 4, 3]
SWAP = [0, 0, 1, 1]
ADD1 = [1, 1, 3, 3]
MASK2 = [3, 4, 1, 2]
ADD2 = [1, 2, 1, 2]
ADD3 = [1, 2, 3, 4]

# dir: 0 - ascending, 1 - descending
function sort_vector!(a::AbstractVector, dir::Int=0)
    @assert length(a) == 4
    comp = @. xor(Int(a > @view a[MASK1]), dir)
    @. a = @view a[xor(comp, SWAP) + ADD1]
    comp = @. xor(Int(a > @view a[MASK2]), dir)
    a .= view(a, comp * 2 + ADD2)
    comp = @. xor(Int(a > @view a[MASK1]), dir)
    a .= view(a, comp + ADD1)
end

function shuffle2(a::AbstractVector, b::AbstractVector, indices)
    n_a = length(a)
    [
        if i > n_a
            b[i - n_a]
        else
            a[i]
        end
        for i in indices
    ]
end

# dir: 0 - ascending, 1 - descending
function swap_vector!(a::AbstractVector, b::AbstractVector, dir::Int=0)
    @assert length(a) == length(b) == 4
    comp = @. xor(Int(a > b), dir) * 4 + ADD3
    a_copy = copy(a)
    a .= shuffle2(a, b, comp)
    b .= shuffle2(b, a_copy, comp)
end

function bsort8!(arr::AbstractVector, dir::Int=0)
    @assert length(arr) == 8
    a = view(arr, 1:4)
    b = view(arr, 5:8)

    sort_vector!(a, 0)
    sort_vector!(b, 1)
    swap_vector!(a, b, dir)
    sort_vector!(a, dir)
    sort_vector!(b, dir)
end

#===== A full bitonic sort =====#
#
# - bsort_init
# - bsort_stage_n
# - bsort_stage_0
# - bsort_merge
# - bsort_merge_last
#
# (Too lazy to implement it now.)

#===== Unit Tests =====#
using Test
using Random: seed!, shuffle, shuffle!

@testset "Bitonic sort" begin
    n = 2048
    seed!()
    a = collect(1:n)
    shuffle!(a)

    bitonic_sort!(a)
    @test issorted(a)

    a = repeat([1, 2], 64)
    bitonic_sort!(a)
    @test issorted(a)
end

@testset "bsort8" begin
    seed!()
    a = shuffle(1:8)
    bsort8!(a)
    @test issorted(a)
end

end # module
