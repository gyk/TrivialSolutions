// Surrounded Regions (https://leetcode.com/problems/surrounded-regions/)

using System.Collections.Generic;

public class Solution {
    public void Solve(char[][] board) {
        var nr = board.GetLength(0);
        var nc = nr == 0 ? 0 : board[0].GetLength(0);

        var q = new Queue<(int, int)>();

        char get(int r, int c) {
            if (r < 0 || c < 0 || r == nr || c == nc) {
                return '!';
            } else {
                return board[r][c];
            }
        }

        IEnumerable<(int, int)> getBound() {
            var (r, c) = (0, 0);
            for (int i = 1; i < nc; i++) {
                yield return (r, ++c);
                if (nr > 1) yield return (nr - 1 - r, nc - 1 - c);
            }
            for (int i = 1; i < nr; i++) {
                yield return (++r, c);
                if (nc > 1) yield return (nr - 1 - r, nc - 1 - c);
            }
            if (nr == 1 && nc == 1) yield return (0, 0);
        }

        foreach (var (r, c) in getBound()) {
            if (board[r][c] == 'O') {
                q.Enqueue((r, c));
            }
        }

        while (q.Count > 0) {
            var (r, c) = q.Dequeue();
            var x = get(r, c);
            if (x == 'O') {
                board[r][c] = '?';
                foreach (var (rr, cc) in new [] {(r, c - 1), (r - 1, c), (r, c + 1), (r + 1, c)}) {
                    var xx = get(rr, cc);
                    if (xx == 'O') {
                        q.Enqueue((rr, cc));
                    }
                }
            }
        }

        for (int r = 0; r < nr; r++) {
            for (int c = 0; c < nc; c++) {
                board[r][c] = board[r][c] switch {
                    '?' => 'O',
                    _ => 'X',
                };
            }
        }
    }
}
