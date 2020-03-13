// Lexicographical Numbers (https://leetcode.com/problems/lexicographical-numbers/)

using System.Collections.Generic;
using System.Linq;

public class Solution {
    public IList<int> LexicalOrder(int n) {
        return new List<int>(lexicalOrderImpl(n));
    }

    IEnumerable<int> lexicalOrderImpl(int n) {
        int i = 1;
        while (true) {
            yield return i;

            if (i * 10 <= n) {
                i *= 10;
                continue;
            }

            while (i % 10 == 9 || i + 1 > n) {
                i /= 10;
            }

            if (i == 0) {
                break;
            }

            ++i;
        }
    }

    public IList<int> LexicalOrder2(int n) {
        return Enumerable.Range(1, n)
            .Select(x => x.ToString())
            .OrderBy(s => s)
            .Select(s => int.Parse(s))
            .ToArray();
    }
}
