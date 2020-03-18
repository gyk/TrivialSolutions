"""
# Homogeneous Coordinate

## References

- http://www.ipb.uni-bonn.de/book-pcv/pdfs/PCV-A-sample-page.pdf (Chapter 5 of Photogrammetric
  Computer Vision. Förstner, Wolfgang, and B. P. Wrobel, 2016.)
- https://wordsandbuttons.online/interactive_guide_to_homogeneous_coordinates.html
"""
module HomogeneousCoordinate

using LinearAlgebra: cross, det, dot, norm

export
    Point, PointH,
    LineSlopeIntercept, LineH,
    is_vertical, dual, normalize!,
    is_point_on_line, line_through_two_points, intersection_of_two_lines, are_collinear,
    cart2homo, homo2cart

#===== Cartesian Coordinate =====#

"Point represented in Cartesian coordinate"
struct Point
    x::Float64
    y::Float64
end

"Line `y = mx + b`"
struct LineSlopeIntercept
    slope::Float64
    intercept::Float64
end

"Line in standard form, i.e., `a x + b y = c`"
struct Line  # Not used
    a::Float64
    b::Float64
    c::Float64
end

function Base.:(≈)(p1::Point, p2::Point)::Bool
    p1.x ≈ p2.x && p1.y ≈ p2.y
end

function Base.:(≈)(l1::LineSlopeIntercept, l2::LineSlopeIntercept)::Bool
    l1.slope ≈ l2.slope && l1.intercept ≈ l2.intercept
end

function is_point_on_line(p::Point, l::LineSlopeIntercept)::Bool
    l.slope * p.x + l.intercept == p.y
end

function line_through_two_points(
    p1::Point,
    p2::Point,
)::Union{Nothing, LineSlopeIntercept}
    inv_dx = inv(p1.x - p2.x)
    if isinf(inv_dx)
        return nothing
    end

    m = (p1.y - p2.y) * inv_dx

    # (p1.y - b) / p1.x == (p2.y - b) / p2.x  ⟹
    # p1.y * p2.x - b * p2.x == p2.y * p1.x - b * p1.x  ⟹
    # (p1.x - p2.x) b == p1.x & p2.y - p1.y * p2.x  ⟹
    b = (p1.x * p2.y - p1.y * p2.x) * inv_dx
    LineSlopeIntercept(m, b)
end

"Determines whether the 3 points are nearly collinear"
function are_collinear(p1::Point, p2::Point, p3::Point)::Bool
    # FIXME:
    # 1. Relative tolerance
    # 2. Or use pairwise `≈`?
    abs(det([
        p1.x p1.y 1.0
        p2.x p2.y 1.0
        p3.x p3.y 1.0
    ])) <= sqrt(eps(Float64))
end

function intersection_of_two_lines(
    l1::LineSlopeIntercept,
    l2::LineSlopeIntercept,
)::Union{Nothing, Point}
    # m1 x + b1 = m2 x + b2  ⟹
    # x = (b2 - b1) / (m1 - m2)

    inv_dm = inv(l1.slope - l2.slope)
    if isinf(inv_dm)
        return nothing
    end
    x = (l2.intercept - l1.intercept) * inv_dm
    y = l1.slope * x + l1.intercept
    Point(x, y)
end

#===== Homogeneous Coordinate =====#

"Point represented in homogeneous coordinate"
struct PointH
    v::Vector{Float64}  # Mutable!
end

function Base.getproperty(p::PointH, name::Symbol)
    if name == :x
        p.v[1]
    elseif name == :y
        p.v[2]
    elseif name == :w
        p.v[3]
    else
        getfield(p, name)
    end
end

"Line `a x + b y + c = 0`"
struct LineH
    v::Vector{Float64}  # Mutable!
end

function Base.getproperty(l::LineH, name::Symbol)
    if name == :a
        l.v[1]
    elseif name == :b
        l.v[2]
    elseif name == :c
        l.v[3]
    else
        getfield(l, name)
    end
end

function is_vertical(l::LineH)::Bool
    iszero(l.b)
end

function Base.:(==)(p1::PointH, p2::PointH)::Bool
    iszero(cross(p1.v, p2.v))
end

function Base.:(==)(l1::LineH, l2::LineH)::Bool
    iszero(cross(l1.v, l2.v))
end

function Base.:(≈)(p1::PointH, p2::PointH)::Bool
    p1.x * p2.y ≈ p1.y * p2.x &&
    p1.y * p2.w ≈ p1.w * p2.y &&
    p1.w * p2.x ≈ p1.x * p2.w
end

function Base.:(≈)(l1::LineH, l2::LineH)::Bool
    l1.a * l2.b ≈ l1.b * l2.a &&
    l1.b * l2.c ≈ l1.c * l2.b &&
    l1.c * l2.a ≈ l1.a * l2.c
end

function Base.isinf(p::PointH)::Bool
    iszero(p.w)
end

function Base.isinf(l::LineH)::Bool
    iszero(l.a ^ 2 + l.b ^ 2)
end

# Euclidean normalization
function normalize!(p::PointH)
    if iszero(p.w)
        error("Cannot normalize point at infinity")
    end

    p.v ./= p.w
end

function normalize!(l::LineH)
    h = hypot(l.a, l.b)

    if iszero(h)
        error("Cannot normalize line at infinity")
    end

    h = if l.c < 0.0
        h
    else
        -h
    end

    l.v ./= h
end

function dual(p::PointH)::LineH
    LineH(p.v)
end

function dual(l::LineH)::PointH
    PointH(l.v)
end

# By definition, the line's equation is `a x + b y + c = 0` and its homogeneous representation is
# `(a, b, c)`, so `(a, b, c) ⋅ (x, y, 1)` should be 0.
function is_point_on_line(p::PointH, l::LineH)::Bool
    iszero(dot(p.v, l.v))
end

# Point P on line L  ⟺  homo(P) ⟂ homo(L)
function line_through_two_points(p1::PointH, p2::PointH)::LineH
    LineH(cross(p1.v, p2.v))
end

function are_collinear(p1::PointH, p2::PointH, p3::PointH)::Bool
    # FIXME:
    # 1. Relative tolerance
    # 2. Or use pairwise `≈`?
    abs(det(hcat(p1.v, p2.v, p3.v))) <= sqrt(eps(Float64))
end

function intersection_of_two_lines(l1::LineH, l2::LineH)::PointH
    PointH(cross(l1.v, l2.v))
end

#===== Conversion =====#

function cart2homo(p::Point)::PointH
    PointH([p.x, p.y, 1.0])
end

function homo2cart(p::PointH)::Union{Nothing, Point}
    if iszero(p.w)
        nothing
    else
        Point(p.x / p.w, p.y / p.w)
    end
end

# Kind of a misnomer...
function cart2homo(l::LineSlopeIntercept)::LineH
    LineH([l.slope, -1.0, l.intercept])
end

function homo2cart(l::LineH)::Union{Nothing, LineSlopeIntercept}
    if iszero(l.b)
        return nothing
    end

    m = -l.a / l.b
    b = -l.c / l.b
    LineSlopeIntercept(m, b)
end

end # module
