using Test

using EvenTotalPayment

# https://www.extension.iastate.edu/agdm/wholefarm/html/c5-93.html
@testset "Smoke" begin
    p = even_total_payment(10000.0, 0.07, 20)
    @test round(Int, p.payment) == 944
    @test round(Int, p.principals[10]) == 448
    @test round(Int, p.interests[10]) == 495
    @test round(Int, total_interest(p)) == 8879
    @test round(Int, total_payment(p)) == 18879
end

# 微博高利贷
@testset "Weibo Loan Shark" begin
    # 根据微博消费贷规则，借款8000元按等额本息半年还清，每月需还款1476.78元。(王高飞：“加点利息怎么
    # 了？”)
    rate = estimate_interest_rate(8000.0, 6, 1476.78)
    @test round(Int, rate * 100 * 12) == 36  # 年化百分比利率（Annual percentage rate）高达36%
    # 有效年利率（Effective annual rate）
    ear = round((1.0 + rate) ^ 12 - 1.0; sigdigits=3)
    println("Effective annual rate = $(ear * 100)%")
end
