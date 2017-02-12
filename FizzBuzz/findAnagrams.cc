#include <vector>
#include <string>
#include <iostream>

using std::vector;
using std::string;

class Solution {
public:
    vector<int> findAnagrams(string s, string p) {
        vector<int> found;
        int ns = s.size();
        int np = p.size();
        if (ns < np) return found;
        
        int dict['z' + 1] = {};

        for (int i=0; i<np; i++) {
            dict[s[i]]++;
            dict[p[i]]--;
        }

        int nDiffs = 0;
        for (int i='a'; i<='z'; i++) {
            if (dict[i] != 0) {
                nDiffs++;
            }
        }

        if (nDiffs == 0) {
            found.push_back(0);
        }

        for (int i=1; i<=ns-np; i++) {
            int d;
            d = ++dict[s[i + np - 1]];
            if (d == 0) {
                nDiffs--;
            } else if (d == 1) {
                nDiffs++;
            }

            d = --dict[s[i - 1]];
            if (d == 0) {
                nDiffs--;
            } else if (d == -1) {
                nDiffs++;
            }
            
            if (nDiffs == 0) {
                found.push_back(i);
            }
        }

        return found;
    }
};

int main(int argc, char const *argv[])
{
    Solution sol;
    vector<int> results = sol.findAnagrams("cbaebabacd", "abc");
    for (int pos : results) {
        std::cout << pos << ' ';
    }
    return 0;
}
