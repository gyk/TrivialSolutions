// Best Time to Buy and Sell Stock

using System;
using System.Collections.Generic;
using System.Linq;

// https://leetcode.com/problems/best-time-to-buy-and-sell-stock/
public class SolutionI {
    public int MaxProfit(int[] prices) {
        var lowest = int.MaxValue;
        var maxProfit = 0;
        foreach (int p in prices) {
            lowest = Math.Min(lowest, p);
            maxProfit = Math.Max(maxProfit, p - lowest);
        }
        return maxProfit;
    }
}

// https://leetcode.com/problems/best-time-to-buy-and-sell-stock-ii/
public class SolutionII {
    public int MaxProfit(int[] prices) {
        int res = 0;
        for (int i = 1; i < prices.Length; i++) {
            res += Math.Max(prices[i] - prices[i - 1], 0);
        }
        return res;
    }
}

// https://leetcode.com/problems/best-time-to-buy-and-sell-stock-iii/
public class SolutionIII {
    public int MaxProfit(int[] prices) {
        int b1 = int.MaxValue; // b1
        int s1b1 = 0; // s1 - b1
        int b2s1b1 = int.MaxValue; // b2 - (s1 - b1)
        int s2b2s1b1 = 0; // s2 - b2 + s1 - b1
        foreach (int p in prices) {
            b1 = Math.Min(b1, p);
            s1b1 = Math.Max(s1b1, p - b1);
            b2s1b1 = Math.Min(b2s1b1, p - s1b1);
            s2b2s1b1 = Math.Max(s2b2s1b1, p - b2s1b1);
        }
        return s2b2s1b1;
    }
}

// https://leetcode.com/problems/best-time-to-buy-and-sell-stock-iv/
public class SolutionIV {
    public int MaxProfit(int k, int[] prices) {
        if (k * 2 >= prices.Length) {
            return maxProfitInf(prices);
        }

        var min = Enumerable.Repeat(int.MaxValue, k + 1).ToArray();
        var max = new int[k + 1];
        foreach (int p in prices) {
            for (int i = 1; i <= k; i++) {
                min[i] = Math.Min(min[i], p - max[i - 1]);
                max[i] = Math.Max(max[i], p - min[i]);
            }
        }
        return max[k];
    }

    int maxProfitInf(int[] prices) { // Problem II
        int res = 0;
        for (int i = 1; i < prices.Length; i++) {
            res += Math.Max(prices[i] - prices[i - 1], 0);
        }
        return res;
    }
}

// ----- Alternative Solutions ----- //

// Best Time to Buy and Sell Stock I, using Kadane's Algorithm
public class SolutionI_Kadane {
    public int MaxProfit(int[] prices) {
        int maxSoFar = 0;
        int endsHere = 0;
        for (int i = 1; i < prices.Length; i++) {
            int diff = prices[i] - prices[i - 1];
            endsHere += diff;
            if (diff > 0) {
                maxSoFar = Math.Max(maxSoFar, endsHere);
            } else {
                endsHere = Math.Max(endsHere, 0);
            }
        }
        return maxSoFar;
    }
}

// Best Time to Buy and Sell Stock II, an over-complicated solution.
public class SolutionII_Dumb {
    public int MaxProfit(int[] prices) {
        var profitLowest = new List<(int, int)> { (0, int.MaxValue) };

        for (int i = 0; i < prices.Length; i++) {
            var price = prices[i];
            var (profitBest, lowestBest) = (0, int.MaxValue);
            for (int j = 0; j < profitLowest.Count; j++) {
                var (profit, lowest) = profitLowest[j];
                if (profit > profitBest && profit - profitBest > lowest - lowestBest) {
                    (profitBest, lowestBest) = (profit, lowest);
                }
                if (price < lowest) {
                    profitLowest[j] = (profit, price);
                } else if (price > lowest) {
                    profitLowest.Add((profit + price - lowest, int.MaxValue));
                }
            }

            profitLowest.RemoveAll(x => {
                var (profit, lowest) = x;
                return profit <= profitBest && profitBest - profit >= lowestBest - lowest;
            });
            profitLowest.Add((profitBest, lowestBest));
        }
        return profitLowest.Select(x => x.Item1).Max();
    }
}

// Best Time to Buy and Sell Stock III
public class SolutionIII_TwoPasses {
    public int MaxProfit(int[] prices) {
        int n = prices.Length;

        var maxProfits2 = new int[n + 1];
        int highest = 0;
        for (int i = n - 1; i >= 0; i--) {
            highest = Math.Max(highest, prices[i]);
            maxProfits2[i] = Math.Max(maxProfits2[i + 1], highest - prices[i]);
        }

        int maxProfit = 0;
        int lowest = int.MaxValue;
        for (int i = 0; i < n; i++) {
            lowest = Math.Min(lowest, prices[i]);
            int maxProfit1 = prices[i] - lowest;
            maxProfit = Math.Max(maxProfit, maxProfit1 + maxProfits2[i + 1]);
        }
        return maxProfit;
    }
}

// Best Time to Buy and Sell Stock IV
// https://leetcode.com/articles/best-time-to-buy-and-sell-stock-iv/#approach-2-merging
public class SolutionIV_Merge {
    public int MaxProfit(int k, int[] prices) {
        if (prices.Length == 0) {
            return 0;
        }

        var txns = new List<(int, int)>();
        int min = prices[0];
        int max = prices[0];
        bool ascending = false;
        for (int i = 1; i < prices.Length; i++) {
            if (prices[i] >= prices[i - 1]) {
                max = prices[i];
                ascending = true;
            } else {
                if (ascending) {
                    txns.Add((min, max));
                    ascending = false;
                }
                min = prices[i];
            }
        }
        if (ascending) {
            txns.Add((min, max));
        }

        while (txns.Count > k) {
            int deleteLoss = txns[0].Item2 - txns[0].Item1;
            int deleteLossInd = 0;
            int mergeLoss = int.MaxValue;
            int? mergeLossInd = null;
            for (int i = 1; i < txns.Count; i++) {
                int deleteLossCurr = txns[i].Item2 - txns[i].Item1;
                if (deleteLossCurr < deleteLoss) {
                    deleteLoss = deleteLossCurr;
                    deleteLossInd = i;
                }

                int mergeLossCurr = txns[i - 1].Item2 - txns[i].Item1; // can be negative
                if (mergeLossCurr < mergeLoss) {
                    mergeLoss = mergeLossCurr;
                    mergeLossInd = i;
                }
            }

            if (deleteLoss < mergeLoss) {
                txns.RemoveAt(deleteLossInd);
            } else {
                int i = mergeLossInd.Value;
                txns[i - 1] = (txns[i - 1].Item1, txns[i].Item2);
                txns.RemoveAt(i);
            }
        }

        return txns.Select(t => t.Item2 - t.Item1).Sum();
    }
}

// Extends `SolutionI_Kadane` to k transactions.
// https://leetcode.com/articles/best-time-to-buy-and-sell-stock-iv/743974/Best-Time-to-Buy-and-Sell-Stock-IV/627971
public class SolutionIV_Kadane {
    public int MaxProfit(int k, int[] prices) {
        int n = prices.Length;
        if (k * 2 >= n) {
            return maxProfitInf(prices);
        }
        var maxSoFar = new int[n];

        // Invariants:
        //
        // - endsHere[k][i]: The max profit until i, with at most k trxns, and sells stock at i.
        // - maxSoFar[k][i]: The max profit until i, with at most k trxns.

        while (k-- > 0) {
            int endsHere = 0;
            for (int i = 1; i < n; i++) {
                // Here `maxSoFar[i]` refers to `maxSoFar[k - 1][i]` (But if you write `maxSoFar[i -
                // 1]`, it means `maxSoFar[k][i - 1]`).
                endsHere = Math.Max(maxSoFar[i], endsHere + prices[i] - prices[i - 1]);
                maxSoFar[i] = Math.Max(maxSoFar[i - 1], endsHere);
            }
        }

        return maxSoFar[^1];
    }

    int maxProfitInf(int[] prices) { // Problem II
        int res = 0;
        for (int i = 1; i < prices.Length; i++) {
            res += Math.Max(prices[i] - prices[i - 1], 0);
        }
        return res;
    }
}
