"""
Golden-section Search (https://en.wikipedia.org/wiki/Golden-section_search)
"""
module GoldenSectionSearch

#=
I don't know how to prove the optimality of golden-section search. The explanation on Wikipedia is
not plausible. Referring to the diagram on Wikipedia, let $s = x_2 - x_1, t = x_3 - x_4$, and
without loss of generality, suppose that `x_3 - x_1 = 1`. Also suppose the minimum distributes
uniformly in $(a, b)$. The expected interval length after evaluating $f(x_2)$ and $f(x_4)$ is

    (s + 1/2 * (1 - s - t)) * (1 - t) + (t + 1/2 * (1 - s - t)) * (1 - s)
    s.t. 0 < s < 1, 0 < t < 1 and s + t < 1

The new interval length reaches its minimum when $s = t = 1/2 - ϵ$. However, this setting is greedy
as the search is carried out interatively so it doesn't necessarily lead to the minimum after N
steps. Also note that when $x_2$ is fixed, let $t = min(x_2 - x_1, x_3 - x_2)$, the greedy solution
of $s$ is

$$
s = t + 1/2,  if 0 < t <= 1/4
s = 1 - t,  if 1/4 < t <= 1/2
$$

and the corresponding minimum length of interval is

$$
7 / 8 - t,  if 0 < t <= 1/4
2 t^2 - 2 t + 1,  if 1/4 < t <= 1/2
$$

With this idea one can possibly derive the optimal search scheme but I get stuck here.
=#

const GOLDEN_RATIO = (sqrt(5.0) + 1.0) / 2.0  # ϕ
const GOLDEN_RATIO_INV = GOLDEN_RATIO - 1.0  # 1 / ϕ, or Φ
const GOLDEN_RATIO_INV2 = 1 - GOLDEN_RATIO_INV  # 1 / ϕ²

"""
Find the minimum of a unimodal function `f`.

# Pre-conditions

- The minimum lies within the interval `(a, b)`.
"""
function golden_section_search_minimum(f::Function, a::T, b::T)::T where T <: Number
    tolerance = eps(T)
    # tolerance = 1e-6
    @assert a < b
    l = b - a
    n = Int(ceil(log(l / tolerance) / log(GOLDEN_RATIO)))

    ll = l * GOLDEN_RATIO_INV2
    aa = a + ll
    bb = b - ll
    faa = f(aa)
    fbb = f(bb)

    for i in 1:n
        if faa > fbb
            a = aa
            aa = bb; faa = fbb

            # The following code preserves precision better than
            #
            #     bb = b - (aa - a); fbb = f(bb)
            #
            # Also, if computing the new interval using `+`/`-` you have to break the loop when
            # `a <= aa <= bb <= b` is violated.
            l *= GOLDEN_RATIO_INV
            bb = a + l * GOLDEN_RATIO_INV
            fbb = f(bb)
        else
            b = bb
            bb = aa; fbb = faa
            l *= GOLDEN_RATIO_INV

            # It seems better than
            #
            #     aa = b - l * GOLDEN_RATIO_INV
            #
            # but I don't know the reason.
            aa = a + l * GOLDEN_RATIO_INV2

            faa = f(aa)
        end
    end

    if faa > fbb
        (aa + b) / 2.0
    else
        (a + bb) / 2.0
    end
end

# Smoke tests
@assert golden_section_search_minimum(x -> (x - 2.0) ^ 2, 0.0, 10.0) ≈ 2.0f0
@assert golden_section_search_minimum(x -> x^2 - x - 1.0, -10.0, 10.0) ≈ 0.5f0

end # module
