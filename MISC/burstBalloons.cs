// Burst Balloons (https://leetcode.com/problems/burst-balloons/)
//
// https://medium.com/@resiloc/how-to-solve-the-burst-balloons-problem-like-a-piece-of-cake-6121f365b1f
using System.Collections.Generic;

public class Solution {
    // First attempt. It fails the last test case (Time Limit Exceeds).
    public int MaxCoinsTLE(int[] nums) {
        int n = nums.Length;
        var mem = new Dictionary<(int, int, int), int>();
        System.Func<int, int> getRight = r => r < n ? nums[r] : 1;

        int solve(int begin, int end, int left) {
            if (begin > end) {
                return 0;
            } else if (begin == end) {
                return left * nums[begin] * getRight(end + 1);
            }

            if (mem.TryGetValue((begin, end, left), out int cCached)) {
                return cCached;
            }

            int maxCoins = 0;
            // When balloon #begin bursts, it's balloon #i to its right.
            for (int i = begin + 1; i <= end + 1; i++) {
                int c = solve(begin + 1, i - 1, nums[begin]);
                c += left * nums[begin] * getRight(i);
                c += solve(i, end, left);
                maxCoins = c > maxCoins ? c : maxCoins;
            }
            mem[(begin, end, left)] = maxCoins;
            return maxCoins;
        }

        return solve(0, n - 1, 1);
    }

    // Top-down DP
    public int MaxCoins(int[] nums) {
        int n = nums.Length;
        var mem = new int?[n, n];
        System.Func<int, int> getValue = i => 0 <= i && i < n ? nums[i] : 1;

        int solve(int begin, int end) {
            if (begin > end) {
                return 0;
            }
            if (mem[begin, end] is int cCached) {
                return cCached;
            }
            if (begin == end) {
                return getValue(begin - 1) * nums[begin] * getValue(end + 1);
            }

            int maxCoins = 0;
            // Which balloon bursts last?
            for (int i = begin; i <= end; i++) {
                int cLeft = solve(begin, i - 1);
                int cRight = solve(i + 1, end);
                int c = cLeft + (getValue(begin - 1) * nums[i] * getValue(end + 1)) + cRight;
                maxCoins = c > maxCoins ? c : maxCoins;
            }
            mem[begin, end] = maxCoins;
            return maxCoins;
        }

        return solve(0, n - 1);
    }
}
