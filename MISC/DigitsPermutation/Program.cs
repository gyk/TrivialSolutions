// SGU 502 - Digits Permutation
//
// The probability of the algorithm NOT finding an answer after n-th iteration is $(16/17)^n$.
using System;
using System.Linq;
using System.Collections.Generic;

namespace DigitsPermutation
{
    class Program
    {
        public static IEnumerable<int[]> permutations(int[] a)
        {
            int n = a.Length;
            IEnumerable<int[]> permR(int k)
            {
                if (k == 0) {
                    yield return a;
                } else {
                    var used = new bool[10];
                    for (int i = 0; i <= k; i++) {
                        if (!used[a[i]] && (k < n - 1 || a[i] != 0)) {
                            used[a[i]] = true;
                            (a[i], a[k]) = (a[k], a[i]);
                            foreach (var x in permR(k - 1)) {
                                yield return x;
                            }
                            (a[i], a[k]) = (a[k], a[i]);
                        }
                    }
                }
            }
            return permR(n - 1);
        }

        static void Main(string[] args)
        {
            int[] a = Console.ReadLine().Select(c => c - '0').ToArray();
            foreach (var p in permutations(a)) {
                var x = ulong.Parse(string.Join("", p.Reverse()));
                if (x % 17 == 0) {
                    Console.WriteLine($"{x}");
                    return;
                }
            }
            Console.WriteLine("-1");
        }
    }
}
