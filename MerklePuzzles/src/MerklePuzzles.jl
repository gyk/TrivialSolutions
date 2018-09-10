"""
Merkle's Puzzles
================

A toy implementation of Merkle's puzzles, an early, impractical key exchange algorithm devised by
Ralph Merkle.

# References

- https://en.wikipedia.org/wiki/Merkle%27s_Puzzles
- https://medium.com/100-days-of-algorithms/day-75-merkles-puzzles-d9f0e8f9c9d0
"""
module MerklePuzzles

using Random: shuffle
using Nettle: digest

#====
The message format mostly follows Tomáš Bouda's Medium article.

    secret  = [ KEY_SIZE | INDEX_SIZE] | DIGEST_SIZE
    otp_key =       DIGEST_SIZE        | DIGEST_SIZE
====#

sha1(s::Vector{UInt8}) = digest("sha1", s)

# Set it to 1 if Eve takes too long to solve all the puzzles.
const INDEX_SIZE = 2
const N_PUZZLES = 1 << (8 * INDEX_SIZE)
const DIGEST_SIZE = length(sha1(UInt8[]))
# may be larger than the actual symmetric key size
const KEY_SIZE = DIGEST_SIZE - INDEX_SIZE
const OTP_SEED_SIZE = 10

@assert KEY_SIZE > 0
@assert OTP_SEED_SIZE > INDEX_SIZE

"Represents each of Merkle's puzzles."
struct Puzzle
    "The encrypted message, length = DIGEST_SIZE * 2"
    encrypted::Vector{UInt8}

    "Partial OTP key, length = OTP_SEED_SIZE - INDEX_SIZE"
    partial_otp_seed::Vector{UInt8}
end

# Helpers
@inline function pack_bigendian(a::AbstractVector{UInt8}, x::Int)
    x = x - 1
    for i in length(a):-1:1
        a[i] = x & 0xFF
        x >>= 8
    end
end

@inline function unpack_bigendian(a::AbstractVector{UInt8})::Int
    x = 0
    for i in 1:length(a)
        x <<= 8
        x += a[i]
    end
    x + 1
end

# TODO: refactor the API.
"Returns `otp_key`. Randomly sets `otp_seed` if it is empty."
function make_otp_key!(otp_seed::Vector{UInt8})::Vector{UInt8}
    if isempty(otp_seed)
        resize!(otp_seed, OTP_SEED_SIZE)
        otp_seed .= rand(UInt8, OTP_SEED_SIZE)
    end

    otp_key = Vector{UInt8}(undef, DIGEST_SIZE * 2)

    otp_digest = sha1(otp_seed)
    otp_key[1:DIGEST_SIZE] = otp_digest

    otp_digest = sha1(otp_digest)
    otp_key[(DIGEST_SIZE + 1):end] = otp_digest

    otp_key
end

function make_puzzle(key::Vector{UInt8}, index::Int)::Puzzle
    @assert length(key) == KEY_SIZE
    @assert 1 <= index <= N_PUZZLES

    secret = Vector{UInt8}(undef, DIGEST_SIZE * 2)
    secret[1:KEY_SIZE] = key
    index_view = view(secret, (KEY_SIZE + 1):DIGEST_SIZE)
    pack_bigendian(index_view, index)
    # NOTE:
    # 1. Actually index can be excluded from the digestion.
    # 2. The digest must be encrypted too, or it will be insecure.
    secret[(DIGEST_SIZE + 1):end] = sha1(secret[1:DIGEST_SIZE])

    otp_seed = UInt8[]
    otp_key = make_otp_key!(otp_seed)
    @assert length(otp_seed) == OTP_SEED_SIZE
    encrypted = map(xor, secret, otp_key)
    partial_otp_seed = otp_seed[(INDEX_SIZE + 1):end]

    Puzzle(encrypted, partial_otp_seed)
end

function generate_puzzles(n::Int, keys::Matrix{UInt8})
    [make_puzzle(keys[i, :], i) for i in 1:n]
end

"Returns `(index, key)` pair, or `nothing` if the puzzle cannot be solved."
function solve_puzzle(encrypted::Vector{UInt8},
                      otp_seed_template::Vector{UInt8},
                      key_index::Int)::Union{Tuple{Int, Vector{UInt8}}, Nothing}
    key_index_view = view(otp_seed_template, 1:INDEX_SIZE)
    pack_bigendian(key_index_view, key_index)

    otp_key = make_otp_key!(otp_seed_template)
    decrypted = map(xor, encrypted, otp_key)
    if sha1(decrypted[1:DIGEST_SIZE]) == decrypted[(DIGEST_SIZE + 1):end]
        decrypted = decrypted[1:DIGEST_SIZE]
        index_view = view(decrypted, (KEY_SIZE + 1):DIGEST_SIZE)
        index = unpack_bigendian(index_view)
        (index, decrypted[1:KEY_SIZE])
    else
        nothing
    end
end

# The puzzles created by Bob should be serialized before being sent to Alice.
# We assume the (de)serialization code already exists and just pass around Julia objects.

function alice(puzzles::Vector{Puzzle})::Union{Tuple{Int, Vector{UInt8}}, Nothing}
    println("""
        Alice: Puzzles received.
        Alice: Pick a random one and solve it by brute force.
        """)
    i = rand(1:N_PUZZLES)
    puzzle = puzzles[i]
    otp_seed_template = [zeros(UInt8, INDEX_SIZE); puzzle.partial_otp_seed]

    for j in 1:N_PUZZLES
        maybe_index_key = solve_puzzle(puzzle.encrypted, otp_seed_template, j)
        if maybe_index_key != nothing
            return maybe_index_key
        end
    end

    println("Alice: Fsck, I can't solve it. Bob must be a liar.")
    nothing
end

function bob()::Tuple{Matrix{UInt8}, Vector{Puzzle}}
    keys = rand(UInt8, (N_PUZZLES, KEY_SIZE))
    puzzles = generate_puzzles(N_PUZZLES, keys)
    shuffled_puzzles = shuffle(puzzles)
    println("""
        Bob: Puzzles generated.
        Bob: Send puzzles to Alice via insecure channel.
        """)
    (keys, shuffled_puzzles)
end

function eve(puzzles::Vector{Puzzle})::Union{Vector{Vector{UInt8}}, Nothing}
    println("""
        Eve: Puzzles eavesdropped.
        Eve: Start to crack every puzzle.
        """)
    solved_puzzles = Vector{Union{Vector{UInt8}, Nothing}}(nothing, N_PUZZLES)

    for i in 1:N_PUZZLES
        puzzle = puzzles[i]
        otp_seed_template = [zeros(UInt8, INDEX_SIZE); puzzle.partial_otp_seed]

        for j in 1:N_PUZZLES
            maybe_index_key = solve_puzzle(puzzle.encrypted, otp_seed_template, j)
            if maybe_index_key != nothing
                (index, key) = maybe_index_key

                if solved_puzzles[index] != nothing
                    error("Duplicate indices")
                end

                solved_puzzles[index] = key
                @goto succeed
            end
        end

        return nothing
        @label succeed
    end

    solved_puzzles
end

function run()
    println("""
        ======================
        =  Merkle's Puzzles  =
        ======================
        """)
    (bob_keys, shuffled_puzzles) = bob()

    alice_resp = alice(shuffled_puzzles)
    if alice_resp == nothing
        error("Alice cannot solve the puzzle.")
    end
    (index, dec_key) = alice_resp
    println("*: Alice sends index $index back to Bob.")
    if bob_keys[index, :] == dec_key
        println("""
            *: Alice and Bob have agreed on a shared key to use
            *: ...and they communicate happily ever after.
            """)
    else
        error("Alice and Bob have not reached consensus.")
    end

    # Eve the eavesdropper knows the index too.
    eve_resp = eve(shuffled_puzzles)
    if eve_resp == nothing
        println("Eve cannot crack every puzzle.")
    end
    dec_keys = eve_resp
    if bob_keys[index, :] == dec_keys[index]
        println("*: Eve has successfully cracked the key.")
    else
        println("*: Eve has NOT cracked the key.")
    end

    println("\nEnd.")
end

end # module
