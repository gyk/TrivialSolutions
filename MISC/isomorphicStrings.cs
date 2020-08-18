// Isomorphic Strings (https://leetcode.com/problems/isomorphic-strings/)

using System.Collections.Generic;
using System.Linq;

public class Solution {
    public bool IsIsomorphic(string s, string t) {
        if (s.Length != t.Length) {
            return false;
        }
        var m = new Dictionary<char, char>();
        var r = new HashSet<char>();
        foreach (var c in s.Zip(t, (c_s, c_t) => new { S = c_s, T = c_t })) {
            if (m.TryGetValue(c.S, out char ch)) {
                if (ch != c.T) {
                    return false;
                }
            } else {
                if (r.Contains(c.T)) {
                    return false;
                }
                m[c.S] = c.T;
                r.Add(c.T);
            }
        }
        return true;
    }
}
