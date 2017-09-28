#include <cassert>

#include <vector>
#include <algorithm>

using std::vector;

// Pre-condition: the input vector is non-empty.

class Solution {
public:
    int findMinNoDup(vector<int>& a) {
        int l = 0, r = a.size() - 1;
        while (a[l] > a[r]) {
            int m = (l + r) / 2;
            if (a[m] > a[r]) {
                l = m + 1;
            } else {
                l++;
                r = m;
            }
        }
        return a[l];
    }

    int findMinWithDup(vector<int>& a) {
        int l = 0, r = a.size() - 1;
        while (a[l] >= a[r]) {
            int m = (l + r) / 2;
            if (a[m] > a[r]) {
                l = m + 1;
            }/*
                If the control flow goes here, we have:

                a[l] >= a[r] >= a[m]
            */else if (a[l] > a[m]) {
                l++;
                r = m;
            } else if ((r--) - (l++) <= 2) {
                return a[m];
            }
        }
        return a[l];
    }
};

int main(int argc, char const *argv[])
{
    Solution sol;

    vector<int> v;
    int i = 0;
    for (; i<10; i++) {
        v.push_back(i);
    }

    for (; i; i--) {
        assert(v[0] + i == 10);
        std::rotate(v.begin(), v.begin() + 1, v.end());
        int no_dup = sol.findMinNoDup(v);
        int with_dup = sol.findMinWithDup(v);
        assert(no_dup == with_dup && no_dup == 0);
    } 

    v.clear();
    v.push_back(3);
    v.push_back(3);
    v.push_back(1);
    v.push_back(3);
    
    assert(sol.findMinWithDup(v) == 1);
    return 0;
}
