// Finds minimum cost to make a sequence non-decreasing.
//
// References:
//
// - USACO 2008 Gold
// - Codeforces 13/C

#include <iostream>
#include <vector>
#include <algorithm>
#include <limits>

using namespace std;

typedef long long LL;

// The "standard" solution.
LL non_decreasing_seq(std::vector<LL>& a)
{
    std::vector<LL> b(a);
    std::sort(b.begin(), b.end());
    auto it = std::unique(b.begin(), b.end());
    b.resize(std::distance(b.begin(), it));

    int n = a.size();
    int m = b.size();

    // dp[i][j]: the cost to make a[0], a[1], ..., a[i] non-decreasing and a[i] <= b[j]
    std::vector< std::vector<LL> > dp(2, std::vector<LL>(m, 0));

    for (int i=0; i<n; i++) {
        for (int j=0; j<m; j++) {
            LL lower = j == 0 ? std::numeric_limits<LL>::max() : dp[i & 1][j - 1];
            dp[i & 1][j] = std::min(lower, dp[(i - 1) & 1][j] + std::abs(b[j] - a[i]));
        }
    }

    return dp[(n - 1) & 1][m - 1];
}

// TODO: This problem can be generalized to $L_p$ isotonic regression.
//
// Some related papers:
//
// - Stout, Quentin F. "Isotonic regression via partitioning." Algorithmica 66.1 (2013): 93-112.
// - Ahuja, Ravindra K., and James B. Orlin. "A fast scaling algorithm for minimizing separable
//   convex functions subject to chain constraints." Operations Research 49.5 (2001): 784-789.


int main(int argc, char const *argv[])
{
    int N;
    std::cin >> N;
    std::vector<LL> a(N);

    for (int i=0; i<N; i++) {
        std::cin >> a[i];
    }

    std::cout << non_decreasing_seq(a) << '\n';

    return 0;
}
