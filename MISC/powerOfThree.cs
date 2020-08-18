// Power of Three (https://leetcode.com/problems/power-of-three/)

using System;

public class Solution {
    public bool IsPowerOfThreeLoop(int n) {
        if (n == 0) {
            return false;
        }
        while (n != 1) {
            if (n % 3 != 0) {
                return false;
            }
            n /= 3;
        }
        return true;
    }

    public bool IsPowerOfThreeLog(int n) {
        return n > 0 && (int)Math.Pow(3.0, Math.Round(Math.Log((double)n, 3.0))) == n;
    }

    public bool IsPowerOfThreeMod(int n) {
        return n > 0 && 1162261467 % n == 0;
    }
}
