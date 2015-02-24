# Converts infix expression into reverse Polish notation
# (Only 1-digit numbers are allowed.)

operators = {
    # opname => (operator, precedence)
    '+' => (+, 6),
    '-' => (-, 6),
    '*' => (*, 7),
    '/' => (/, 7),
}

is_operator(op) = haskey(operators, op)
get_operator(ch) = operators[ch][1];
get_precedence(ch) = operators[ch][2];
PREC_OFFSET = 100

function in2post(expr::ASCIIString)
    opstack = Char[]
    precedence_stack = Int[]
    output = Char[]
    prec_offset = 0

    for ch in expr
        if ch == '('
            prec_offset += PREC_OFFSET
        elseif ch == ')'
            prec_offset -= PREC_OFFSET
        elseif is_operator(ch)
            precedence = get_precedence(ch) + prec_offset
            while !isempty(opstack) && 
                precedence <= precedence_stack[end]
                push!(output, pop!(opstack))
                pop!(precedence_stack)
            end
            push!(opstack, ch)
            push!(precedence_stack, precedence)
        else
            push!(output, ch)
        end
    end

    if prec_offset != 0
        warn("Unbalanced parentheses!")
    end
    [output, reverse(opstack)]
end

function eval_post(postexp)
    numstack = Int[]
    for ch in postexp
        if is_operator(ch)
            b = pop!(numstack);
            a = pop!(numstack);
            push!(numstack, get_operator(ch)(a, b))
        else
            push!(numstack, ch - '0');
        end
    end
    assert(length(numstack) == 1)
    numstack[end]
end

expr = strip(readline())
postexp = in2post(expr)
@printf("The converted RPN is: %s,\nwhich = %d", 
    join(postexp), eval_post(postexp))

# Conclusion: Julia is far from mature enough to use in production.
