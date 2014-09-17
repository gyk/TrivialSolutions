/*
Longest Increasing Subsequence
Implemented according to the USACO dynamic programming tutorial.
*/

#include <limits>
#include <vector>
#include <algorithm>
#include <iostream>

template <typename T>
int longest_subseq1(const T& a, int n)
{
	// the length of longest sequence that ends here
	int* ends_here = new int[n]();
	int longest = 0;

	ends_here[0] = 1;
	for (int i=1; i<n; i++) {
		for (int j=i-1; j>=0; j--) {
			if (a[j] < a[i] && ends_here[j] >= ends_here[i]) {
				ends_here[i] = ends_here[j] + 1;
				if (ends_here[i] > longest) {
					longest = ends_here[i];
				}
			}
		}
	}

	delete[] ends_here;
	return longest;
}

template <typename T>
int longest_subseq2(const T& a, int n)
{
	// best_run[i] stores the ending value of the longest
	// sequence of length i so far.
	int* best_run = new int[n+1];
	std::fill_n(best_run, n+1, std::numeric_limits<int>::max());

	best_run[1] = a[0];
	int longest = 1;
	for (int i=1; i<n; i++) {
		int j;
		// loops until better than best
		// (can be further accelerated using binary search)
		for (j=1; best_run[j]<a[i]; j++);
		best_run[j] = a[i];
		longest = std::max(longest, j);
	}

	delete[] best_run;
	return longest;
}

int main(int argc, char const *argv[])
{
	std::vector<int> a;
	int v;
	while (std::cin >> v) {
		a.push_back(v);
	}

	std::cout << longest_subseq1(a, a.size()) << '\n';
	std::cout << longest_subseq2(a, a.size()) << '\n';

	return 0;
}
