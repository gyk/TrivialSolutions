// Find Peak Element (https://leetcode.com/problems/find-peak-element/)

// My first attempt -- a lengthy solution
static class Extension
{
    public static int At(this int[] nums, int i)
    {
        if (i == -1 || i == nums.Length) {
            return int.MinValue;
        } else {
            return nums[i];
        }
    }
}

public class Solution {
    public int FindPeakElement(int[] nums) {
        int l = -1, r = nums.Length, m = nums.Length / 2;
        // Invariant: lVal < mVal && mVal > rVal
        while (!(l + 1 == m && m + 1 == r)) {
            int lVal = nums.At(l);
            int mVal = nums.At(m);
            int rVal = nums.At(l);
            int lm = l + 1 == m ? l : l + (m - l) / 2;
            int rm = m + 1 == r ? r : m + (r - m) / 2;
            int lmVal = nums.At(lm);
            int rmVal = nums.At(rm);

            if (lmVal > mVal) {
                (m, r) = (lm, m);
                continue;
            } else if (mVal < rmVal) {
                (l, m) = (m, rm);
                continue;
            } else {
                if (lmVal == mVal) {
                    if (nums.At(m - 1) > mVal) {
                        (l, m, r) = (lm, m - 1, m);
                        continue;
                    } else { // nums[m - 1] < nums[m]
                        l = m - 1;
                    }
                } else { // lmVal < mVal
                    l = lm;
                }

                if (mVal == rmVal) {
                    if (nums.At(m + 1) > mVal) {
                        (l, m, r) = (m, m + 1, rm);
                        continue;
                    } else { // nums[m + 1] < nums[m]
                        r = m + 1;
                    }
                } else { //  mVal > rmVal
                    r = rm;
                }

                continue;
            }
        }
        return m;
    }
}

// A better solution.
// https://leetcode.com/problems/find-peak-element/solution/
public class Solution_Concise {
    public int FindPeakElement(int[] nums) {
        var (l, r) = (0, nums.Length - 1); // peak ∈ [l, r]
        while (l < r) {
            int m = l + (r - l) / 2;
            if (nums[m] > nums[m + 1]) {
                r = m;
            } else {
                l = m + 1;
            }
        }
        return l;
    }
}
