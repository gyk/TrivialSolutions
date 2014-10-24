
#include <cstdlib>
#include <vector>
#include <string>
#include <iostream>

template <typename T>
inline T min3(const T& a1, const T& a2, const T& a3)
{
	using std::min;
	return min(min(a1, a2), a3);
}

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

// NOTE: VC++ 2010 compiler cannot deduce the template arguments.
// Use G++ or Clang.

template <typename TRndIt, typename TDist>
TDist dynamicTimeWarping(TRndIt a, size_t na, TRndIt b, size_t nb, 
	TDist (* const& dist)(decltype(*a)& x, decltype(*b)& y))
{
	// assert(na != 0 && nb != 0);
	TDist** d = alloc2d(na, nb, TDist());

	d[0][0] = dist(a[0], b[0]);
	for (int i=1; i<na; i++) {
		d[i][0] = d[i-1][0] + dist(a[i], b[0]);
	}
	for (int j=0; j<nb; j++) {
		d[0][j] = d[0][j-1] + dist(a[0], b[j]);
	}

	for (int i=1; i<na; i++) {
		for (int j=1; j<nb; j++) {
			d[i][j] = dist(a[i], b[j]) + min3(
					d[i][j-1], 
					d[i-1][j], 
					d[i-1][j-1]);
		}
	}

	auto ret = d[na-1][nb-1];
	delete[] d;
	return ret;
}

// Cannot deduce template argument if using lambda:
// 
// auto manhattan = [](const int& x, const int& y) -> int {
// 	return abs(x - y);
// };

int manhattan(const int& x, const int& y)
{
	return abs(x - y);
}

int main(int argc, char const *argv[])
{
	auto a = std::vector<int>();
	auto b = std::vector<int>();
	for (int v; std::cin >> v; a.push_back(v));
	std::cin.clear();

	std::string s;
	std::cin >> s;

	for (int v; std::cin >> v; b.push_back(v));

	// we need const_iterator
	const auto& ac = a;
	const auto& bc = b;

	// If compiled with VC++, it should be rewritten as:
	//     std::cout << dynamicTimeWarping<decltype(ac.begin()), int>
	//         (ac.begin(), ac.size(), bc.begin(), bc.size(), manhattan);
	
	// NOTE: the `&` before function name is crucial (tested in 
	// g++ (GCC) 4.6.2).
	std::cout << dynamicTimeWarping(ac.begin(), ac.size(), 
		bc.begin(), bc.size(), &manhattan);

	return 0;
}
