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
