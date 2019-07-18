"""
Pollard's rho algorithm (https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm)
"""
module PollardRho

#=
According to <https://stackoverflow.com/a/48208795>, Pollard's rho algorithm does not always find
the factors of perfect powers.
=#

function squared_plus_1(n::Integer)
    function f(a::Integer)::Integer
        a2 = powermod(a, 2, n)
        mod(a2 + 1, n)
    end
end

function pollard_rho_factor(n::Integer, f::Function=squared_plus_1(n))::Integer
    # Brent's cycle detection algorithm
    l = 0
    tortoise = hare = 2  # the smallest prime
    cycle_len = 2  # prime gap
    factor = 1
    while factor == 1
        if l == cycle_len
            tortoise = hare
            cycle_len *= 2
            l = 0
        end
        hare = f(hare)
        l += 1
        factor = gcd(hare - tortoise, n)
    end
    factor
end

# Unit tests
using Test

function check_prime(n::Integer)::Bool
    factor = pollard_rho_factor(n)
    n == factor
end

function check_composite(n::Integer)::Bool
    factor = pollard_rho_factor(n)
    1 < factor < n && n % factor == 0
end

@testset "PollardRho" begin
    prime_list = [7, 4567, 15960005471, 1238926361552897]
    composite_list = [
        101 * 103, 1009 * 1013, 10007 * 10009,
        1234567,
        12389263_66_1552897,
    ]
    @test check_prime.(prime_list) |> all
    @test check_composite.(composite_list) |> all
end

end  # module
