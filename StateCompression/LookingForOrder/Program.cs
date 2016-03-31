/*
  Codeforces 8C - Looking for Order
*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace _8C
{
    static class Program
    {
        #region Console IO Helper
        static class CIO
        {
            static string[] tokens = new string[0];
            static int cursor = 0;
            public static int NextInt()
            {
                if (cursor >= tokens.Length) {
                    do {
                        tokens = Console.ReadLine().Split(new[] { ' ', '\t', '\n', '\r' },
                            StringSplitOptions.RemoveEmptyEntries);
                    } while (tokens.Length == 0);
                    cursor = 0;
                }
                return int.Parse(tokens[cursor++]);
            }

            public static void NewLine()
            {
                Console.Write(Environment.NewLine);
            }
        }
        #endregion

        #region Extension Methods
        static int square(int x)
        {
            return x * x;
        }

        static int D(this int[,] coords, int i, int j)
        {
            return
                square(coords[i, 0] - coords[j, 0]) + 
                square(coords[i, 1] - coords[j, 1]) + 
                square(coords[i, 0]) + square(coords[i, 1]) + 
                square(coords[j, 0]) + square(coords[j, 1]);
        }
        #endregion

        static void solve(int[,] coords, out int totalDist, out List<int> path)
        {
            int N = coords.GetLength(0);
            int[,] d = new int[N, N];
            for (int i = 0; i < N; i++) {
                for (int j = 0; j <= i; j++) {
                    d[i, j] = d[j, i] = coords.D(i, j);
                }
            }

            int[] cost = new int[1 << N];
            int[] prev = new int[1 << N];

            for (int i = 1; i < (1 << N); i++) {
                int mask = 0, j;
                for (j = N - 1; j >= 0; j--) {
                    mask = 1 << j;
                    if ((i & mask) != 0) {
                        break;
                    }
                }

                int old = i ^ mask;
                cost[i] = cost[old] + d[j, j];
                prev[i] = old;
                for (int k = j - 1; k >= 0; k--) {
                    mask = 1 << k;
                    if ((old & mask) != 0) {
                        int new_cost = cost[old ^ mask] + d[j, k];
                        if (new_cost < cost[i]) {
                            cost[i] = new_cost;
                            prev[i] = old ^ mask;
                        }
                    }
                }
            }

            int all = (1 << N) - 1;
            totalDist = cost[all];
            path = new List<int>();
            path.Add(0);
            for (int p = all; p != 0; ) {
                int q = prev[p];
                for (int i = N; i > 0; i--) {
                    int m = 1 << (i - 1);
                    if ((p & m) != (q & m)) {
                        path.Add(i);
                    }
                }
                path.Add(0);
                p = q;
            }
            path.Reverse();
        }

        static void Main(string[] args)
        {
            int bagX = CIO.NextInt(), bagY = CIO.NextInt();
            int nObjs = CIO.NextInt();
            var coords = new int[nObjs, 2];
            for (int i = 0; i < nObjs; i++) {
                coords[i, 0] = CIO.NextInt() - bagX;
                coords[i, 1] = CIO.NextInt() - bagY;
            }

            int dist;
            List<int> path;
            Program.solve(coords, out dist, out path);
            Console.Write(dist);
            CIO.NewLine();
            Console.Write(string.Join(" ", path));
            CIO.NewLine();
        }
    }
}
