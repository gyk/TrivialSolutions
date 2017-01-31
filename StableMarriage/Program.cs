using System;

namespace ConsoleApplication
{
    public class Program
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

        public static void Main(string[] args)
        {
            int nTestCases = CIO.NextInt();
            for (int i = 0; i < nTestCases; i++) {
                int nMarriages = CIO.NextInt();
                int[][] menPreferences = new int[nMarriages][];

                // The ranks of men for women. It is basically the "inverse" 
                // of preferential list.
                int[][] womenRanks = new int[nMarriages][];

                for (int j = 0; j < nMarriages; j++) {
                    int id = CIO.NextInt() - 1;
                    womenRanks[id] = new int[nMarriages];
                    for (int k = 0; k < nMarriages; k++) {
                        int t = CIO.NextInt() - 1;
                        womenRanks[id][t] = k;
                    }
                }

                for (int j = 0; j < nMarriages; j++) {
                    int id = CIO.NextInt() - 1;
                    menPreferences[id] = new int[nMarriages];
                    for (int k = 0; k < nMarriages; k++) {
                        int t = CIO.NextInt() - 1;
                        menPreferences[id][k] = t;
                    }
                }

                int[] matches = StableMarriage.solve(menPreferences, womenRanks);
                for (int m = 0; m < matches.Length; m++) {
                    Console.WriteLine($"{m + 1} {matches[m] + 1}");
                }
            }
        }
    }
}
