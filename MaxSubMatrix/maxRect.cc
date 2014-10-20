/*

Maximal Rectangle with all 1s

*/

#include <vector>
#include <stack>
#include <iostream>

using std::stack;
using std::vector;

template <typename T2D>
int maxRect(T2D& a, int m, int n)
{
	using std::max;
	int best = 0;
	
	// # of consecutive 1s ending here, in this column
	for (int i=1; i<m; i++) {
		for (int j=0; j<n; j++) {
			if (a[i][j]) {
				a[i][j] = a[i-1][j] + 1;
			}
		}
	}

	struct HeightPos
	{
		int h;
		int x;
	};

	for (int i=0; i<m; i++) {
		// For each raw, solves the "largest rectangular area in 
		// a histogram" problem
		auto stk = stack<HeightPos>();
		for (int j=0; j<=n; j++) {
			int h = j==n ? 0 : a[i][j];
			int x = j;
			int xToPush = x;

			while (true) {
				if (stk.empty() || stk.top().h < h) {
					stk.push(HeightPos{h, xToPush});
					break;
				}

				if (stk.top().h > h) {
					int area = (x - stk.top().x) * stk.top().h;
					best = max(best, area);
					xToPush = stk.top().x;
					stk.pop();
				} else {  // stk.top().h == h
					break;
				}
			}
			
		}
	}

	return best;
}

inline void ignores(std::istream& istrm)
{
	// ignores {' ', '\t'}
	for (char c; (c=istrm.peek()) && (c==' ' || c=='\t'); istrm.ignore());
}

int main(int argc, char const *argv[])
{
	using std::cin;
	auto a = vector<vector<int>>();

	while (cin) {
		auto aa = vector<int>();
		for (int v; 
			(cin.peek() != '\n') && (cin >> v);
			ignores(cin)) {
				aa.push_back(v);
		}
		cin.ignore();  // eats newline
		if (aa.size() > 0) {
			a.push_back(aa);
		}
	}

	std::cout << maxRect(a, a.size(), a[0].size());
	return 0;
}
