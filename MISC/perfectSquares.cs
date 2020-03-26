using System.Linq;

public class Solution
{
    public int NumSquares(int n)
    {
        var choices = Enumerable.Range(1, n).Select(x => x * x).TakeWhile(x => x <= n).ToArray();
        var mem = new int?[n + 1];
        mem[0] = 0;

        int solve(int r) {
            return mem[r] ??= 1 + choices.TakeWhile(x => x <= r).Select(x => solve(r - x)).Min();
        }

        return solve(n);
    }
}
