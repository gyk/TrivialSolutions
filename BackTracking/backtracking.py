class BackTracking(object):
    def __init__(self, n_moves, n_choices, valid_move):
        self.n_moves = n_moves
        self.n_choices = n_choices
        self.valid_move = valid_move

    def get_next_valid(self, moves, beg=0):
        for ch in range(beg, self.n_choices):
            if self.valid_move(moves + [ch]):
                return ch

    def solve(self):
        moves = []
        i = 0

        while True:
            if len(moves) == self.n_moves:
                yield list(moves)
                i -= 1
            if i == len(moves):
                ch = self.get_next_valid(moves)
                if ch is not None:
                    moves.append(ch)
                i += 1
                continue
            elif i == len(moves) - 1:
                ch = moves[i]
                ch_next = self.get_next_valid(moves, ch + 1)
                if ch_next is None:
                    moves.pop()
                    if not moves:
                        return
                    i -= 1
                    continue
                else:
                    moves[i] = ch_next
                    i += 1
                    continue

def travel(n_rows, n_cols):
    n_moves = n_rows - 1 + n_cols - 1
    choices = {
        0 : (0, 1),  # UP
        1 : (1, 0),  # RIGHT
    }

    def valid_move(moves):
        n_ones = sum(moves)
        n_zeros = len(moves) - n_ones
        return n_zeros <= n_rows - 1 and n_ones <= n_cols - 1

    def comb(n, r):
        import math
        import operator

        r = min(r, n-r)
        if r == 0:
            return 1
        numer = reduce(operator.mul, xrange(n, n - r, -1))
        denom = math.factorial(r)
        return numer // denom

    bt = BackTracking(n_moves, len(choices), valid_move)
    solutions = list(bt.solve())
    assert len(solutions) == comb(n_moves, n_rows - 1)
    return solutions
                
if __name__ == '__main__':
    solutions = travel(3, 5)
    print "#solutions = ", len(solutions)
    for s in solutions[:10]:
        print s
