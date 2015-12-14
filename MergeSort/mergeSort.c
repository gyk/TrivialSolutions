/*

Merge Sort

Ref:
  Algorithms in C, Robert Sedgewick, Chapter 8

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>

typedef int T;

void fill_array(int arr[], int n)
{
    static bool init = false;
    if (!init) {
        srand(time(NULL));
        init = true;
    }
    for (int i=0; i<n; i++) {
        arr[i] = rand() % 500;
    }
}

void print_array(int arr[], int n)
{
    for (int i=0; i<n; i++) {
        printf("%i ", arr[i]);
    }
    puts("");
}

void merge(T a[], int na, T b[], int nb, int dst[])
{
    int n = na + nb;
    while (n--) {
        if (na == 0) {
            dst[n] = b[--nb];
        } else if (nb == 0) {
            dst[n] = a[--na];
        } else {
            dst[n] = a[na-1] > b[nb-1] ? a[--na] : b[--nb];
        }
    }
}

void merge_AB_R(T src[], T dst[], int n)
{
    int m = n / 2;
    if (m == 0) {
        dst[0] = src[0];
        return;
    }

    merge_AB_R(dst, src, m);
    merge_AB_R(dst + m, src + m, n - m);
    merge(src, m, src + m, n - m, dst);
}

void merge_sort(T a[], int n)
{
    T* aux = (T*)malloc(n * sizeof(T));
    memcpy(aux, a, n * sizeof(T));

    merge_AB_R(aux, a, n);
    free(aux);
}

int main(int argc, char const *argv[])
{
    int n;
    scanf("%d", &n);
	int* a = (int*)malloc(n * sizeof(int));
    fill_array(a, n);
    print_array(a, n);

    merge_sort(a, n);
    print_array(a, n);
    free(a);
	return 0;
}
