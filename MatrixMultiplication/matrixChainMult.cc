/*

Matrix-chain Multiplication Problem

*/

#include <cassert>
#include <vector>
#include <iostream>

typedef int pairs[][2];

const int INT_MAX = ((unsigned)(~0)) >> 1;

template <typename T>
T** alloc2d(size_t nr, size_t nc, T filled)
{
	auto a = (T**)new T[nr * (nc + 1)];
	for (int i=0; i<nr; i++) {
		a[i] = (T*)a + nr + i * nc;
	}
	std::fill_n(a[0], nr * nc, filled);
	return a;
}

inline int multimes(int r1, int c1r2, int c2)
{
	return r1 * c1r2 * c2;
}

int matrixChainMult(pairs mSizes, int nPairs)
{
	auto m = alloc2d<int>(nPairs, nPairs, 0);

	for (int len=1; len<nPairs; len++) {
		for (int i=0; i<nPairs-len; i++) {
			int min = INT_MAX;
			for (int pivot=i+1; pivot<=i+len; pivot++) {
				int nTimes = m[i][pivot-1] + m[pivot][i+len] + 
					multimes(mSizes[i][0], mSizes[pivot-1][1], mSizes[i+len][1]);
				if (nTimes < min) {
					min = nTimes;
				}
			}
			m[i][i+len] = min;
		}
	}

	int ret = m[0][nPairs-1];
	delete[] m;
	return ret;
}

int main(int argc, char const *argv[])
{
	std::vector<int> a;
	for (int v; std::cin >> v; a.push_back(v));
	int nPairs = a.size() / 2;
	assert(a.size() - nPairs * 2 == 0);
	// WORKAROUND: ISO C++ forbids casting to an array type
	std::cout << matrixChainMult((pairs&)(*&a[0]), nPairs);
	return 0;
}
