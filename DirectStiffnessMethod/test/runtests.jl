using Test
using SparseArrays

using DirectStiffnessMethod

# The textbook [hibbeler] still uses backward imperial units, so we have to do some weird
# convertions from time to time.

@testset "[hibbeler] Example 14.3 (truss)" begin
    nodes = [
        Node(1, 3.0, 4.0, FixedJoint)
        Node(2, 0.0, 0.0, FreeJoint)
        Node(3, 3.0, 0.0, FixedJoint)
    ]

    E = 1.0
    A = 1.0
    I = 1.0

    members = [
        Member(1, 2, 3, PinnedConnection, PinnedConnection, E, A, I)
        Member(2, 2, 1, PinnedConnection, PinnedConnection, E, A, I)
    ]

    s = Structure(nodes, members)

    loads = sparsevec(node_indices(2), [0.0, -2.0, 0.0], 3 * num_nodes(s))
    (d, f) = solve(s, loads)

    # Some values from the textbook are not accurate due to early rounding errors.
    @test round.(d, sigdigits=4) == [0.0, 0.0, 0.0, 4.5, -19.0, 0.0, 0.0, 0.0, 0.0]
    @test round.(f, sigdigits=3) == [1.5, 2.0, 0.0, 0.0, 0.0, 0.0, -1.5, 0.0, 0.0]
end

@testset "[hibbeler] Example 16.1 (frame)" begin
    nodes = [
        Node(1, 0.0, 0.0, SimpleJoint)
        Node(2, 20.0 * 12.0, 0.0, FreeJoint)
        Node(3, 20.0 * 12.0, -20.0 * 12.0, FixedJoint)
    ]

    E = 29.0e3
    A = 10.0
    I = 500.0

    members = [
        Member(1, 1, 2, FixedConnection, FixedConnection, E, A, I)
        Member(2, 2, 3, FixedConnection, FixedConnection, E, A, I)
    ]

    s = Structure(nodes, members)

    loads = sparsevec(node_indices(2), [5.0e3, 0.0, 0.0], 3 * num_nodes(s))
    (d, f) = solve(s, loads)

    # Some values from the textbook are not accurate due to early rounding errors.
    @test round.(d / 1000.0, sigdigits=4) ==
        [0.6958, 0.0, 1.234e-3, 0.6958, -1.551e-3, -2.488e-3, 0.0, 0.0, 0.0]
    @test round.(f / 1000.0, sigdigits=3) ==
        [0.0, -1.87, 0.0, 0.0, 0.0, 0.0, -5.0, 1.87, 750.0]
end

@testset "Truss v.s. Frame" begin
    nodes = [
        Node(1, 0.0, 0.0, FixedJoint)
        Node(2, 0.0, 1.0, FreeJoint)
        Node(3, 1.0, 1.0, FreeJoint)
        Node(4, 1.0, 0.0, FixedJoint)
    ]

    # Steel pipe, length = 1m, external diameter = 2cm, internal diameter = 1cm
    ro = 0.01
    ri = 0.005
    E = 200.0e9
    A = pi * (ro ^ 2 - ri ^ 2)
    I = pi / 4 * (ro ^ 4 - ri ^ 4)

    members = [
        Member(1, 2, 1, PinnedConnection, PinnedConnection, E, A, I)
        Member(2, 2, 3, PinnedConnection, PinnedConnection, E, A, I)
        Member(3, 3, 4, PinnedConnection, PinnedConnection, E, A, I)
        Member(4, 1, 4, PinnedConnection, PinnedConnection, E, A, I)
        Member(5, 2, 4, PinnedConnection, PinnedConnection, E, A, I)
        Member(6, 3, 1, PinnedConnection, PinnedConnection, E, A, I)
    ]

    s = Structure(nodes, members)

    loads = sparsevec(node_indices(2), [10.0, 10.0, 0.0], 3 * num_nodes(s))
    (d, f) = solve(s, loads)

    # Manually calculates the internal axial forces
    SQRT2INV = 1.0 / sqrt(2.0)
    iaf = E * A * [
        d[5], d[7] - d[4], d[8], 0.0,
        (-d[4] * SQRT2INV + d[5] * SQRT2INV) * SQRT2INV,
        (d[7] * SQRT2INV + d[8] * SQRT2INV) * SQRT2INV,
    ]

    @test round.(iaf, sigdigits=3) == [14.4, -5.58, -5.58, 0.0, -6.25, 7.89]

    # Uses fixed connections to construct a frame.
    members_frame = [
        Member(1, 2, 1, FixedConnection, FixedConnection, E, A, I)
        Member(2, 2, 3, FixedConnection, FixedConnection, E, A, I)
        Member(3, 3, 4, FixedConnection, FixedConnection, E, A, I)
        Member(4, 1, 4, FixedConnection, FixedConnection, E, A, I)
        Member(5, 2, 4, FixedConnection, FixedConnection, E, A, I)
        Member(6, 3, 1, FixedConnection, FixedConnection, E, A, I)
    ]

    s_frame = Structure(nodes, members_frame)

    (d_frame, f_frame) = solve(s_frame, loads)

    iaf_frame = begin
        d = d_frame
        E * A * [
            d[5], d[7] - d[4], d[8], 0.0,
            (-d[4] * SQRT2INV + d[5] * SQRT2INV) * SQRT2INV,
            (d[7] * SQRT2INV + d[8] * SQRT2INV) * SQRT2INV,
        ]
    end

    # This shows the relative error when modeling a frame as truss is ignorable in real life.
    rel_err = abs.((iaf - iaf_frame) ./ (iaf_frame .+ eps()))
    @test all(rel_err .< 0.01)
    # (Actually, the maximum relative error is about 0.001 in this setting.)
end

@testset "Portal frame" begin
    offset = 0.5
    # Span = 2m, height = 1m
    nodes = [
        Node(1, 0.0, 0.0, FixedJoint)
        Node(2, 0.0, 1.0, FreeJoint)
        Node(3, 1.0 - offset, 1.0, FreeJoint)
        Node(4, 2.0, 1.0, FreeJoint)
        Node(5, 2.0, 0.0, FixedJoint)
    ]

    # Steel pipe, length = 1m, external diameter = 2cm, internal diameter = 1cm
    ro = 0.01
    ri = 0.005
    E = 200.0e9
    A = pi * (ro ^ 2 - ri ^ 2)  # doesn't matter for frame (matters for truss)
    I = pi / 4 * (ro ^ 4 - ri ^ 4)

    members = [
        Member(1, 1, 2, FixedConnection, FixedConnection, E, A, I)
        Member(2, 2, 3, FixedConnection, FixedConnection, E, A, I)
        Member(3, 3, 4, FixedConnection, FixedConnection, E, A, I)
        Member(4, 4, 5, FixedConnection, FixedConnection, E, A, I)
    ]

    s = Structure(nodes, members)

    loads = sparsevec(node_indices(3), [0.0, -100.0, 0.0], 3 * num_nodes(s))
    (d, f) = solve(s, loads)

    d_x = d[1:3:end]
    # When putting a point load on the left half of the horizontal beam, counterintuitively, the
    # frame leans to the left instead of right.
    #
    # Adjust the relative values of E/I and the frame may have negative-X deformation. And in the
    # case of large deformation/flexible beams, the common intuition is right too.
    @test all(d_x .>= 0.0)

    #================

    "Offset of the point load" v.s. "The displacement of the horizontal beam":

    The offset ∈ [0.0, 1.0), and `d = (d[4] + d[10]) / 2` is the average horizontal displacement of
    the beam. It can be seen from the table below that the horizontal displacement reaches its
    maximum when the load placed at approximately 0.6m from the axis of symmetry.


        | offset | d * 1e4 |
        |--------|---------|
        |  0.0   |  0.0    |
        |  0.05  |  1.058  |
        |  0.1   |  2.1    |
        |  0.15  |  3.111  |
        |  0.2   |  4.073  |
        |  0.25  |  4.972  |
        |  0.3   |  5.792  |
        |  0.35  |  6.516  |
        |  0.4   |  7.128  |
        |  0.45  |  7.614  |
        |  0.5   |  7.956  |
        |  0.55  |  8.138  |
        |  0.6   |  8.146  |
        |  0.65  |  7.963  |
        |  0.7   |  7.573  |
        |  0.75  |  6.96   |
        |  0.8   |  6.108  |
        |  0.85  |  5.002  |
        |  0.9   |  3.625  |
        |  0.95  |  1.962  |

    ================#
end
