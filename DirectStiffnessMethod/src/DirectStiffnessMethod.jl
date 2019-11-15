"""
Direct Stiffness Method
=======================

Plane truss/frame analysis using Direct stiffness method. It currently only supports two types of
beams: truss (both ends are pinned joints) and frame (both ends are fixed joints).

References
----------

- [hibbeler]: Hibbeler, R. C. "Structural Analysis 8th edition." (2012).

"""
module DirectStiffnessMethod

export
    Node, Member,
    JointType, FixedJoint, PinnedJoint, RollerJoint, RollerYJoint, SimpleJoint, FreeJoint,
    EndType, FixedConnection, PinnedConnection, RollerConnection, RollerYConnection,
        SimpleConnection, SimpleYConnection,
    Beam,
    Structure, num_nodes, num_members, node_indices,
    solve

using LinearAlgebra
using SparseArrays

#===== Supports & Connections =====#

"The joint (support) type."
@enum JointType begin
    FixedJoint
    PinnedJoint
    RollerJoint
    RollerYJoint
    SimpleJoint
    FreeJoint
end

"The end (connection) type."
@enum EndType begin
    FixedConnection
    PinnedConnection
    RollerConnection
    RollerYConnection
    SimpleConnection
    SimpleYConnection
end

function join_free_dims(j::JointType)::BitVector
    # The case [1, 1, 0] and [0, 1, 1] (SimpleY) seem very rare in real life.
    if j == FixedJoint
        [0, 0, 0]
    elseif j == PinnedJoint
        [0, 0, 1]
    elseif j == RollerJoint
        [1, 0, 0]
    elseif j == RollerYJoint
        [0, 1, 0]
    elseif j == SimpleJoint
        [1, 0, 1]
    elseif j == FreeJoint
        [1, 1, 1]
    end |> BitVector
end

function end_effective_dims(e::EndType)::BitVector
    # The "Free" connection makes no sense, so it is excluded. The real life connections are mostly
    # "Fixed" and "Pinned".
    if e == FixedConnection
        [1, 1, 1]
    elseif e == PinnedConnection
        [1, 1, 0]
    elseif e == RollerConnection
        [0, 1, 1]
    elseif e == RollerYConnection
        [1, 0, 1]
    elseif e == SimpleConnection
        [0, 1, 0]
    elseif e == SimpleYConnection
        [1, 0, 0]
    end |> BitVector
end

# Both ends must have the same connection type. If one end is pinned and the other is fixed, we
# should use the "condensation method", which has not been implemented here.
function beam_effective_dims(e1::EndType, e2::EndType)::BitVector
    if (e1, e2) == (FixedConnection, FixedConnection)
        [1, 1, 1, 1, 1, 1]
    elseif (e1, e2) == (PinnedConnection, PinnedConnection)
        [1, 0, 0, 1, 0, 0]
    else
        error("unimplemented")
    end |> BitVector
end

#===== Node & Member =====#

"Represents joints, supports, or ends of a member."
struct Node
    id::Int
    x::Float64
    y::Float64
    joint_type::JointType
end

struct Member
    id::Int
    from::Int
    to::Int

    near_end::EndType
    far_end::EndType

    "Young's modulus"
    E::Float64

    "The area"
    A::Float64

    "The area moment of inertia"
    I::Float64
end

#===== Beam =====#

struct Beam
    "The length"
    l::Float64

    "Cosine of the sloping angle"
    λ_x::Float64

    "Sine of the sloping angle"
    λ_y::Float64

    "E * A"
    EA::Float64

    "E * I"
    EI::Float64

    "Effective indices of connection"
    conn_indices::BitVector
end

# Truss beam is treated as a special case of frame beam.
#
#     k_m = EA / l *
#         [
#              1.0    -1.0
#             -1.0     1.0
#         ]
#
#     T =
#     [
#         c       s       0.0     0.0
#         0.0     0.0     c       s
#     ]
#

raw"""
Computes member stiffness matrix $k_m$.

In the local coordinate system, the origin is at the "near" node and X axis extends toward the "far"
node.
"""
function compute_member_k(beam::Beam)::Matrix{Float64}
    l = beam.l
    EA = beam.EA
    EI = beam.EI
    l2 = l * l
    l3 = l * l2

    Symmetric(
        [
            EA / l      0.0         0.0         -EA / l     0.0         0.0
            0.0         12EI / l3   6EI / l2    0.0         -12EI / l3  6EI / l2
            0.0         0.0         4EI / l     0.0         -6EI / l2   2EI / l
            0.0         0.0         0.0         EA / l      0.0         0.0
            0.0         0.0         0.0         0.0         12EI / l3   -6EI / l2
            0.0         0.0         0.0         0.0         0.0         4EI / l
        ],
        :U,
    ) |> Matrix
end

function compute_transform_mat(beam::Beam)::Matrix{Float64}
    (c, s) = (beam.λ_x, beam.λ_y)

    [
        c       s       0.0     0.0     0.0     0.0
        -s      c       0.0     0.0     0.0     0.0
        0.0     0.0     1.0     0.0     0.0     0.0
        0.0     0.0     0.0     c       s       0.0
        0.0     0.0     0.0     -s      c       0.0
        0.0     0.0     0.0     0.0     0.0     1.0
    ]
end

#===== Structure =====#

"Represents a planar structure."
mutable struct Structure
    nodes::Vector{Node}
    members::Vector{Member}
end

@inline function num_nodes(s::Structure)::Int
    length(s.nodes)
end

@inline function num_members(s::Structure)::Int
    length(s.members)
end

function node_indices(node_id::Int)::UnitRange{Int}
    (3 * (node_id - 1) + 1):(3 * node_id)
end

"Creates beams from nodes and members."
function assemble_beam(s::Structure, member_id::Int)::Beam
    mem = s.members[member_id]
    from_node = s.nodes[mem.from]
    to_node = s.nodes[mem.to]

    lx = to_node.x - from_node.x
    ly = to_node.y - from_node.y
    l = sqrt(lx ^ 2 + ly ^ 2)
    λ_x = lx / l
    λ_y = ly / l

    EA = mem.E * mem.A
    EI = mem.E * mem.I

    conn_indices = vcat(end_effective_dims(mem.near_end), end_effective_dims(mem.far_end))
    Beam(l, λ_x, λ_y, EA, EI, conn_indices)
end

raw"""
Computes member global stiffness matrix $k$.
"""

function compute_global_k(
    beam::Beam,
    near_end::EndType=FixedConnection,
    far_end::EndType=FixedConnection,
)::Matrix{Float64}
    # - Displacement transformation matrix `T`, which transforms global displacements to local
    #   displacements.
    # - Member stiffness matrix `k_m`, which transforms local displacements to local forces.
    # - Displacement transformation matrix `T'`, which transforms local forces to global forces.
    #
    # k = T' * k_m * T

    k_m = compute_member_k(beam)
    T = compute_transform_mat(beam)
    selection = beam_effective_dims(near_end, far_end)
    T' * (selection .* k_m * T)
end

raw"""
Assembles structure stiffness matrix $K$.
"""
function assemble_struct_k(s::Structure)::SparseMatrixCSC{Float64}
    n_nodes = num_nodes(s)
    n_members = num_members(s)
    K = sparse([], [], Float64[], 3n_nodes, 3n_nodes)
    for i in 1:n_members
        mem = s.members[i]

        b = assemble_beam(s, i)
        k = compute_global_k(b, mem.near_end, mem.far_end)

        from_node = mem.from
        to_node = mem.to
        indices = [node_indices(from_node); node_indices(to_node)]

        K_view = @view K[indices, indices]
        ix = b.conn_indices
        K_view[ix, ix] .+= k[ix, ix]
    end
    K
end

function free_displacement_indices(s::Structure)::BitVector
    n_nodes = num_nodes(s)
    free_ix = BitVector(undef, 3 * n_nodes)
    for i in 1:n_nodes
        ix = node_indices(i)
        free_ix[ix] = join_free_dims(s.nodes[i].joint_type)
    end
    free_ix
end

#=

The structure stiffness equation (Subscript `k`: known variable; `u`: unknown variable):

    [ f_k     [ K_11 K_12     [ d_u
      f_u ] =   K_21 K_22 ] *   d_k ]

`d_k` is usually 0.

    d_u = K_11^{-1} f_k
    f_u = K_21 d_u

=#

function solve(
    s::Structure,
    loads::AbstractVector{Float64}
)::Tuple{SparseVector{Float64}, SparseVector{Float64}}
    free_disp_ix = free_displacement_indices(s)
    unknown_force_ix = .!free_disp_ix

    K = assemble_struct_k(s)
    K_11 = K[free_disp_ix, free_disp_ix]
    d_u = qr(K_11) \ Vector(loads[free_disp_ix])
    K_21 = K[unknown_force_ix, free_disp_ix]
    f_u = K_21 * d_u

    n_dims = length(free_disp_ix)
    d = sparsevec((1:n_dims)[free_disp_ix], d_u, n_dims)
    f = sparsevec((1:n_dims)[unknown_force_ix], f_u, n_dims)
    (d, f)
end

end # module
