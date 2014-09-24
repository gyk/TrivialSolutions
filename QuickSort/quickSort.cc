/*

Quick Sort

Based on Chapter 3 of Beautiful Code by Jon Bentley.

*/

#include <cstdlib>
#include <vector>
#include <iostream>

template <typename T>
void quickSort(T& a, const int begin, const int end)
{
	// range [begin, end)
	if (end - begin <= 1) {
		return;
	}

	int index = begin + std::rand() % (end - begin);
	std::swap(a[begin], a[index]);

	// Partitioning 
	int i, pivot;
	for (i = pivot = begin + 1; 
		i < end; 
		i++) {
		if (a[i] < a[begin]) {
			std::swap(a[i], a[pivot++]);
		}
	}
	std::swap(a[begin], a[pivot - 1]);

	quickSort(a, begin, pivot);
	quickSort(a, pivot, end);
}

int main(int argc, char const *argv[])
{
	std::vector<int> a;
	for (int v; std::cin >> v; a.push_back(v));

	quickSort(a, 0, a.size());

	for (auto& el : a) {
		std::cout << el << ' ';
	}

	return 0;
}
