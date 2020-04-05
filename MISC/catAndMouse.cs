// Cat and Mouse (https://leetcode.com/problems/cat-and-mouse/)

using System.Collections.Generic;

enum GameResult
{
    Draw,
    MouseWin,
    CatWin,
}

public class Solution
{
    static (GameResult, GameResult) getMaxMin(int turn)
    {
        return turn switch // 0: Mouse, 1: Cat
        {
            0 => (GameResult.MouseWin, GameResult.CatWin),
            _ => (GameResult.CatWin, GameResult.MouseWin),
        };
    }

    public int CatMouseGame(int[][] graph)
    {
        int n = graph.Length;
        var game = new GameResult[n, n, 2];
        var degrees = new int[n, n, 2]; // out-degrees
        var q = new Queue<(int, int, int)>();

        for (int t = 0; t < 2; t++) {
            game[0, 0, t] = GameResult.MouseWin;
            q.Enqueue((0, 0, t));
            for (int i = 1; i < n; i++) {
                game[0, i, t] = game[i, 0, t] = GameResult.MouseWin;
                game[i, i, t] = GameResult.CatWin;
                foreach (var s in new[] { (0, i, t), (i, 0, t), (i, i, t) }) {
                    q.Enqueue(s);
                }
            }
        }

        for (int m = 1; m < n; m++) {
            for (int c = 1; c < n; c++) {
                degrees[m, c, 0] = graph[m].Length;
                degrees[m, c, 1] = graph[c].Length;
            }
        }

        void f(GameResult cur, int m, int c, int t)
        {
            var (max, min) = getMaxMin(t);
            ref GameResult res = ref game[m, c, t];
            if (res != GameResult.Draw) {
                return;
            } else if (cur == max) {
                res = max;
                q.Enqueue((m, c, t));
            } else { // `cur` cannot be Draw
                if (--degrees[m, c, t] == 0) {
                    res = min;
                    q.Enqueue((m, c, t));
                }
            }
        }

        while (q.Count > 0) {
            var (mouse, cat, turn) = q.Dequeue();
            var cur = game[mouse, cat, turn];
            if ((mouse, cat, turn) == (1, 2, 0)) {
                return (int)cur;
            }

            if (turn == 0) {
                foreach (int c in graph[cat]) {
                    f(cur, mouse, c, 1);
                }
            } else {
                foreach (int m in graph[mouse]) {
                    f(cur, m, cat, 0);
                }
            }
        }

        return (int)GameResult.Draw;
    }
}
