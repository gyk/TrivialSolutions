// Wiggle Sort II (https://leetcode.com/problems/wiggle-sort-ii/)

using System;

static class Extension {
    public static void Swap(this Span<int> a, int i, int j) {
        if (i != j) {
            (a[i], a[j]) = (a[j], a[i]);
        }
    }

    public static int findKSmallest(this int[] arr, int k) {
        if (k < 0 || k >= arr.Length) {
            throw new ArgumentException("Invalid arguments");
        }

        for (var a = new Span<int>(arr);;) {
            int n = a.Length;
            a.Swap(0, new Random().Next(n));

            int i = 0;
            for (int j = i + 1; j < n; j++) {
                if (a[j] < a[0]) {
                    a.Swap(++i, j);
                }
            }
            a.Swap(0, i);

            if (i == k) {
                return a[i];
            } else if (i < k) {
                a = a.Slice(i + 1);
                k = k - (i + 1);
            } else {
                a = a.Slice(0, i);
            }
        }
    }
}

// The solution that uses an auxiliary array (extra O(n) space).
public class Solution_Aux {
    public void WiggleSort(int[] nums) {
        int n = nums.Length;
        if (n < 2) {
            return;
        }
        int h = (n + 1) / 2;
        var m = nums.findKSmallest(h);

        var aux = new Span<int>((int[])nums.Clone());
        // 3-way partition
        int l = 0, i = 0, r = n - 1;
        while (i <= r) {
            if (aux[i] < m) {
                // Either `l == i` or `l` points to an element that equals to `m`. `i++` => `i` is
                // also correct.
                aux.Swap(l++, i++);
            } else if (aux[i] == m) {
                i++;
            } else { // aux[i] > m
                aux.Swap(i, r--);
            }
        }

        // The elements are placed backwards because it is the correct way to wiggle sort when there
        // are exactly `n / 2` median elements in the array. For example, when `n = 4a` and elements
        // in the range `[a, 3a)` of the sorted array all equal to the median. The following
        // implementation results in identical adjacent numbers:
        //
        //     for (int k = h; k < h; k++) {
        //         nums[k * 2] = aux[k];
        //     }
        //     for (int k = h; k < n; k++) {
        //         nums[((k - (n + 1) / 2) * 2) + 1] = aux[k];
        //     }
        //
        // The mappings are a => 2a and (3a - 1) => 2a - 1 so it does not meet the criterion.

        for (int k = h - 1, j = 0; k >= 0; k--, j += 2) {
            nums[j] = aux[k];
        }
        for (int k = n - 1, j = 1; k >= h; k--, j += 2) {
            nums[j] = aux[k];
        }
    }
}

// The O(n) time and O(1) space solution (https://leetcode.com/problems/wiggle-sort-ii/discuss/77677/)
public class Solution {
    public void WiggleSort(int[] nums) {
        int n = nums.Length;
        if (n < 2) {
            return;
        }
        int h = (n + 1) / 2;
        var m = nums.findKSmallest(h);
        Span<int> a = nums;

        // 3-way partition: [> m] [== m] [< m]
        Func<int, int> index = i => (1 + 2 * i) % (n | 1); // one-to-one mapping
        int l = 0, i = 0, r = n - 1;
        while (i <= r) {
            int x = nums[index(i)];
            if (x > m) {
                a.Swap(index(l++), index(i++));
            } else if (x == m) {
                i++;
            } else {
                a.Swap(index(i), index(r--));
            }
        }
    }
}
