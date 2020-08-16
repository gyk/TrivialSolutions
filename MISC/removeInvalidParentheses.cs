using System.Collections.Generic;
using System.Linq;

public class Solution
{
    static (int, int) findUnbalance(string s)
    {
        int leftCnt = 0, rightCnt = 0;
        for (int i = 0; i < s.Length; i++) {
            switch (s[i]) {
                case '(':
                    leftCnt++;
                    break;
                case ')':
                    if (leftCnt > 0) {
                        leftCnt--;
                    } else {
                        rightCnt++;
                    }
                    break;
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
                    if (nLeftRemoved < leftCnt) {
                        removed[i] = true;
                        solve(i + 1, nLeftRemoved + 1, nRightRemoved, balance);
                        removed[i] = false;
                    }
                    break;
                case ')':
                    if (balance > 0) {
                        solve(i + 1, nLeftRemoved, nRightRemoved, balance - 1);
                    }
                    if (nRightRemoved < rightCnt) {
                        removed[i] = true;
                        solve(i + 1, nLeftRemoved, nRightRemoved + 1, balance);
                        removed[i] = false;
                    }
                    break;
                default:
                    solve(i + 1, nLeftRemoved, nRightRemoved, balance);
                    break;
            }
        }

        solve(0, 0, 0, 0);
        return res.ToArray();
    }
}
