#include <iostream>
#include <string>
#include <algorithm>
#include <vector>

using std::string, std::vector, std::pair;

vector<string> pre_a;
vector<pair<string, int>> suf_a;

bool cmp(const pair<string, int>& p, const string& s)
{
    return p.first < s;
}

int solve(string& pre, string& suf)
{
    auto pre_beg_it = std::lower_bound(pre_a.begin(), pre_a.end(), pre);
    ++pre.back();
    auto pre_end_it = std::lower_bound(pre_a.begin(), pre_a.end(), pre);
    --pre.back();

    int beg_i = pre_beg_it - pre_a.begin();
    int end_i = pre_end_it - pre_a.begin();

    int cnt = 0;
    auto suf_it = std::lower_bound(suf_a.begin(), suf_a.end(), suf, cmp);
    ++suf.back();
    for (; suf_it != suf_a.end() && suf_it->first < suf; ++suf_it) {
        int i = suf_it->second;
        if (beg_i <= i && i < end_i) {
            cnt++;
        }
    }
    --suf.back();
    return cnt;
}

int main(int argc, char const *argv[])
{
    int n_genomes;
    std::cin >> n_genomes;
    pre_a.reserve(n_genomes);
    suf_a.reserve(n_genomes);
    for (int i=0; i<n_genomes; i++) {
        std::cin >> pre_a.emplace_back(string());
    }
    std::sort(pre_a.begin(), pre_a.end());

    for (int i=0; i<n_genomes; i++) {
        string s = pre_a[i];
        string rev_s(s.rbegin(), s.rend());
        suf_a.emplace_back(rev_s, i);
    }
    std::sort(suf_a.begin(), suf_a.end());

    int n_tests;
    std::cin >> n_tests;
    for (int i=0; i<n_tests; i++) {
        string pre, suf;
        std::cin >> pre >> suf;
        std::reverse(suf.begin(), suf.end());
        std::cout << solve(pre, suf) << std::endl;
    }
    return 0;
}
