/*

Balanced Partition Problem

*/

#include <algorithm>
#include <numeric>
#include <iostream>

template <typename T>
T** alloc2d(size_t nr, size_t nc, T filled)
{
	auto a = (T**)new char[nr * sizeof(T*) + nr * nc * sizeof(T)];
	for (int i=0; i<nr; i++) {
		a[i] = (T*)(a + nr) + i * nc;
	}
	std::fill_n(a[0], nr * nc, filled);
	return a;
}

bool balancedPartition(int a[], int n)
{
	int sum = std::accumulate(a+1, a+1+n, 0);
	if (sum % 2) {
		return false;
	}
	int half = sum / 2;

	// isSumOf[i][j] == true: sum of subarray of a[0..i] == j
	bool** isSumOf = alloc2d(n+1, half+1, false);
	for (int i=0; i<=n; i++) {
		isSumOf[i][0] = true;
	}

	for (int i=1; i<=n; i++) {
		for (int j=1; j<=half; j++) {
			isSumOf[i][j] = isSumOf[i-1][j] || 
				j - a[i] >= 0 && isSumOf[i-1][j - a[i]];
		}
	}

	int ret = isSumOf[n][half];
	delete[] isSumOf;
	return ret;
}

int main(int argc, char const *argv[])
{
	std::vector<int> a{0};
	for (int v; std::cin >> v; a.push_back(v));
	std::cout << (balancedPartition(&a[0], a.size() - 1) ? "true" : "false");
	return 0;
}
