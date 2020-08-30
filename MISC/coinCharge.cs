// Coin Change (https://leetcode.com/problems/coin-change/)

public class Solution {
    public int CoinChange(int[] coins, int amount) {
        var a = new int?[amount + 1];
        a[0] = 0;
        for (int i = 1; i <= amount; i++) {
            foreach (int c in coins) {
                int j = i - c;
                if (j >= 0 && a[j].HasValue) {
                    if (!a[i].HasValue || a[j] + 1 < a[i]) {
                        a[i] = a[j] + 1;
                    }
                }
            }
        }
        return a[amount] ?? -1;
    }
}

public class Solution_Add {
    public int CoinChange(int[] coins, int amount) {
        var a = new int?[amount + 1];
        a[0] = 0;
        for (int i = 0; i < amount; i++) {
            if (!a[i].HasValue) {
                continue;
            }
            foreach (int c in coins) {
                int j = i + c;
                if (j >= 0 && j <= amount && (!a[j].HasValue || a[i] + 1 < a[j])) {
                    a[j] = a[i] + 1;
                }
            }
        }
        return a[amount] ?? -1;
    }
}
