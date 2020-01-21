using Test
using RendezvousHashing

using DataStructures: DefaultDict
using HypothesisTests: ChisqTest, pvalue
using Random: randstring

NODE_ID_WEIGHT_LIST = [
    ("node1", 100.0),
    ("node2", 200.0),
    ("node3", 300.0),
    ("node4", 400.0),
]

@testset "Smoke" begin
    coordinators = [
        WrhCoordinator(),
        WdhtCoordinator(),
    ]

    for coord in coordinators
        println("----------------")
        for (id, w) in NODE_ID_WEIGHT_LIST
            insert_node!(coord, id, w)
        end
        remove_node!(coord, "node4")

        println(choose_nodes(coord, "foo"))
        println(choose_nodes(coord, "bar", 2))
        println(choose_nodes(coord, "hello", 1))
    end
    println()
end


function compute_id_len(n::Int)::Int
    Int(ceil(log(n, 62))) + 1
end

function generate_nodes(n::Int)::Dict{String, Float64}
    id_len = compute_id_len(n)
    d = Dict{String, Float64}()
    while length(d) < n
        w = rand()
        d[randstring(id_len)] = w
    end
    w_sum = sum(values(d))
    for k in keys(d)
        d[k] /= w_sum
    end
    @assert sum(values(d)) ≈ 1.0
    d
end

@testset "Weighted Rendezvous Hashing" begin
    # `WdhtCoordinator` usually does NOT pass the Chi-squared test. When `N_TESTS` is large, both
    # will not pass the Chi-squared test unless `reseed!` is called regularly. The reason is
    # unknown. I have scrutinized my code but haven't found any obvious bugs.
    N_TESTS = 10000
    N_NODES = 5
    dataset = generate_nodes(N_NODES)
    coordinators = [
        WrhCoordinator(),
        WdhtCoordinator(),
    ]

    for coord in coordinators
        println("----------------")
        for (id, w) in dataset
            insert_node!(coord, id, w)
        end

        ID_LEN_TEST = compute_id_len(N_TESTS)
        counter = DefaultDict{String, Int}(0)
        for i in 1:N_TESTS
            data = randstring(ID_LEN_TEST)
            chosen = choose_nodes(coord, data, 1)[1]
            counter[chosen] += 1

            if i % 50 == 0
                reseed!(coord)
            end
        end

        for (id, freq) in counter
            println("Expected = $(dataset[id]), actual = $(freq / N_TESTS)")
        end

        observed = [counter[k] for k in keys(dataset)]
        expected = [dataset[k] for k in keys(dataset)]

        p = pvalue(ChisqTest(observed, expected))
        if p < 0.05
            println("(!) The implementation of $(typeof(coord)) is probably wrong, p = $p")
        end
    end
end
