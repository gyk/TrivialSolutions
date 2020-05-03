using Test

using AutomaticDifferentiation.Forward
using AutomaticDifferentiation.Backward

@testset "Smoke" begin
    (x, y) = rand(2)
    z_value = x * y + sin(x)

    dx = 1.0
    dy = 1.0
    ∂z_over_∂x = y + cos(x)
    ∂z_over_∂y = x
    dz = ∂z_over_∂x * dx + ∂z_over_∂y * dy

    ## Forward

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

    ## Backward

    let x = Var(x), y = Var(y)
        z = x * y + sin(x)
        z.grad = 1.0
        @test grad!(x) ≈ ∂z_over_∂x
        @test grad!(y) ≈ ∂z_over_∂y
    end
end
