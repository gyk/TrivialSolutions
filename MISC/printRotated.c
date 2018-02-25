/*

Prints Rotated Square

e.g. n = 3, the square is:
1 2 3
4 5 6
7 8 9

Output:
3
2 6
1 5 9
4 8
7

*/

#include <stdio.h>
#include <stdlib.h>

void printDiag(int beg, int end, int stopBeg, int dBeg, int dEnd)
{
	for (; beg!=stopBeg; beg+=dBeg, end+=dEnd) {
		for (int cur=beg; cur<=end; cur+=abs(dEnd-dBeg)) {
			printf("%i ", cur);
		}
		puts("");
	}
}

void printRotated(int n)
{
	printDiag(n, n, 1, -1, n);
	printDiag(1, n * n, n * n + 1, n, -1);
}

int main()
{
	int n;
	scanf("%d", &n);
	printRotated(n);
	return 0;
}
