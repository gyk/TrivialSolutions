#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
#include <assert.h>

typedef int T;

// k: 0-based index
T kth_of_two_sorted(T a[], int na, T b[], int nb, int k)
{
    T* a_end = a + na;
    T* b_end = b + nb;
    T** x;

    while (k >= 0) {
        // Note: `p + 1` makes the loop still work even if k < 3.
        int p = (k - 1) / 2;
        if (a + p >= a_end || b + p < b_end && a[p] > b[p]) {
            x = &b;
        } else {
            x = &a;
        }
        *x += p + 1;
        k -= p + 1;
    }
    return *--*x;
}

void fill_array(int* arr, int n)
{
    static bool init = false;
    if (!init) {
        srand(time(NULL));
        init = true;
    }
    for (int i=0; i<n; i++) {
        arr[i] = rand() % 100;
    }
}

int cmp(const void* s, const void* t)
{
    return *(int*)s - *(int*)t;
}

int main()
{
    int na, nb;
    int k;
    scanf("%d%d%d", &na, &nb, &k);
    assert(k < na + nb);

    int* arr = (int*)malloc(sizeof(int) * (na + nb));
    fill_array(arr, na + nb);
    int* a = arr;
    int* b = a + na;
    qsort(a, na, sizeof(int), cmp);
    qsort(b, nb, sizeof(int), cmp);

    int kth = kth_of_two_sorted(a, na, b, nb, k);

    qsort(arr, na + nb, sizeof(int), cmp);
    assert(arr[k] == kth);

    free(arr);
    return 0;
}
