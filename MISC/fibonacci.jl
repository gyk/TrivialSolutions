"Fibonacci Number"
A = BigInt[0 1; 1 1]
M = [A]

function fib(n::Int)
    if n == 0
        return 0
    end

    log2n = Int(ceil(log2(n)))
    sizehint!(M, log2n)
    while length(M) < log2n
        push!(M, M[end] ^ 2)
    end

    d = digits(Bool, n; base=2, pad=length(M))
    prod(M[d])[2]
end

#=
fib(i) = (A^i * [0; 1])[1]
       = (A^(i-1) * [0; 1])[2]
       = (A^i)[1, 2]
       = (A^(i - 1))[2, 2]
=#
