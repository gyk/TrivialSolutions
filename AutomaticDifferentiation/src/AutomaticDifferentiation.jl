"""
Automatic Differentiation
=========================

## References

- https://en.wikipedia.org/wiki/Automatic_differentiation
- https://github.com/MikeInnes/diff-zoo
- https://rufflewind.com/2016-12-30/reverse-mode-automatic-differentiation
"""

module AutomaticDifferentiation

include("forward.jl")
include("backward.jl")

#=

∂y/∂x can be expressed as (supposing the computation forms a polytree):

$$
{\partial{y} \over \partial{x}} =
  \prod_{i=1}^{n} {\partial{w_i} \over \partial{w_{i-1}}} =
  {\partial{y} \over \partial{w_{n-1}}} \cdot
  {\partial{w_{n-1}} \over \partial{w_{n-2}}} \cdot \ldots \cdot
  {\partial{w_1} \over \partial{x}}
$$

- Forward: Evaluates ∂y/∂x with right association
- Backward: Evaluates ∂y/∂x with left association

=#

end # module
