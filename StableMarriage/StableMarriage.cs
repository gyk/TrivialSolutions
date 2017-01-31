using System.Collections.Generic;
using System.Linq;

class StableMarriage
{
    public static int[] solve(int[][] mPrefer, int[][] wRanks)
    {
        int n = mPrefer.GetLength(0);
        int[] wMatches = new int[n];
        var oneToN = Enumerable.Range(0, n);
        HashSet<int> mFree = new HashSet<int>(oneToN);
        HashSet<int> wFree = new HashSet<int>(oneToN);

        while (mFree.Count > 0) {
            int m = mFree.First();
            foreach (int w in mPrefer[m]) {
                if (wFree.Contains(w)) {
                    wMatches[w] = m;
                    mFree.Remove(m);
                    wFree.Remove(w);
                    break;
                } else {
                    // If w is not free, find the man she currently gets engaged to.
                    int m_ = wMatches[w];
                    // w prefers m to m_
                    if (wRanks[w][m] < wRanks[w][m_]) {
                        mFree.Remove(m);
                        mFree.Add(m_);
                        wMatches[w] = m;
                        break;
                    }
                }
            }
        }

        int[] mMatches = new int[n];
        for (int w = 0; w < n; w++) {
            mMatches[wMatches[w]] = w;
        }
        return mMatches;
    }
}
