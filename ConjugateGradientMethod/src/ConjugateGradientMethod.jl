raw"""
# Conjugate Gradient Method

## References

- [wiki]: https://en.wikipedia.org/wiki/Conjugate_gradient_method
- [painless]: Shewchuk, Jonathan Richard. "An introduction to the conjugate gradient method without
  the agonizing pain." (1994): 1.

The derivation in <https://en.wikipedia.org/wiki/Derivation_of_the_conjugate_gradient_method> is
rather complicated and unintuitive, so it's better to go through [painless].
"""
module ConjugateGradientMethod

using LinearAlgebra: norm, I, (⋅)

export conjugate_gradient, conjugate_directions

#=

At first "conjugate" sounds confusing, but it becomes clear after realizing it is actually "$p_i$
and $p_j$ (i ≠ j) are conjugate **w.r.t. $A$**" (while $r_i^T r_j = 0$ for i ≠ j). So the whole
iteration is indeed doing Gram-Schmidt process to find $A$-orthogonal search directions.

Recall some definitions:

    x_* = \sum _{i=1}^{n} α_i p_i  ...mutually conjugate vectors, w.r.t. $A$
    α_i = <p_i, r_i> / <p_i, p_i>_A

    r_i = b - A x_i  ...the residual, negative gradient of $f(x) = 1/2 x^T A x - b^T x$ at $x_i$
    e_i = x_i - x_*  ...the error

Some notes taken from [painless]:

- "In fact, if the search vectors are constructed by conjugation of the axial unit vectors,
  Conjugate Directions becomes equivalent to performing Gaussian elimination."
- In Conjugate Directions, $e_{i + 1}$ is $A$-orthogonal to $p_{i}$. This is equivalent to finding
  the minimum point along $p_i$.
- Conjugate Directions chooses value from $e_i = e_0 + P_i$ that minimizes $<e_0, e_0>_A$, where
  $P_i$ is `span {p_0, p_1, ..., p_{i - 1}}`. (See [painless] 7.3)
- Moreover, not only $<p_{i - 1}, e_i>_A = 0$, but for $i < j$, $<p_i, e_j>_A = 0$ also holds. As
  $p_i^T A e_j = 0$ and $r_j = -A e_j$, we know $p_i$ and $r_j$ are orthogonal.
- Finally, CG is simply a special case of Conjugate Directions where search directions are
  constructed by conjugation of the residuals. This choice makes $r_i^T r_j = 0$ and $p_i^T r_i =
  r_i^T r_i$ and $r_i^T A d_i = d_i^T A d_i$ and $r_{i + 1}$ being $A$-orthogonal to $P_i$, etc.,
  many nice properties, so there is no need to store all the previous search directions for doing
  Gram-Schmidt process.

Recapitulate some derivations of equations:

    α_i = <p_i, r_i> / <p_i, p_i>_A    (CD, given $p_i$, minimization)
        = <r_i, r_i> / <p_i, p_i>_A    (CG, u_i = r_i, c.f. [painless] Eq. 42)

    β_ij = -<u_i, p_j>_A / <p_j, p_j>_A    (CD, Gram-Schmidt, c.f. [painless] Eq. 37)

    β_i := β_{i}{i - 1}
        = -<r_{i + 1}, p_i>_A / <p_i, p_i>_A    (CG, Gram-Schmidt in Krylov subspace)
        = <r_{i + 1}, r_{i + 1}> / <r_i, r_i>    (CD, c.f. [painless] Eq. 43, definition of α_i)

=#

# Just a proof-of-concept. VERY slow.
#
# <https://en.wikipedia.org/wiki/Derivation_of_the_conjugate_gradient_method#The_conjugate_direction_method>
function conjugate_directions(
    A::AbstractMatrix{T},
    b::Vector{T},
)::Vector{T} where T<:AbstractFloat
    n = length(b)
    x = zeros(T, n)
    if norm(b) < eps(T)
        return x
    end

    U = Matrix(T.(I(n)))
    P = zeros(T, n, n)
    u(k::Int) = @view U[:, k]
    p(k::Int) = @view P[:, k]

    r = b
    for i in 1:n
        # Gram-Schmidt orthogonalization, directly translated from its definition.
        t = u(i)
        for j = 1:(i - 1)
            Ap = A * p(j)
            β = -(u(i)' * Ap) / (p(j)' * Ap)
            t += β * p(j)
        end
        p(i) .= t
        Ap = A * p(i)
        α = (p(i)' * r) / (p(i)' * Ap)
        x += α * p(i)
        r -= α * Ap
    end
    x
end

function conjugate_gradient(
    A::AbstractMatrix{T},
    b::Vector{T},
)::Vector{T} where T<:AbstractFloat
    n = length(b)
    x = zeros(T, n)
    if norm(b) < eps(T)
        return x
    end

    r = b - A * x
    p = r
    rr = r ⋅ r

    MAX_ITERS = n * 10
    for i in 1:MAX_ITERS
        Ap = A * p
        α = rr / (p ⋅ Ap)
        x += α * p
        r -= α * Ap
        rr_new = r ⋅ r
        if sqrt(rr_new) < eps(T)
            break
        end
        β = rr_new / rr
        p = r + β * p
        rr = rr_new
    end
    x
end

# TODO: Preconditioning.

end  # module
