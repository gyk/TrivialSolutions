# Inverse 32-bit Shift-And-Xor transform

function xorshift_left(value::UInt32, n_shift::Integer, and_mask::UInt32 = 0xFFFF_FFFF)::UInt32
    value ⊻ ((value << n_shift) & and_mask)
end

function xorshift_right(value::UInt32, n_shift::Integer, and_mask::UInt32 = 0xFFFF_FFFF)::UInt32
    value ⊻ ((value >> n_shift) & and_mask)
end

function reverse_xorshift_left(value::UInt32, n_shift::Int, and_mask::UInt32 = 0xFFFF_FFFF)::UInt32
    if n_shift == 0
        error("`n_shift` should not be 0")
    end

    n_remains::Int = 32 - n_shift
    mask = (UInt32(1) << n_shift) - UInt32(1)
    while n_remains > 0
        value ⊻= ((value & mask) << n_shift) & and_mask
        n_remains -= n_shift
        mask <<= n_shift
    end
    value
end

function reverse_xorshift_right(value::UInt32, n_shift::Int, and_mask::UInt32 = 0xFFFF_FFFF)::UInt32
    if n_shift == 0
        error("`n_shift` should not be 0")
    end

    n_remains::Int = 32 - n_shift
    mask = ~((UInt32(1) << n_remains) - UInt32(1))
    while n_remains > 0
        value ⊻= ((value & mask) >> n_shift) & and_mask
        n_remains -= n_shift
        mask >>= n_shift
    end
    value
end

# Let `b[i] = (value >> (n_shift * i)) & ((1 << n_shift) - 1)` (0-based), after the $j$-th xor
# operations, we have
#
#     T(b[i], j) == b[i] ⊻ b[i - 2 ^ j],  if i - 2 ^ j >= 0
#     T(b[i], j) == b[i],  otherwise

function reverse_xorshift_left_fast(value::UInt32, n_shift::Int)::UInt32
    if n_shift == 0
        error("`n_shift` should not be 0")
    end

    while n_shift < 32
        value ⊻= value << n_shift
        n_shift *= 2
    end
    value
end

function reverse_xorshift_right_fast(value::UInt32, n_shift::Int)::UInt32
    if n_shift == 0
        error("`n_shift` should not be 0")
    end

    while n_shift < 32
        value ⊻= value >> n_shift
        n_shift *= 2
    end
    value
end


#===== Unit Tests =====#

using Test
using Random: seed!

@testset "Inverse Xorshift" begin
    n = 1024
    seed!()
    x_arr = rand(UInt32, n)
    n_shift_arr = rand(1:32, n)
    and_mask_arr = rand(UInt32, n)

    x_left_arr = xorshift_left.(x_arr, n_shift_arr, and_mask_arr)
    x_right_arr = xorshift_right.(x_arr, n_shift_arr, and_mask_arr)
    x_left_arr_inv = reverse_xorshift_left.(x_left_arr, n_shift_arr, and_mask_arr)
    x_right_arr_inv = reverse_xorshift_right.(x_right_arr, n_shift_arr, and_mask_arr)
    @test x_arr == x_left_arr_inv == x_right_arr_inv

    x_left_arr = xorshift_left.(x_arr, n_shift_arr)
    x_right_arr = xorshift_right.(x_arr, n_shift_arr)
    x_left_arr_inv = reverse_xorshift_left_fast.(x_left_arr, n_shift_arr)
    x_right_arr_inv = reverse_xorshift_right_fast.(x_right_arr, n_shift_arr)
    @test x_arr == x_left_arr_inv == x_right_arr_inv
end
