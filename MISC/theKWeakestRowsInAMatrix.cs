// LeetCode 1337. The K Weakest Rows in a Matrix
//
// <https://leetcode.com/problems/the-k-weakest-rows-in-a-matrix/>
//
// (I feel obligated to solve Problem #1337 of LeetCode.)

using System.Linq;

public class Solution {
    public int[] KWeakestRows(int[][] mat, int k) {
        return mat
            .Select((row, i) => (row.TakeWhile(x => x != 0).Count(), i))
            .OrderBy(x => x)
            .Take(k)
            .Select(pair => pair.Item2)
            .ToArray();
    }
}
