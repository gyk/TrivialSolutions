"""
Archimedes' Approximation of Pi

## References

- https://itech.fgcu.edu/faculty/clindsey/mhf4404/archimedes/archimedes.html
- https://betterexplained.com/articles/prehistoric-calculus-discovering-pi/
"""
module ArchimedesPi

#=

"If an angle of a triangle be bisected and the straight line cutting the angle cut the base also,
the segments of the base will have the same ratio as the remaining sides of the triangle."

-- Euclid's Elements

Let $r = 1$, $OSide_{n} = a$, $ISide_{n} = b$, $OSide_{2n} = x$, $ISide_{2n} = y$, we have

$$
(x / 2) / (a / 2 - x / 2) = 1 / (a / b)  =>
x = a * b / (a + b)
$$

and

$$
(y / 2) / (x / 2) = (b / 2) / y  =>
2 (y ^ 2) = x * b
$$

So the perimeter of circumscribing polygon of 2n sides is (the harmonic mean)

$$
O_{2n} = 2n * OSide_{2n} = 2n / (1 / a + 1 / b) = \frac{2}{1 / I_{n} + 1 / O_{n}}
$$

and the perimeter of inscribing polygon of 2n sides is (the geometric mean)

$$
I_{2n} = 2n * ISide_{2n}
       = 2n * \sqrt{x * b} / \sqrt{2}
       = n * \sqrt{2} * \sqrt{x * b}
       = \sqrt{2} * \sqrt{(OSide_{2n} * n) * (ISide_{n} * n)}
       = \sqrt{2} * \sqrt{(O_{2n} / 2) * I_{n}}
       = \sqrt{I_{n} * O_{2n}}
$$
=#

function calculate_pi(n_digits::Int=100)::BigFloat
    prec = Int(ceil(log2(10) * (n_digits + 1)))  # +1 because pi = 3.(...)
    setprecision(prec * 2) do
        # Starts from a hexagon
        outer = big"2.0" * sqrt(big"3.0")
        inner = big"3.0"
        df = outer - inner

        while true
            outer = big"2.0" / (one(BigFloat) / inner + one(BigFloat) / outer)
            inner = sqrt(inner * outer)

            df = begin
                new_df = outer - inner
                if new_df >= df
                    break
                end
                new_df
            end
        end

        pi_archimedes = (outer + inner) / big"2.0"
        # Still uses the default rounding, intentionally
        setprecision(prec)
        pi_archimedes + big(0)
    end
end

#=
Verifies the answer:

    pi_archimedes = calculate_pi()
    setprecision(precision(pi_archimedes))  # Warning: Set the global BigFloat precision!
    println(pi_archimedes - big(pi))
=#

end # module
