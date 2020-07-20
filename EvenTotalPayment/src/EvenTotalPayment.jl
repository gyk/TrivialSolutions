module EvenTotalPayment

export Payment, even_total_payment, total_payment, total_interest, estimate_interest_rate

const Money = BigFloat  # Use Decimal?

struct Payment
    payment::Money
    principals::Vector{Money}
    interests::Vector{Money}
    unpaid_balances::Vector{Money}
end

total_payment(p::Payment) = p.payment * length(p.principals)
total_interest(p::Payment) = sum(p.interests)

function even_total_payment(loan::Float64, interest_rate::Float64, n_payments::Int)::Payment
    even_total_payment(Money(loan), BigFloat(interest_rate), n_payments)
end

#=

A: loan, k: interest rate, x: monthly/yearly payment, n: payment period

A1 = A - (x - A * k)
A2 = A1 - (x - A1 * k)
   = (A - (x - A * k)) - (x - (A - (x - A * k)) * k)
   = A * (1 + k)^2 - x * ((1 + k) + 1)
A3 = A2 - (x - A2 * k)
   = (A * (1 + k)^2 - x * ((1 + k) + 1)) - (x - (A * (1 + k)^2 - x * ((1 + k) + 1)) * k)
   = A * (1 + k)^3 - x * ((1 + k)^2 + (1 + k) + 1)
...
An = 0

⟹

x = A * (1 + k)^n / (Σ_{i=0}^{n - 1} (1 + k)^i)

=#

"""
- interest_rate: monthly/yearly interest rate
- n_payments: the period of repayment in months/years
"""
function even_total_payment(loan::Money, interest_rate::BigFloat, n_payments::Int)::Payment
    load_coeffs = [(1 + interest_rate) ^ i for i in 1:n_payments]
    interest_coeffs = cumsum([1.0; load_coeffs[1:(end - 1)]])

    payment = loan * load_coeffs[end] / interest_coeffs[end]
    unpaid_balances = @. loan * load_coeffs - payment * interest_coeffs
    interests = [loan; unpaid_balances[1:(end - 1)]] .* interest_rate
    principals = payment .- interests

    Payment(payment, principals, interests, unpaid_balances)
end

function estimate_interest_rate(
    loan::Float64, n_payments::Int, each_payment::Float64,
)::Union{Nothing, Float64}
    rate = estimate_interest_rate(Money(loan), n_payments, Money(each_payment))
    return isnothing(rate) ? nothing : Float64(rate)
end

function estimate_interest_rate(
    loan::Money, n_payments::Int, each_payment::Money,
)::Union{Nothing, BigFloat}
    @inline compute_payment(r::BigFloat) = even_total_payment(loan, r, n_payments).payment
    low = big(0.0)
    high = big(1.0)
    if compute_payment(low) > each_payment || compute_payment(high) < each_payment
        return nothing
    end

    while true
        mid = (low + high) / 2.0
        p = compute_payment(mid)
        if abs(p - each_payment) < 0.01
            return mid
        end

        if p < each_payment
            low = mid
        else
            high = mid
        end
    end
end

end # module
