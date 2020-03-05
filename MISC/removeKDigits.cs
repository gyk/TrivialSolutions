// https://leetcode.com/problems/remove-k-digits

using System;
using System.Collections.Generic;
using System.Linq;

public class Solution {
    static int[] digits;

    public string RemoveKdigits(string num, int k) {
        int[] digits = num.Select(c => c - '0').ToArray();
        var removed = removeK(digits, k);
        var ret = string.Concat(removed.SkipWhile(x => x == 0).Select(d => (char)('0' + d)));
        return string.IsNullOrEmpty(ret) ? "0" : ret;
    }

    IEnumerable<int> removeK(int[] digits, int k) {
        int n = digits.Count();
        var res = new List<int>(n - k);

        int i = 0;
        ReadOnlySpan<int> digitsSpan = digits.AsSpan();
        while (i < n - k) {
            ReadOnlySpan<int> d = digitsSpan.Slice(i);

            int minSoFar = 10;
            int minIndex = -1;
            for (int j = 0; j <= k; j++) {
                if (d[j] < minSoFar) {
                    minSoFar = d[j];
                    minIndex = j;
                }
            }

            res.Add(minSoFar);
            i += minIndex + 1;
            k -= minIndex;
        }

        return res;
    }
}
