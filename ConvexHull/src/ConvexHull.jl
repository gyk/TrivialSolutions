"""
Computes convex hull of 2D points. Assumes non-degenerate inputs.
"""
module ConvexHull

const Point{T} = Tuple{T, T}

raw"""
Classifies whether a point $r$ lies to the left or right of the oriented line $pq$.

Returns:

* -1 if $r$ lies to the left
* 0 if $r$ lies on the line
* 1 if $r$ lies to the right

**Warning**: This computation is not robust. See [Robust Predicates for Computational
Geometry][robust] for details. (If `BigFloat` is used, there is no rounding problems.)

[robust]: http://www.cs.cmu.edu/%7Equake/robust.html
"""
function orient(p::Point{T},
                q::Point{T},
                r::Point{T})::T where T<:AbstractFloat
    pr_x = r[1] - p[1]
    pr_y = r[2] - p[2]
    rq_x = q[1] - r[1]
    rq_y = q[2] - r[2]
    sign(pr_x * rq_y - pr_y * rq_x)
end

# Graham scan
#
# Computational Geometry: Algorithms and Applications, Chapter 1.
function convex_hull_graham_scan!(points::Vector{Point{T}})::Vector{Point{T}} where T<:AbstractFloat
    @assert length(points) >= 3 "Too few points"
    sort!(points)  # in lexical order

    function build_convex_hull(points::AbstractVector{Point{T}})
        n = length(points)
        hull = points[1:2]
        sizehint!(hull, n)

        for i in 3:n
            while true
                if orient(hull[end - 1], hull[end], points[i]) > 0
                    break
                else
                    pop!(hull)
                    if length(hull) < 2
                        break
                    end
                end
            end
            push!(hull, points[i])
        end

        hull
    end

    upper_hull = build_convex_hull(points)
    pop!(upper_hull)
    lower_hull = build_convex_hull(@view points[end:-1:1])
    pop!(lower_hull)

    [upper_hull; lower_hull]
end

# Unsorted version, complexity: O(n^2)
function convex_hull_incremental(points::Vector{Point{T}})::Vector{Point{T}} where T<:AbstractFloat
    n = length(points)
    @assert n >= 3 "Too few points"
    hull = points[1:3]
    if orient(hull[1], hull[2], hull[3]) < 0
        hull[[1, 2]] .= hull[[2, 1]]
    end
    sizehint!(hull, n)

    for i in 4:n
        p = points[i]
        # Vertices inside `[start, stop)` will be removed.
        start::Union{Nothing, Int} = nothing
        stop::Union{Nothing, Int} = nothing
        h_len = length(hull)
        prev_ori = orient(hull[end - 1], hull[end], p) >= 0

        # trying to find two tangent lines
        for (from, to) in ((mod1(i - 1, h_len), i) for i in 1:h_len)
            curr_ori = orient(hull[from], hull[to], p) >= 0
            if !curr_ori && prev_ori
                start = to  # inclusive
                if stop != nothing
                    break
                end
            elseif curr_ori && !prev_ori
                stop = from  # exclusive
                if start != nothing
                    break
                end
            end
            prev_ori = curr_ori
        end

        # Always being on the right side, `p` must be inside the hull.
        if start == nothing
            continue
        end
        # If `start != nothing`, then `stop != nothing`.

        # Note: `start == stop` means no vertices are removed.
        if start <= stop
            splice!(hull, start:(stop - 1), [p])
        else
            # The same as
            #
            #     hull = [hull[stop:(start - 1)]; p]
            #
            # but without allocating extra memory.
            hull[start] = p
            resize!(hull, start)
            deleteat!(hull, 1:(stop - 1))
        end
    end
    hull
end

#===== Unit Tests =====#
using Test
using Random: seed!

function convex_hull_length(hull::Vector{Point{T}})::T where T<:AbstractFloat
    hull2 = circshift(hull, -1)
    map((x, y) -> hypot((x .- y)...), hull2, hull) |> sum
end

@testset "Convex Hull" begin
    seed!()
    n = 100
    a = rand(n, 2)
    points = [tuple(a[i, :]...) for i in 1:n]

    cvh_increm = convex_hull_incremental(points)
    cvh_graham = convex_hull_graham_scan!(points)
    @test convex_hull_length(cvh_increm) ≈ convex_hull_length(cvh_graham)
end
end # module
