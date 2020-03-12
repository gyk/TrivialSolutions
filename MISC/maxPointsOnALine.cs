// Max Points on a Line (https://leetcode.com/problems/max-points-on-a-line/)

using System.Collections.Generic;
using Math = System.Math;

public class Solution {
    static (int, int) reduceFraction(int a, int b) {
        if (a == 0 || b == 0) {
            if (a != 0) {
                return (1, 0);
            } else if (b != 0) {
                return (0, 1);
            } else {
                return (0, 0);
            }
        }

        var (x, y) = (a, b);
        do {
            (x, y) = (y, x % y);
        } while (y != 0);
        return (a / x, b / x);
    }

    public int MaxPoints(int[][] points) {
        int maxCount = 0;
        for (int i = 0; i < points.Length; i++) {
            var dict = new Dictionary<(int, int), int>();
            int max = 0;
            for (int j = 0; j <= i; j++) {
                int dx = points[i][0] - points[j][0];
                int dy = points[i][1] - points[j][1];
                var slope = reduceFraction(dx, dy);
                int count = dict.GetValueOrDefault(slope, 0) + 1;
                dict[slope] = count;
                if (slope != (0, 0)) {
                    max = Math.Max(max, count);
                }
            }
            maxCount = Math.Max(maxCount, max + dict[(0, 0)]);
        }
        return maxCount;
    }
}
