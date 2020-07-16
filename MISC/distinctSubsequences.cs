// Distinct Subsequences (https://leetcode.com/problems/distinct-subsequences/)

public class Solution {
    public int NumDistinct(string s, string t) {
        // appends virtual '$' at the end of both strings
        var m = new int[s.Length + 1, 2];
        for (int i = 0; i <= s.Length; i++) {
            m[i, t.Length % 2] = 1;
        }

        for (int j = t.Length - 1; j >= 0; j--) {
            for (int i = s.Length - 1; i >= 0; i--) {
                ref var acc = ref m[i + 1, (j + 1) % 2];
                m[i, j % 2] = s[i] == t[j] ? m[i + 1, j % 2] + acc : m[i + 1, j % 2];
                acc = 0;
            }
        }

        return m[0, 0];
    }
}
