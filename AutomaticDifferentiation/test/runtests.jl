using Test

using AutomaticDifferentiation.Forward

@testset "Forward - Smoke" begin
    (x, y) = rand(2)
    z_value = x * y + sin(x)

    dx = 1.0
    dy = 1.0
    ∂z_over_∂x = y + cos(x)
    ∂z_over_∂y = x
    dz = ∂z_over_∂x * dx + ∂z_over_∂y * dy

    let x = ind_var(x), y = ind_var(y)
        z = x * y + sin(x)
        @test z.value ≈ z_value
        @test z.grad ≈ dz
    end

    let x = ind_var(x)
        z = x * y + sin(x)
        @test z.value ≈ z_value
        @test z.grad ≈ ∂z_over_∂x
    end

    let y = ind_var(y)
        z = x * y + sin(x)
        @test z.value ≈ z_value
        @test z.grad ≈ ∂z_over_∂y
    end
end
