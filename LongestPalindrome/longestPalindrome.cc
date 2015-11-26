/*

Longest Palindrome by Manacher's algorithm

*/

#include <string>
#include <vector>
#include <iostream>
#include <algorithm>

using std::string;
using std::vector;

string preprocess(const string& s)
{
    // "banana" -> "^#b#a#n#a#n#a#$"
    int len = s.length();
    string r(len * 2 + 1 + 2, '#');
    r[0] = '^';
    r[r.length() - 1] = '$';

    for (int i=0; i<len; i++) {
        r[i * 2 + 2] = s[i];
    }
    
    return r;
}

int longest_naive(const string& s_)
{
    string s = preprocess(s_);
    int len = s.length();
    int longest_so_far = 0;
    for (int i=0; i<len; i++) {
        int l = i, r = i;
        int len_p = 0;
        while (--l >=0 && ++r < len) {
            if (s[l] != s[r]) {
                break;
            }
            len_p = (r - l) / 2;
        }
        if (len_p > longest_so_far) {
            longest_so_far = len_p;
        }
    }
    return longest_so_far;
}

int longest(const string& s_)
{
    string s = preprocess(s_);
    int len = s.length();
    int C = 0;
    int longest_so_far = 0;
    vector<int> p(len, 0);

    for (int i=1; i<len-1; i++) {
        int i_mirrored = C * 2 - i;
        int R = C + p[C];
        if (i > R) {
            while (s[i + p[i] + 1] == s[i - p[i] - 1]) {
                p[i]++;
            }
        } else {
            p[i] = std::min(R - i, p[i_mirrored]);
        }

        longest_so_far = std::max(p[i], longest_so_far);
    }

    return longest_so_far;
}

int main(int argc, char const *argv[])
{
    string s;
    std::cin >> s;
    std::cout << longest_naive(s) << ' ';
    std::cout << longest(s) << '\n';
    return 0;
}
