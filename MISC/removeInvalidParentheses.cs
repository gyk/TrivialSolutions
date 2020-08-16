// Remove Invalid Parentheses (https://leetcode.com/problems/remove-invalid-parentheses/)
using System.Collections.Generic;
using System.Linq;

// Time complexity: O(2^n)

public class Solution
{
    static (int, int) findUnbalance(string s)
    {
        int leftCnt = 0, rightCnt = 0;
        foreach (char c in s) {
            if (c == '(') {
                leftCnt++;
            } else if (c == ')') {
                if (leftCnt > 0) {
                    leftCnt--;
                } else {
                    rightCnt++;
                }
            }
        }
        return (leftCnt, rightCnt);
    }

    public IList<string> RemoveInvalidParentheses(string s)
    {
        var res = new HashSet<string>();
        int n = s.Length;
        var removed = new bool[n];

        string construct()
        {
            return string.Join(null,
                Enumerable.Range(0, n).Where(i => !removed[i]).Select(i => s[i]));
        }

        var (leftCnt, rightCnt) = findUnbalance(s);

        void solve(int i, int nLeftRemoved, int nRightRemoved, int balance)
        {
            if (i == n) {
                if ((nLeftRemoved, nRightRemoved) == (leftCnt, rightCnt) && balance == 0) {
                    res.Add(construct());
                }
                return;
            }

            switch (s[i]) {
                case '(':
                    solve(i + 1, nLeftRemoved, nRightRemoved, balance + 1);
                    break;
                case ')':
                    if (balance > 0) {
                        solve(i + 1, nLeftRemoved, nRightRemoved, balance - 1);
                    }
                    break;
                default:
                    solve(i + 1, nLeftRemoved, nRightRemoved, balance);
                    break;
            }

            removed[i] = true;
            switch (s[i]) {
                case '(':
                    if (nLeftRemoved < leftCnt) {
                        solve(i + 1, nLeftRemoved + 1, nRightRemoved, balance);
                    }
                    break;
                case ')':
                    if (nRightRemoved < rightCnt) {
                        solve(i + 1, nLeftRemoved, nRightRemoved + 1, balance);
                    }
                    break;
            }
            removed[i] = false;
        }

        solve(0, 0, 0, 0);
        return res.ToArray();
    }
}
