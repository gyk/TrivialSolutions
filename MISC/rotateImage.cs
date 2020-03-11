// Rotate Image (https://leetcode.com/problems/rotate-image/)

public class Solution {
    public void Rotate(int[][] matrix) {
        // Rot90: (r, c) -> (c, n - 1 - r)
        // Transpose: (r, c) -> (c, r)
        // FlipVertically: (r, c) -> (r, n - 1 - c)
        //
        // FlipVertically ∘ Transpose = Rot90
        //
        // (FlipVertically has better spatial locality than FlipHorizontally.)

        for (int r = 0; r < matrix.Length; r++) {
            for (int c = 0; c < r; c++) {
                (matrix[r][c], matrix[c][r]) = (matrix[c][r], matrix[r][c]);
            }
        }

        foreach (var row in matrix) {
            System.Array.Reverse(row);
        }
    }
}
