"""
Dancing Links
=============

Finds the first solution of an exact cover problem using Donald Knuth's Dancing Links technique.

References
----------

- The "Dancing Links" paper: https://arxiv.org/pdf/cs/0011047.pdf
- A good tutorial: http://garethrees.org/2007/06/10/zendoku-generation/#section-4
- C implementation: http://maskray.me/blog/2009-11-23-sudoku-with-dancing-links-and-algorithm-x
"""
module DancingLinks

export DLinks, init_headers!, insert!, cover!, uncover!, dlx!

mutable struct DLinks
    L::Vector{Int}
    R::Vector{Int}
    U::Vector{Int}
    D::Vector{Int}

    h::Int
    C::Vector{Int}  # points to the column object
    S::Vector{Int}  # the size of column (number of 1s)
end

"Initializes root and column headers"
function init_headers!(d::DLinks, n_cols::Int)
    d.h = n_cols + 1
    for col in 1 : d.h
        d.L[col] = mod1(col - 1, d.h)
        d.R[col] = mod1(col + 1, d.h)
        d.U[col] = col
        d.D[col] = col
    end
end

function insert!(d::DLinks, cur::Int, left::Int, right::Int, col::Int)
    # Row
    d.L[cur] = left
    d.R[left] = cur

    d.R[cur] = right
    d.L[right] = cur

    # Column
    d.U[cur] = d.U[col]
    d.D[d.U[cur]] = cur

    d.D[cur] = col
    d.U[col] = cur

    # Header
    d.C[cur] = col
    d.S[col] += 1
end

"Removes the column."
function cover!(d::DLinks, col::Int)
    d.R[d.L[col]] = d.R[col]
    d.L[d.R[col]] = d.L[col]

    for r in Loop(d.D, col)
        for c in Loop(d.R, r)
            d.D[d.U[c]] = d.D[c]
            d.U[d.D[c]] = d.U[c]

            d.S[d.C[c]] -= 1
        end
    end
end

"Puts the column back."
function uncover!(d::DLinks, col::Int)
    d.R[d.L[col]] = col
    d.L[d.R[col]] = col

    for r in Loop(d.U, col)
        for c in Loop(d.L, r)
            d.D[d.U[c]] = c
            d.U[d.D[c]] = c

            d.S[d.C[c]] += 1
        end
    end
end

"""
The "Algorithm X".

It's a depth-first search with backtracking.
"""
function dlx!(d::DLinks, O::Vector{Int})::Bool
    if d.R[d.h] == d.h
        return true
    end

    # finds column with the minimum size
    col = begin
        min_col = nothing
        s_min = typemax(Int)
        for col in Loop(d.R, d.h)
            if d.S[col] < s_min
                s_min = d.S[col]
                min_col = col
            end
        end
        min_col
    end

    cover!(d, col)
    push!(O, 0)

    for r in Loop(d.D, col)
        O[end] = r

        for c in Loop(d.R, r)
            cover!(d, d.C[c])
        end

        if dlx!(d, O)
            return true  # only the first
        end

        for c in Loop(d.L, r)
            uncover!(d, d.C[c])
        end
    end

    uncover!(d, col)
    false
end

mutable struct Loop
    circle::Vector{Int}
    cur::Int
    stop::Int

    Loop(circle::Vector{Int}, start::Int) = new(circle, start, start)
end

function Base.iterate(iter::Loop, _state=iter)
    next = iter.circle[iter.cur]
    if next == iter.stop
        nothing
    else
        iter.cur = next
        (iter.cur, iter)
    end
end

include("Sudoku.jl")

end  # module
