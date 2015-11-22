/*

Robin-Karp & Knuth-Morris-Pratt

*/

#include <cstdlib>
#include <ctime>

#include <cassert>

#include <string>
#include <vector>
#include <iostream>

using std::string;
using std::vector;

int robin_karp(const string& s, const string& p);
int kmp(const string& s, const string& p);

int robin_karp(const string& s, const string& p)
{
    const int BASE = 3137;
    int s_len = s.length(), p_len = p.length();
    int ss = 0, pp = 0;
    int highest = 1;
    // integer overflow as implicit modulo
    for (int i=0; i<p_len; i++) {
        ss = ss * BASE + s[i];
        pp = pp * BASE + p[i];
        highest = highest * BASE;
    }

    auto match_here = [&s, &p](int i)
    {
        int p_len = p.length();
        for (int j=0; j<p_len; j++) {
            if (s[i + j] != p[j]) {
                return false;
            }
        }
        return true;
    };

    for (int i=0; i<=s_len-p_len; i++) {
        if (ss == pp) {
            // checks whether it is a spurious hit
            if (match_here(i)) {
                return i;
            }
        }
        ss = ss * BASE - highest * s[i] + s[i + p_len];
    }
    return -1;
}

// just for debugging purpose
vector<int> build_next_naive(const string& p)
{
    int len = p.length();
    vector<int> next(len, -1);
    next[0] = -1;
    next[1] = p[0] == p[1] ? 0 : -1;

    for (int j=2; j<len; j++) {
        for (int offset=1; offset<=j; offset++) {
            bool matched = true;
            for (int k=0; offset+k<=j; k++) {
                if (p[offset + k] != p[k]) {
                    matched = false;
                    break;
                }
            }
            if (matched) {
                next[j] = j - offset;
                break;
            }
        }
    }
    return next;
}

vector<int> build_next(const string& p)
{
    int len = p.length();
    vector<int> next(len, -1);

    // next[j] == argmax j' s.t. p[0..j'] == p[(j-j')..j]
    //
    // So if s[i..(i+j)] == p[0..j] and s[i+j+1] != p[j+1],
    // we can ensure that s[(j - next[j])..j] == p[0..next[j]].

    for (int j=1; j<len; j++) {
        int prev_next = next[j - 1];
        for (;;) {
            if (p[j] == p[prev_next + 1]) {
                next[j] = prev_next + 1;
                break;
            } else {
                if (prev_next == -1) {
                    break;
                }
                prev_next = next[prev_next];
            }
        }

    }

    return next;
}

int kmp(const string& s, const string& p)
{
    vector<int> next = build_next(p);
    int s_len = s.length(), p_len = p.length();
    int i = 0, j = 0;
    while (i < s_len) {
        if (s[i] == p[j]) {
            i++;
            j++;
            if (j == p_len) {
                return i - p_len;
            }
        } else {
            if (j == 0) {
                i++;
            } else {
                j = next[j - 1] + 1;
            }
        }

    }

    return -1;
}

// generates test cases
string random_string(int len)
{
    static const char alphanum[] = "ABC";
    static bool initialized = false;

    if (!initialized) {
        std::srand(std::time(NULL));
        initialized = true;
    }

    string s(len, '\0');
    for (int i = 0; i < len; i++) {
        s[i] = alphanum[rand() % (sizeof(alphanum) - 1)];
    }
    return s;
}

int main()
{
    int n_tests;
    std::cin >> n_tests;

    while (n_tests--) {
        const int S_LEN = 250, P_LEN = 5;
        string s_str, p_str;
        s_str = random_string(S_LEN);
        p_str = random_string(P_LEN);
        assert(build_next(p_str) == build_next_naive(p_str));

        std::cout << s_str << '\n' << p_str << '\n';
        int ind = s_str.find(p_str);
        int ind_robin_karp = robin_karp(s_str, p_str);
        int ind_kmp = kmp(s_str, p_str);
        assert(ind == ind_robin_karp && ind == ind_kmp);
        std::cout << ind << "\n\n";
    }
}
