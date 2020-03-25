// Spiral Matrix

using System.Collections.Generic;
using System.Linq;

// https://leetcode.com/problems/spiral-matrix/
public class SolutionI {
    readonly (int, int)[] DIR = new [] {
        (0, 1),
        (1, 0),
        (0, -1),
        (-1, 0),
    };
    public IList<int> SpiralOrder(int[][] matrix) {
        int nr = matrix.Length;
        int nc = nr > 0 ? matrix[0].Length : 0;
        var res = new List<int>(nr * nc);

        int dir = 0;
        int r = 0, c = -1;
        while (nr > 0 && nc > 0) {
            var (dr, dc) = DIR[dir];
            if (dr == 0) {
                for (int i = 0; i < nc; i++) {
                    c += dc;
                    res.Add(matrix[r][c]);
                }
                nr--;
            } else {
                for (int i = 0; i < nr; i++) {
                    r += dr;
                    res.Add(matrix[r][c]);
                }
                nc--;
            }
            dir = (dir + 1) % 4;
        }

        return res;
    }
}

// https://leetcode.com/problems/spiral-matrix-ii/
public class SolutionII {
    public int[][] GenerateMatrix(int n) {
        var a = Enumerable.Range(0, n).Select(_ => new int[n]).ToArray();
        int r = 0, c = 0;
        int k = 1;
        while (n > 1) {
            for (int i = 0; i < n - 1; i++) {
                a[r][c++] = k++;
            }
            for (int i = 0; i < n - 1; i++) {
                a[r++][c] = k++;
            }
            for (int i = 0; i < n - 1; i++) {
                a[r][c--] = k++;
            }
            for (int i = 0; i < n - 1; i++) {
                a[r--][c] = k++;
            }
            r++; c++;
            n -= 2;
        }
        if (n == 1) {
            a[r][c] = k;
        }
        return a;
    }
}
