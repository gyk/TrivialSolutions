/*

Calculates the edit distance (Levenshtein distance) between two strings.

*/

#include <string>
#include <iostream>
#include <functional>

using std::string;


// Helper functions
template <typename T>
inline T min3(const T& a1, const T& a2, const T& a3)
{
	using std::min;
	return min(min(a1, a2), a3);
}

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


auto& strlen = std::char_traits<char>::length;

int editDistNaive(const char a[], const char b[])
{
	if (a[0] == '\0') {
		return strlen(b);
	} else if (b[0] == '\0') {
		return strlen(a);
	} else if (a[0] == b[0]) {
		return editDistNaive(a+1, b+1);
	} else {
		return 1 + min3(
			editDistNaive(a, b+1), 
			editDistNaive(a+1, b), 
			editDistNaive(a+1, b+1));
	}
}


const int UNDEF = -1;

int editDistTopDown(const string& a, const string& b)
{
	auto memoize = alloc2d<int>(a.length()+1, b.length()+1, UNDEF);

	std::function<int(int, int)> editDistR = 
		[&a, &b, &memoize, &editDistR](int i, int j) -> int 
	{
		if (memoize[i][j] != UNDEF) {
			return memoize[i][j];
		}

		int ed;
		if (i == a.length()) {
			ed = b.length() - j;
		} else if (j == b.length()) {
			ed = a.length() - i;
		} else if (a[i] == b[j]) {
			ed = editDistR(i+1, j+1);
		} else {
			ed = 1 + min3(
				editDistR(i, j+1), 
				editDistR(i+1, j), 
				editDistR(i+1, j+1)
			);
		}
		memoize[i][j] = ed;
		return ed;
	};

	int ed = editDistR(0, 0);
	delete[] memoize;
	return ed;
}


int editDistBottomUp(const string& a, const string& b)
{
	// d[i][j]: distance between a[:i] & b[:j]
	auto d = alloc2d<int>(a.length()+1, b.length()+1, 0);

	for (int i=0; i<=a.length(); i++) {
		for (int j=0; j<=b.length(); j++) {
			if (i == 0) {
				d[i][j] = j;
			} else if (j == 0) {
				d[i][j] = i;
			} else if (a[i-1] == b[j-1]) {
				d[i][j] = d[i-1][j-1];
			} else {
				d[i][j] = 1 + min3(
					d[i][j-1], 
					d[i-1][j], 
					d[i-1][j-1]);
			}
		}
	}

	int ed = d[a.length()][b.length()];
	delete[] d;
	return ed;
}

int main(int argc, char const *argv[])
{
	string a, b;
	std::cin >> a >> b;
	if (a.length() * b.length() < 200) {
		std::cout << editDistNaive(a.c_str(), b.c_str()) << '\n';
	}
	std::cout << editDistTopDown(a, b) << '\n';
	std::cout << editDistBottomUp(a, b) << '\n';
	return 0;
}
