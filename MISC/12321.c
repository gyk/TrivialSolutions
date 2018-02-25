#include <stdio.h>
#include <stdlib.h>

/********
    func(1, 1);  ->  1
    func(1, 3);  ->  1 2 3 2 1
    func(1, 6);  ->  1 2 3 4 5 6 5 4 3 2 1

`func` should be implemented without any loop, if-statement or 
conditional operation.
********/

int func(int i, int n)
{
    return printf("%d %.0s", (n - abs(i - n)), i + 1 == n * 2 || func(i + 1, n));
}


int main(int argc, char const *argv[])
{
    func(1, 1); puts("");
    func(1, 3); puts("");
    func(1, 6); puts("");
    return 0;
}
