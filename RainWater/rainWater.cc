#include <cassert>

#include <vector>
#include <algorithm>

using std::vector;

class Solution {
public:
    int trapThreePasses(vector<int>& height) {
        int v = 0;
        int n = height.size();
        if (n == 0) { return v; }

        auto l_hi = height;
        for (int i=1; i<n; i++) {
            l_hi[i] = std::max(l_hi[i], l_hi[i-1]);
        }

        auto r_hi = height;
        for (int i=n-2; i>=0; i--) {
            r_hi[i] = std::max(r_hi[i], r_hi[i+1]);
        }

        for (int i=1; i<n-1; i++) {
            int h = std::min(l_hi[i], r_hi[i]);
            v += std::max(h - height[i], 0);
        }

        return v;
    }

    int trapOnePass(vector<int>& height) {
        int v = 0;
        int n = height.size();
        if (n == 0) { return v; }

        int l = 0, r = n - 1;
        int l_hi = height[l], r_hi = height[r];

        while (l < r) {
            if (l_hi < r_hi) {
                l++;
                if (l_hi > height[l]) {
                    v += l_hi - height[l];
                } else {
                    l_hi = height[l];
                }
            } else {
                r--;
                if (r_hi > height[r]) {
                    v += r_hi - height[r];
                } else {
                    r_hi = height[r];
                }
            }
        }

        return v;
    }
};
