// Missing Number (https://leetcode.com/problems/missing-number/)

using System.Linq;

public class Solution {
    public int MissingNumber(int[] nums) {
        int n  = nums.Length;
        return n * (n + 1) / 2 - nums.Sum();
    }
}
