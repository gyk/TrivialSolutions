// Coin Change (https://leetcode.com/problems/coin-change/)

public class Solution1 {
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

public class Solution1_Add {
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

/********************************/

// Coin Change 2 (https://leetcode.com/problems/coin-change-2/)

public class Solution2 {
    public int Change(int amount, int[] coins) {
        var a = new int[amount + 1];
        a[0] = 1;
        foreach (int c in coins) {
            for (int j = c; j <= amount; j++) {
                a[j] += a[j - c];
            }
        }
        return a[amount];
    }
}

// My first attempt
public class Solution2_Stupid {
    public int Change(int amount, int[] coins) {
        var a = new int[amount + 1];
        a[0] = 1;
        var b = new int[amount + 1];
        foreach (int c in coins) {
            a.CopyTo(b, 0);
            for (int i = 0; i < amount; i++) {
                if (a[i] == 0) {
                    continue;
                }
                for (int j = i + c; j <= amount; j += c) {
                    b[j] += + a[i];
                }
            }
            (a, b) = (b, a);
        }
        return a[amount];
    }
}
