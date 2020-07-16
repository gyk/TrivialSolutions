// Distinct Subsequences (https://leetcode.com/problems/distinct-subsequences/)

public class Solution {
    public int NumDistinct(string s, string t) {
        // appends virtual '^'/'$' at the start/end of both strings
        var m = new int[s.Length + 2, 2];
        m[s.Length + 1, (t.Length + 1) % 2] = 1;

        for (int j = t.Length; j >= 0; j--) {
            for (int i = s.Length; i >= 0; i--) {
                ref var acc = ref m[i + 1, (j + 1) % 2];
                m[i, (j + 1) % 2] += acc;
                if ((i, j) switch {
                    (0, 0) => true,
                    (_, 0) => false,
                    (0, _) => false,
                    (_, _) => (s[i - 1] == t[j - 1]),
                }) {
                    m[i, j % 2] = acc;
                }
                acc = 0;
            }
        }

        return m[0, 0];
    }
}
