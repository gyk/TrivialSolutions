// Domino (https://codeforces.com/contest/97/problem/A)

using System;
using System.Linq;

namespace Domino
{
    class Program
    {
        static readonly int[] BASES = new int[] { 13, 11, 9, 7, 5, 3, 1 }; // 13!!
        static readonly int N_MAPPINGS = BASES.Aggregate(1, (a, b) => a * b);

        static int[] numToMapping(int n)
        {
            int?[] mapping = new int?[14];
            int m = 0;
            for (int i = 0; i < 14; i++) {
                if (mapping[i].HasValue) {
                    continue;
                }
                mapping[i] = m;

                int r = n % BASES[m];
                n /= BASES[m];
                for (int j = i + 1; j < 14; j++) {
                    if (mapping[j].HasValue) {
                        continue;
                    }
                    if (r-- == 0) {
                        mapping[j] = m;
                        break;
                    }
                }
                m++;
            }
            return Array.ConvertAll(mapping, x => x.Value);
        }

        static void solve(char[][] field)
        {
            var (n, m) = (field.Length, field[0].Length);
            int?[][] block = field.Select(x => x.Select(_ => (int?)null).ToArray()).ToArray();
            var domino = new (int?, int?)[28];

            void assignDomino(int i, int b)
            {
                if (!domino[i].Item1.HasValue) {
                    domino[i].Item1 = b;
                } else {
                    domino[i].Item2 = b;
                }
            }

            bool verify(int[] mapping)
            {
                var check = new bool[7, 7];
                for (int d = 0; d < 28; d++) {
                    var (b1, b2) = domino[d];
                    var (m1, m2) = (mapping[b1.Value], mapping[b2.Value]);
                    (m1, m2) = m1 > m2 ? (m2, m1) : (m1, m2);
                    if (check[m1, m2]) {
                        return false;
                    }
                    check[m1, m2] = true;
                }
                return true;
            }

            int iBlock = 0;
            for (int r = 0; r < n; r++) {
                for (int c = 0; c < m; c++) {
                    if (field[r][c] != '.') {
                        if (!block[r][c].HasValue) {
                            block[r][c] =
                            block[r][c + 1] =
                            block[r + 1][c] =
                            block[r + 1][c + 1] = iBlock++;
                        }

                        int iDomino = field[r][c];
                        if (iDomino == 'A') iDomino = 26;
                        else if (iDomino == 'B') iDomino = 27;
                        else iDomino -= 'a';

                        assignDomino(iDomino, block[r][c].Value);
                    }
                }
            }

            int count = 0;
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < N_MAPPINGS; i++) {
                var mapping = numToMapping(i);
                if (verify(mapping)) {
                    count++;
                    if (count == 1) {
                        for (int r = 0; r < n; r++) {
                            for (int c = 0; c < m; c++) {
                                if (block[r][c] is int b) {
                                    sb.AppendFormat("{0}", mapping[b]);
                                } else {
                                    sb.Append('.');
                                }

                            }
                            sb.Append(System.Environment.NewLine);
                        }
                    }
                }
            }

            Console.WriteLine($"{count * 5040}");
            Console.Write($"{sb}");
        }

        static void Main(string[] args)
        {
            int[] nm = Console.ReadLine().Split().Select(x => int.Parse(x)).ToArray();
            int n = nm[0];
            int m = nm[1];
            char[][] field = new char[n][];
            for (int i = 0; i < n; i++) {
                field[i] = Console.ReadLine().ToCharArray();
            }
            solve(field);
        }
    }
}
