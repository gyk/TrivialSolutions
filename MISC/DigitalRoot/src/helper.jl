function digital_root(a::Integer)::Int
    while a >= 10
        a = sum(digits(a))
    end
    a
end

function digital_root(a::Vector{<:Integer})::Int
    a = cumprod(big.(a))
    digital_root(sum(a))
end
