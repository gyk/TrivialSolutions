// Set Matrix Zeroes (https://leetcode.com/problems/set-matrix-zeroes/)

using System.Linq;

public class Solution
{
    public void SetZeroes(int[][] matrix)
    {
        int nr = matrix.Length;
        int nc = matrix[0].Length;

        (int, int)? rc0 = null;
        for (int r = 0; r < nr; r++) {
            for (int c = 0; c < nc; c++) {
                if (matrix[r][c] == 0) {
                    rc0 = (r, c);
                    break;
                }
            }
        }

        if (rc0 is var (r0, c0)) {
            for (int r = 0; r < nr; r++) {
                for (int c = 0; c < nc; c++) {
                    if (matrix[r][c] == 0) {
                        matrix[r0][c] = 0;
                        matrix[r][c0] = 0;
                    }
                }
            }

            for (int r = 0; r < nr; r++) {
                if (r == r0) {
                    continue;
                }
                for (int c = 0; c < nc; c++) {
                    if (c == c0) {
                        continue;
                    }
                    if (matrix[r0][c] == 0 || matrix[r][c0] == 0) {
                        matrix[r][c] = 0;
                    }
                }
            }

            for (int r = 0; r < nr; r++) {
                matrix[r][c0] = 0;
            }
            for (int c = 0; c < nc; c++) {
                matrix[r0][c] = 0;
            }
        }
    }
}

public class Solution_Compact
{
    public void SetZeroes(int[][] matrix)
    {
        var (nr, nc) = (matrix.Length, matrix[0].Length);
        (int, int)? rc0 = null;
        for (int r = 0; r < nr; r++) {
            for (int c = 0; c < nc; c++) {
                if (matrix[r][c] == 0) {
                    if (rc0 is var (row0, col0)) {
                        matrix[row0][c] = matrix[r][col0] = 0;
                    } else {
                        rc0 = (r, c);
                    }
                }
            }
        }

        if (rc0 is var (r0, c0)) {
            foreach (int r in Enumerable.Range(0, nr).Where(r => r != r0).Append(r0)) {
                foreach (int c in Enumerable.Range(0, nc).Where(c => c != c0).Append(c0)) {
                    if (matrix[r0][c] == 0 || matrix[r][c0] == 0) {
                        matrix[r][c] = 0;
                    }
                }
            }
        }
    }
}
