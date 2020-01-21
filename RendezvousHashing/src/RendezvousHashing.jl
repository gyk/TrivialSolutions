"""
# Weighted Rendezvous Hashing

## References

- [wiki]: <https://en.wikipedia.org/wiki/Rendezvous_hashing>.
- [wrh]: Jason Resch. "New Hashing Algorithms for Data Storage",
  <http://www.snia.org/sites/default/files/SDC15_presentations/dist_sys/Jason_Resch_New_Consistent_Hashings_Rev.pdf>.
- [wdht]: Christian Schindelhauer, and Gunnar Schomaker. "Weighted distributed hash tables." SPAA
  2005: Proceedings of the 17th Annual ACM Symposium on Parallelism in Algorithms and Architectures,
  July 18-20, 2005, Las Vegas, Nevada, USA ACM, 2005.
"""
module RendezvousHashing

export RvCoordinator, insert_node!, remove_node!, choose_nodes, num_nodes, node_weight

# Bit operations for hashing
const MASK = UInt64(typemax(Int64))
const MAX_HASH = MASK + UInt64(1)


abstract type RvCoordinator end
function insert_node!(coordinator::RvCoordinator, id::String, weight::Float64)
    error("Unimplemented")
end
function remove_node!(coordinator::RvCoordinator, id::String)
    error("Unimplemented")
end
function choose_nodes(
    coordinator::RvCoordinator,
    data::String,
    n::Union{Int, Nothing}=nothing,
)::Vector{String}
    error("Unimplemented")
end
function num_nodes(coordinator::RvCoordinator)::Int
    error("Unimplemented")
end
function node_weight(coordinator::RvCoordinator, id::String)::Float64
    error("Unimplemented")
end


include("wrh.jl")
include("wdht.jl")

end # module
