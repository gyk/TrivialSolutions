// SGU 506 - Subsequences Of Substrings
// https://codeforces.com/problemsets/acmsguru/problem/99999/506


#include <iostream>
#include <string>
#include <string_view>
#include <vector>

using std::string, std::string_view;
using std::vector;

/** S1 - Time Limit Exceeded **/

int match(const string_view text, const string_view msg)
{
    int l_text = text.length();
    int l_msg = msg.length();

    int j = 0;
    for (int i=0; i<l_msg; i++) {
        do {
            if (j == l_text) return 0;
        } while (text[j++] != msg[i]);
    }
    return j; // points to the upper bound (exclusive)
}

long long solve_tle(string_view text, string_view msg)
{
    long long count = 0;

    while (text.length() >= msg.length()) {
        int m = match(text, msg);
        if (m > 0) {
            count += text.length() - m + 1;
        } else {
            break;
        }
        text.remove_prefix(1);
    }

    return count;
}

/** S2 - Accepted **/

long long solve(const string_view text, const string_view msg)
{
    long long count = 0;

    const int l_text = text.length();
    const int l_msg = msg.length();

    vector<int> m(l_msg, -1);

    auto match = [&](int start) -> bool
    {
        int j = start;
        for (int i=0; i<l_msg; i++) {
            if (m[i] >= j) {
                break;
            }
            do {
                if (j == l_text) return false;
            } while (text[j++] != msg[i]);
            m[i] = j - 1;
        }
        return true;
    };

    int start = 0;
    while (l_text - start >= l_msg && match(start)) {
        count += static_cast<long long>(m[0] - start + 1) * (l_text - m.back());
        start = m[0] + 1;
    }

    return count;
}

int main(int argc, char const *argv[])
{
    string text, msg;
    std::cin >> text >> msg;
    std::cout << solve(text, msg) << std::endl;
    return 0;
}
