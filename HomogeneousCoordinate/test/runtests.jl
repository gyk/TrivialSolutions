using Test

using HomogeneousCoordinate

@testset "Smoke" begin
    p1 = Point(1.0, 0.0)
    p2 = Point(1.0, 1.0)
    @test isnothing(line_through_two_points(p1, p2))
    @test is_vertical(line_through_two_points(cart2homo(p1), cart2homo(p2)))

    p1 = Point(0.0, 1.0)
    p2 = Point(1.0, 3.0)
    p3 = Point(2.0, 5.0)
    @test are_collinear(p1, p2, p3)
    @test are_collinear(cart2homo(p1), cart2homo(p2), cart2homo(p3))
    @test is_point_on_line(p1, line_through_two_points(p2, p3))
    @test is_point_on_line(cart2homo(p1), line_through_two_points(cart2homo(p2), cart2homo(p3)))

    @test isinf(PointH([1.0, 1.0, 0.0]))
    @test isinf(LineH([0.0, 0.0, 1.0]))

    @test PointH([1.0, 1.0, 1.0]) == PointH([2.0, 2.0, 2.0])
    @test LineH([1.0, 1.0, 1.0]) == LineH([2.0, 2.0, 2.0])
end

@testset "Randomized" begin
    for _ in 1:50
        coords = Float64.(rand(1:5, (3, 2)))
        points = mapslices(v -> Point(v...), coords, dims=[2])
        h_points = cart2homo.(points)

        collinear = are_collinear(points[1], points[2], points[3])
        h_collinear = are_collinear(h_points[1], h_points[2], h_points[3])

        line_p1_p2 = line_through_two_points(points[1], points[2])
        h_line_p1_p2 = line_through_two_points(h_points[1], h_points[2])

        line_p2_p3 = line_through_two_points(points[2], points[3])
        h_line_p2_p3 = line_through_two_points(h_points[2], h_points[3])

        h_p1_clone = deepcopy(h_points[1])
        normalize!(h_p1_clone)
        @test h_p1_clone ≈ h_points[1]

        if isnothing(line_p1_p2)
            @test is_vertical(h_line_p1_p2)
        else
            @test cart2homo(line_p1_p2) ≈ h_line_p1_p2

            h_line_p1_p2_clone = deepcopy(h_line_p1_p2)
            normalize!(h_line_p1_p2_clone)
            @test h_line_p1_p2_clone ≈ h_line_p1_p2
        end

        if !isnothing(line_p1_p2) && !isnothing(line_p2_p3) && !collinear
            @test intersection_of_two_lines(line_p1_p2, line_p2_p3) ≈ points[2] &&
                  intersection_of_two_lines(h_line_p1_p2, h_line_p2_p3) ≈ h_points[2]
        end
    end
end

@testset "Dual" begin
    for _ in 1:5
        p = [PointH(rand(3)) for _ in 1:2]
        l = dual.(p)

        l_of_p = line_through_two_points(p...)
        p_of_l = intersection_of_two_lines(l...)

        @test l_of_p.v == p_of_l.v
    end
end
