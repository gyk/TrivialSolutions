// Move Zeroes (https://leetcode.com/problems/move-zeroes/)

public class Solution {
    public void MoveZeroes(int[] nums) {
        int j = 0;
        for (int i = 0; i < nums.Length; i++) {
            if (nums[i] != 0) {
                (nums[i], nums[j]) = (nums[j], nums[i]);
                j++;
            }
        }
        for (; j < nums.Length; j++) {
            nums[j] = 0;
        }
    }
}
