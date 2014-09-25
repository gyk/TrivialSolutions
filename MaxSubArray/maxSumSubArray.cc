/*

Maximum Subarray Problem

Chapter 8 of Programming Pearls by Jon Bentley

*/

#include <vector>
#include <iostream>

int maxSumSubArray(int a[], int n)
{
	int maxSofar = 0;
	for (int i=0, endsHere=0; i<n; i++) {
		endsHere += a[i];
		if (a[i] > 0) {
			if (endsHere > maxSofar) {
				maxSofar = endsHere;
			}
		} else {
			if (endsHere < 0) {
				endsHere = 0;
			}
		}
	}
	return maxSofar;
}

int main(int argc, char const *argv[])
{
	std::vector<int> a;
	for (int v; std::cin >> v; a.push_back(v));
	std::cout << maxSumSubArray(&a[0], a.size());
	return 0;
}
