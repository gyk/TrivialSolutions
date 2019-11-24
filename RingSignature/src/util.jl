"Some utilities"
module Util

import Base: convert

"`BigInt` -> `Vector{UInt8}` conversion"
function convert(::Type{Vector{UInt8}}, x::BigInt)
    sz = div(ndigits(x, base=2) + 8 - 1, 8)
    bytes = UInt8[]
    sizehint!(bytes, sz)
    while x != 0
        push!(bytes, x & 255)
        x >>= 8
    end
    reverse!(bytes)
end

"`Vector{UInt8}` -> `BigInt` conversion"
function convert(::Type{BigInt}, v::Vector{UInt8})
    foldl((acc, b) -> (acc << 8) + b, v; init=big(0))
end

end  # module
