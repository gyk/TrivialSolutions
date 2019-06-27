"""
Luby Transform Code

# References

- David J. C. MacKay. 2002. Information Theory, Inference & Learning Algorithms (pp. 589-596).
  Cambridge University Press, New York, NY, USA.
- https://franpapers.com/en/algorithmic/2018-introduction-to-fountain-codes-lt-codes-with-python/
"""
module LubyTransformCode

include("lehmer.jl")
include("soliton.jl")
include("core.jl")
include("encode.jl")
include("decode.jl")

end
