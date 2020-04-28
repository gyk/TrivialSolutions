// SGU 505 - Prefixes and suffixes
//
// Ref: http://www.shuizilong.com/house/archives/sgu-505-prefixes-and-suffixes/

#include <iostream>
#include <memory>
#include <string>
#include <algorithm>
#include <vector>

using std::string, std::vector, std::pair;
using std::shared_ptr;

class FenwickTree
{
public:
    FenwickTree(int n) : n(n), a(n + 1, 0) {}

    void inc(int i)
    {
        for (i++; i <= this->n; i += i & (-i)) {
            this->a[i]++;
        }
    }

    int prefix_sum(int i) const // Exclusively
    {
        int s = 0;
        for (; i > 0; i -= i & (-i)) {
            s += this->a[i];
        }
        return s;
    }

private:
    int n;
    vector<int> a;
};

struct Query
{
    int beg, end;
    bool opened;
    int value;
    Query(int beg, int end) :
        beg(beg), end(end), opened(false), value(0) {}
    Query(const Query&) = delete;

    void update(const FenwickTree& ft)
    {
        int sum = ft.prefix_sum(this->end) - ft.prefix_sum(this->beg);
        if (this->opened) {
            this->value += sum;
        } else {
            this->value -= sum;
            this->opened = true;
        }
    }
};

bool cmp(const pair<string, int>& p, const string& s)
{
    return p.first < s;
}

pair<int, int> find_range(const vector<pair<string, int>>& a, string& s)
{
    int beg = std::lower_bound(a.begin(), a.end(), s, cmp) - a.begin();
    ++s.back();
    int end = std::lower_bound(a.begin(), a.end(), s, cmp) - a.begin();
    --s.back();
    return std::pair(beg, end);
}

int main(int argc, char const *argv[])
{
    int n_genomes;
    std::cin >> n_genomes;

    vector<pair<string, int>> pre_a, suf_a;
    pre_a.reserve(n_genomes);
    suf_a.reserve(n_genomes);

    for (int i=0; i<n_genomes; i++) {
        std::cin >> pre_a.emplace_back(string(), 0).first;
    }
    std::sort(pre_a.begin(), pre_a.end());

    for (int i=0; i<n_genomes; i++) {
        auto& [s, _] = pre_a[i];
        string rev_s(s.rbegin(), s.rend());
        suf_a.emplace_back(rev_s, i);
    }
    std::sort(suf_a.begin(), suf_a.end());
    for (int i=0; i<n_genomes; i++) {
        pre_a[suf_a[i].second].second = i;
    }

    int n_tests;
    std::cin >> n_tests;

    vector<shared_ptr<Query>> queries(n_tests);
    vector<vector<shared_ptr<Query>>> query_events(n_genomes + 1, vector<shared_ptr<Query>>());

    for (int t=0; t<n_tests; t++) {
        string pre, suf;
        std::cin >> pre >> suf;
        std::reverse(suf.begin(), suf.end());

        auto [pre_beg, pre_end] = find_range(pre_a, pre);
        auto [suf_beg, suf_end] = find_range(suf_a, suf);

        auto q = std::make_shared<Query>(suf_beg, suf_end);
        queries[t] = q;
        if (pre_beg == pre_end || suf_beg == suf_end) {
            continue;
        }

        query_events[pre_beg].push_back(q);
        query_events[pre_end].push_back(q);
    }

    auto ft = FenwickTree(n_genomes);
    for (int i=0; i<=n_genomes; i++) {
        for (auto& q : query_events[i]) {
            q->update(ft);
        }
        if (i < n_genomes) { ft.inc(pre_a[i].second); }
    }

    for (auto& q : queries) {
        std::cout << q->value << std::endl;
    }
    return 0;
}
