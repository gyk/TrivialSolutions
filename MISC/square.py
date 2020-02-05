# Given a set of sticks of various lengths, is it possible to join them end-to-end to form a square?
#
# References:
#
# - Waterloo local (http://plg1.cs.uwaterloo.ca/~acm00/020921/C.html)

# The input size seems so small that it's no need to memoize.
def square(x):
    x.sort(reverse=True)
    sum_len = sum(x)
    side_len = sum_len // 4

    def solve(so_far, rest):
        sum_so_far = sum(so_far)
        if sum_so_far == side_len:
            if rest == []:
                return [so_far]
            result = solve([rest[0]], rest[1:])
            if result:
                return [so_far] + result
            return
        for i in range(len(rest)):
            if sum_so_far + rest[i] > side_len:
                continue
            result = solve(so_far + [rest[i]], rest[:i] + rest[i + 1:])
            if result:
                return result

    if side_len * 4 == sum_len:
        return solve([x[0]], x[1:])

# >>> square([1, 7, 2, 6, 4, 4, 3, 5])
# [[7, 1], [6, 2], [5, 3], [4, 4]]

# >>> square([8, 1, 7, 2, 6, 4, 4, 3, 5])
# [[8, 2], [7, 3], [6, 4], [5, 4, 1]]
