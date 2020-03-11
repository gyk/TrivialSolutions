// Largest Number (https://leetcode.com/problems/largest-number/)
using System.Linq;

// Sorts the array lexicographically.
// `cmp(A + B, A) == cmp(A + B + A, A + A + B)` because all the other elements are smaller than `A`.

public class Solution {
    public string LargestNumber1(int[] nums) {
        string[] a = nums.Select(n => n.ToString()).ToArray();
        System.Array.Sort(a, (x, y) => string.Compare(y + x, x + y)); // descendingly
        if (a[0] == "0") {
            return "0";
        } else {
            return string.Concat(a);
        }
    }

    public string LargestNumber2(int[] nums) {
        string[] a = nums.Select(n => n.ToString()).ToArray();
        System.Array.Sort(a, (x, y) => {
            int nx = x.Length;
            int ny = y.Length;
            for (int i = 0; i < nx + ny; i++) {
                var cx = i >= nx ? y[i - nx] : x[i];
                var cy = i >= ny ? x[i - ny] : y[i];
                int cmp = cx.CompareTo(cy);
                if (cmp != 0) {
                    return -cmp;
                }
            }
            return 0;
        });
        return a[0] == "0" ? "0" : string.Concat(a);
    }
}
