"""
Operation - Google Code Jam 2017 Finals, Problem B
(https://code.google.com/codejam/contest/6314486/dashboard#s=p1&a=0)

Run the script:

    julia --project src/Operation.jl <in.txt >out.txt
"""

module Operation

using Combinatorics: permutations

p(s::AbstractString) = parse(Int, s)

OP_MAP = Dict(
    "+" => +,
    "-" => -,
    "*" => *,
    "/" => //,
)

function solve!(start::BigInt, card_map::Dict{String, Vector{BigInt}})::Rational{BigInt}
    cards = Tuple{Function, BigInt}[]

    for op in ["+", "-"]
        push!(cards, (OP_MAP[op], sum(card_map[op])))
    end

    z_ind = findall(iszero, card_map["*"])
    if !isempty(z_ind)
        push!(cards, (OP_MAP["*"], 0))
        deleteat!(card_map["*"], z_ind)
    end

    for op in ["*", "/"]
        pd = prod(card_map[op])
        neg_list = filter(x -> x < 0, card_map[op])

        if length(neg_list) == 1
            m = neg_list[1]
            pd //= m
            push!(cards, (OP_MAP[op], m))
        elseif length(neg_list) >= 2
            mi, ma = minimum(neg_list), maximum(neg_list)
            pd //= mi * ma
            push!(cards, (OP_MAP[op], mi))
            push!(cards, (OP_MAP[op], ma))
        end

        push!(cards, (OP_MAP[op], pd))
    end

    reduce(max, (reduce((acc, (op, x)) -> op(acc, x), cs; init = start // big(1))
        for cs in permutations(cards)))
end

function main()
    n_tests = p(readline())
    for t in 1:n_tests
        (start, n_cards) = p.(split(readline()))

        card_map = Dict(op => BigInt[] for (op, _) in OP_MAP)
        for _ in 1:n_cards
            (op, x) = begin
                (op, x) = split(readline())
                (String(op), p(x))
            end
            if op == "+" && x < 0
                (op, x) = ("-", -x)
            elseif op == "-" && x < 0
                (op, x) = ("+", -x)
            end
            push!(card_map[op], x)
        end

        res = solve!(big(start), card_map)
        println("Case #$(t): $(res.num) $(res.den)")
        flush(stdout)
    end
end

main()

end # module
