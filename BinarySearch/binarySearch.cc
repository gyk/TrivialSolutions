/*

Search a sorted array for the target value using binary search.

*/

#include <vector>
#include <string>
#include <iostream>
#include <sstream>

using std::vector;
using std::string;
using std::istringstream;

// Returns index i if there exists some i s.t. a[i] == t.
// Returns -1 otherwise.
template <typename T>
int bsearch_basic(T a[], T t, int l, int r)
{
    while (l <= r) {
        int m = l + (r - l) / 2;
        if (t < a[m]) {
            r = m - 1;
        } else if (t > a[m]) {
            l = m + 1;
        } else {
            return m;
        }
    }
    return -1;
}


// Similar to `bsearch_basic`, but when there are multiple  
// matches, returns the minimum index. 
// If cannot find any, returns the insert point i where 
// a[i - 1] < t && t < a[i].
template <typename T>
int bsearch_improved(T a[], T t, int l, int r)
{
    while (l <= r) {
        int m = l + (r - l) / 2;
        if (t < a[m]) {
            r = m - 1;
        } else if (t > a[m]) {
            l = m + 1;
        } else {
            if (m - 1 >= l && a[m - 1] == t) {
                r = m - 1;
            } else {
                return m;
            }
        }
    }

    return l;
}

int main()
{
    for (int t; std::cin >> t; ) {
        string line;
        getline(std::cin, line);  // ignores one line
        getline(std::cin, line);
        istringstream iss(line);

        vector<int> a;
        for (int v=0; iss >> v; a.push_back(v));

        int high = a.size() - 1;
        std::cout << bsearch_basic(&a[0], t, 0, high);
        std::cout << ' ';
        std::cout << bsearch_improved(&a[0], t, 0, high);
        std::cout << std::endl;
    }

}
