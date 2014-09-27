#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define SWAP_INT(a, b) { int t; t = a; a = b; b = t; }

const int MAX_N = 80;
int queen[MAX_N] = {0};

bool horiz[MAX_N] = {false};
bool diag[MAX_N*2] = {false};
bool anti_diag[MAX_N*2] = {false};

int n;

bool place(int row)
{
	int col = queen[row];
	if (horiz[col] || anti_diag[row + col] || diag[row - col + n - 1]) {
		return false;
	} else {
		horiz[col] = anti_diag[row + col] = diag[row - col + n - 1] = true;
		return true;
	}
}

void take(int row)
{
	int col = queen[row];
	horiz[col] = anti_diag[row + col] = diag[row - col + n - 1] = false;
}

void plot()
{
	int i, j;
	for (i=0; i<n; i++, printf("\n")) {
		for (j=0; j<n; j++) {
			printf(j == queen[i] ? "Q " : ". ");
		}
	}
}

void print()
{
	int i;
	for (i=0; i<n; i++) {
		printf("%d %d\n", i+1, queen[i]+1);
	}
}

bool backtrack(int k)
{
	while (k >= 0) {
		while (queen[k] < n) {
			if (place(k)) {
				if (k+1 == n) {
					plot();
					return true;
				}
				k++;
				goto NEXT;
			}
			queen[k]++;
		}
		queen[k] = 0;
		k--;
		take(k);
		queen[k]++;
NEXT:;
	}
	return false;
}

void las_vegas(int m)
{
	int i;
	do {
		// random shuffling
		for (int ii=0; ii<n; ii++) {
			queen[ii] = ii;
		}
		for (i=0; i<m; ) {
			int j = (int)((double)rand() / (RAND_MAX + 1) * (n - i)) + i;
			SWAP_INT(queen[i], queen[j]);
			if (!place(i)) {
				SWAP_INT(queen[i], queen[j]);
			} else {
				i++;
			}
		}
	} while (i < m);

	for (; i<n; i++) {
		queen[i] = 0;
	}
}

int main(int argc, char const *argv[])
{
	srand((unsigned)time(NULL));
	scanf("%d", &n);
	if (n > MAX_N) {
		puts("Are you kidding?");
		return 0;
	}
	
	if (n > 10) {
		int m = n / 2;
		do {
			las_vegas(m);
		} while (!backtrack(m));
	} else {
		backtrack(0);
	}

	return 0;
}
