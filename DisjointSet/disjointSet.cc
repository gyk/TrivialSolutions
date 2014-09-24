/*

Union-Find (Disjoint set) Algorithm

Refs:
  Algorithms in C, Robert Sedgewick, Chapter 1

*/

#include <iostream>


// disjoint_set.h

class DisJointSet
{
public:
	DisJointSet(int);
	~DisJointSet();

	void merge(int a, int b);
	int find(int a);
	bool connected(int a, int b);

private:
	int* id;
	int* rank;
};

// disjoint_set.cc

DisJointSet::DisJointSet(int n)
{
	id = new int[n];
	for (int i=0; i<n; i++) {
		id[i] = i;
	}
	rank = new int[n]();
}

DisJointSet::~DisJointSet()
{
	delete[] id;
	delete[] rank;
}

void DisJointSet::merge(int a, int b)
{
	int i = find(a), j = find(b);

	if (i == j) {
		return;
	}

	// unions by rank
	if (rank[i] > rank[j]) {
		std::swap(i, j);
	}

	// links node i to j
	id[i] = j;
	rank[j] = std::max(rank[i]+1, rank[j]);

	// It's the same as:
	// rank[j] += (rank[i] == rank[j] ? 1 : 0);
}

int DisJointSet::find(int a)
{
	// doing path compression
	int i;
	for (i=a; i!=id[i]; i=id[i]=id[id[i]]);
	return i;
}

bool DisJointSet::connected(int a, int b)
{
	return find(a) == find(b);
}

////////////////////////////////

int main(int argc, char const *argv[])
{
	int a, b;
	DisJointSet disset(200);
	while (std::cin >> a >> b) {
		std::cout << (int)disset.connected(a, b) << '\n';
		disset.merge(a, b);
	}
	return 0;
}
