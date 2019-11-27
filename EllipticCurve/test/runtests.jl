using Test

using EllipticCurveCrypto

@testset "Field" begin
    f_prime = PrimeField{Int}(2 ^ 13 - 1)
    f_real = RealField{Float64}()
    f_rational = RationalField{Rational{BigInt}}()

    rand_field_elem(f::PrimeField{Int}) = f_from(f, rand(Int))
    rand_field_elem(_f::RealField{Float64}) = rand()
    rand_field_elem(_f::RationalField{Rational{BigInt}}) = rationalize(BigInt, rand())

    for f in [f_prime, f_real, f_rational]
        for _ in 1:10
            a = rand_field_elem(f)
            b = rand_field_elem(f)
            c = rand_field_elem(f)
            n = rand(0:10)

            @test begin
                f_add(f, a, b) == f_add(f, b, a) &&
                f_sub(f, a, b) == f_add(f, a, f_neg(f, b)) &&
                f_mul(f, a, b) == f_mul(f, b, a) &&
                f_mul(f, f_add(f, a, b), c) ≈ f_add(f, f_mul(f, a, c), f_mul(f, b, c)) &&
                f_add(f, a, f_neg(f, a)) == f_zero(f) &&
                f_add(f, f_add(f, a, b), c) == f_add(f, a, f_add(f, b, c))
            end

            if b != f_zero(f)
                @test f_mul(f, a, b) ≈ f_div(f, a, f_inv(f, b))
            end

            # Power
            acc = f_one(f)
            for i in 1:n
                acc = f_mul(f, acc, a)
            end
            @test acc ≈ f_pow(f, a, n)
        end
    end
end

@testset "Elliptic Curve - Smoke" begin
    # From <https://github.com/ashutosh1206/Crypton/blob/master/Elliptic-Curves>
    p = 89953523493328636138979614835438769105803101293517644103178299545319142490503
    a = 89953523493328636138979614835438769105803101293517644103178299545319142490500
    b = 28285296545714903834902884467158189217354728250629470479032309603102942404639
    ec = EllipticCurve(PrimeField(p), a, b)
    @test is_on_curve(ec, ec_zero(ec))

    function test_on_curve(x, y)
        @test is_on_curve(ec, Point(x, y))
        @test !is_on_curve(ec, Point(x + 1, y))
        @test !is_on_curve(ec, Point(x, y + 1))
    end

    x = 23292248698455723400586711958086172976663011248265958495236470661012001058264
    y = 11070572596091667736222067788474181728427994902322868933693472122188841639450
    test_on_curve(x, y)

    x = 19111966210181710119684383106309085309943311037354698052067443650291872435169
    y = 21947619442035360436009014982909893928179456172279297680575771006406194394019
    test_on_curve(x, y)

    x = 85505267126160074714029649657702688395481735744072668398817875879304329931353
    y = 15732931607183825022714544854432024236050897772129106298237207697160928704178
    test_on_curve(x, y)
end

@testset "Elliptic Curve - Randomized" begin
    f = PrimeField{Int}(37)
    a = -5
    b = 8
    ec = EllipticCurve(f, a, b)

    function rand_point(ec::EllipticCurve{T}, order::Int, g::Point{T})::Point{T} where T
        k = rand(0:(order - 1))
        ec_scalar_mul(ec, g, k)
    end

    z = ec_zero(ec)
    g = Point{Int}(1, 2)
    for _ in 1:20
        p1 = rand_point(ec, 37, g)
        p2 = rand_point(ec, 37, g)
        p3 = rand_point(ec, 37, g)

        @test begin
            ec_add(ec, p1, z) == p1 &&
            ec_add(ec, p1, ec_neg(ec, p1)) == z &&
            ec_add(ec, ec_add(ec, p1, p2), p3) == ec_add(ec, p1, ec_add(ec, p2, p3)) &&
            ec_add(ec, p1, p2) == ec_add(ec, p2, p1)
        end

        # Power
        n = rand(0:10)
        p = p1
        acc = z
        for i in 1:n
            acc = ec_add(ec, acc, p)
        end
        @test acc ≈ ec_scalar_mul(ec, p, n)
    end
end
