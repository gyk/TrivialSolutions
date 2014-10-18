/*

Largest all-1 Square Sub-matrix

Given a binary matrix, find the maximum size of 
square sub-matrix with all 1s.

*/

#include <algorithm>
#include <iostream>

template <typename T>
T** alloc2d(size_t nr, size_t nc, T filled)
{
	auto a = (T**)new char[nr * sizeof(T*) + nr * nc * sizeof(T)];
	for (size_t i=0; i<nr; i++) {
		a[i] = (T*)(a + nr) + i * nc;
	}
	std::fill_n(a[0], nr * nc, filled);
	return a;
}

int maxSquare(int** a, int m, int n)
{
	using std::min;
	int best = 0;
	auto update_best = [&best](int x) {
		best = std::max(best, x);
		return x;
	};
	// largest square sub-matrix that ends here
	int** here = alloc2d(m, n, 0);

	for (int i=0; i<m; i++) {
		here[i][0] = update_best(a[i][0]);
	}
	for (int j=1; j<n; j++) {
		here[0][j] = update_best(a[0][j]);
	}

	for (int i=1; i<m; i++) {
		for (int j=1; j<n; j++) {
			if (a[i][j]) {
				here[i][j] = update_best(
					1 + min(here[i-1][j-1], min(here[i-1][j], here[i][j-1])));
			} else {
				here[i][j] = 0;
			}
		}
	}
	
	delete[] here;
	return best;
}

int main(int argc, char const *argv[])
{
	int m, n;
	std::cin >> m >> n;
	int** a = alloc2d(m, n, 0);

	for (int i=0; i<m; i++) {
		for (int j=0; j<n; j++) {
			std::cin >> a[i][j];
		}
	}

	std::cout << maxSquare(a, m, n);

	delete[] a;
	return 0;
}
