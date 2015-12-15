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
        printf("%4i ", arr[i]);
    }
    puts("");
}

bool check_same(int a[], int b[], int n)
{
    for (int i=0; i<n; i++) {
        if (a[i] != b[i]) {
            printf("a != b @ %i\n", i);
            print_array(a, n);
            print_array(b, n);
            puts("");
            return false;
        }
    }
    return true;
}

int cmp(const void* s, const void* t)
{
    return *(int*)s - *(int*)t;
}

////////////////////////////////

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

// This routine provides in-place merge interface, despite that 
// under the hood it does use an auxiliary array of size O(n) 
// -- so called "abstract in-place merge".
void merge_abstract_in_place(T a[], int na, T b[], int nb)
{
    assert(a + na == b);
    static T* aux = NULL;
    static int n = 0;
    if (na + nb > n) {
        free(aux);  // no problem
        aux = NULL;
    }
    n = na + nb;
    if (!aux) {
        aux = (T*)malloc(n * sizeof(T));
    }
    
    merge(a, na, b, nb, aux);
    memcpy(a, aux, n * sizeof(T));
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

void merge_sort_top_down(T a[], int n)
{
    T* aux = (T*)malloc(n * sizeof(T));
    memcpy(aux, a, n * sizeof(T));

    merge_AB_R(aux, a, n);
    free(aux);
}

void merge_sort_bottom_up(T a[], int n)
{
    // doing m-by-m merge
    for (int m=1; m<n; m+=m) {
        for (int i=0; i+m<n; i+=m+m) {  // (!) i+m<n, not i<n
            T* r = a + i + m;
            merge_abstract_in_place(a + i, m, r, 
                r + m <= a + n ? m : a + n - r);
        }
    }
}

int main(int argc, char const *argv[])
{
    int n;
    scanf("%d", &n);
	int* a = (int*)malloc(n * sizeof(int));
    fill_array(a, n);

    int *a_TD = (int*)malloc(n * sizeof(int));
    int *a_BU = (int*)malloc(n * sizeof(int));
    memcpy(a_TD, a, n * sizeof(int));
    memcpy(a_BU, a, n * sizeof(int));

    qsort(a, n, sizeof(int), cmp);

    // test top-down merge
    merge_sort_top_down(a_TD, n);
    assert(check_same(a, a_TD, n));

    // test bottom_up merge
    merge_sort_bottom_up(a_BU, n);
    assert(check_same(a, a_BU, n));

    free(a);
    free(a_TD);
    free(a_BU);
	return 0;
}
