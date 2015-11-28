#include <cstdlib>
#include <ctime>
#include <cassert>

#include <set>
#include <iostream>

#include "SkipList.h"

using std::set;
using std::cin;
using std::cout;

set<int> random_ints(int n = 10)
{
    static bool initialized = false;
    if (!initialized) {
        std::srand(static_cast<unsigned int>(std::time(nullptr)));
        initialized = true;
    }

    const int U_BOUND = 100;
    set<int> a;  // # of elements might be less than n
    for (int i=0; i<n; i++) {
        a.insert(std::rand() % U_BOUND);
    }
    return a;
}

int main()
{
    SkipList<int> sk;
    auto a = random_ints();
    for (auto v : a) {
        sk.insert(v);
    }

    for (auto v : a) {
        cout << v << '\t';
    }
    cout << '\n';

    cout << "\n# of layers:\n    ";
    auto histo = numLayersStat(&sk);
    for (auto v : histo) {
        cout << v << "  ";
    }

    cout << "\n\nVisualize the skip list:\n";
    printSkipList(&sk);
    cout << '\n';

    auto b = random_ints(10);
    for (auto v : b) {
        cout << v << '\t';
    }
    cout << '\n';

    cout << "\nSearching:\n";
    for (auto v : b) {
        SkNode<int>* target = sk.search(v);
        if (target) {
            cout << target->item << '\t';
        } else {
            cout << "N/A\t";
            assert(a.find(v) == a.end());
        }
    }
    cout << '\n';

    for (auto t : a) {
        assert(sk.search(t));
        sk.remove(t);
        assert(sk.search(t) == nullptr);
    }
    printSkipList(&sk);  // should print nothing

    return 0;
}
