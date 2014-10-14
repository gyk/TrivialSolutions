/*

Slightly Obfuscated FizzBuzz in C

Compile:
  gcc fizzBuzz.c -o fizzBuzz

*/

#include <stdio.h>

#define x0(x) 0x##x
char a[]="uz FiB", y, i;
char prn(char x)
{
  for(; putchar(a[x]), y!=x; y=x, x=(a[x]&x0(15))%5);
  return 0;
}

int main()
{
  for(; ++i<=100; putchar(a[5%3]))
    if(((i%3)||prn(3)) & ((i%5)||prn(5)))
      printf("%d", i);
  return 0;
}
