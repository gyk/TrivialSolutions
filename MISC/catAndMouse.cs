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
    public int CatMouseGame(int[][] graph)
    {
        int n = graph.Length;
        var mem = new GameResult[n, n, 2]; // 0: Mouse, 1: Cat
        var degrees = new int[n, n, 2]; // out-degrees
        var q = new Queue<(int, int, int)>();

        for (int i = 1; i < n; i++) {
            mem[0, i, 0] = mem[0, i, 1] = GameResult.MouseWin;
            mem[i, i, 0] = mem[i, i, 1] = GameResult.CatWin;
            foreach (var s in new[] { (0, i, 0), (0, i, 1), (i, i, 0), (i, i, 1) }) {
                q.Enqueue(s);
            }
        }

        for (int m = 1; m < n; m++) {
            for (int c = 1; c < n; c++) {
                degrees[m, c, 0] = graph[m].Length;
                degrees[m, c, 1] = graph[c].Length;
            }
        }
        foreach (int c in graph[0]) { // undirected graph
            for (int m = 0; m < n; m++) {
                degrees[m, c, 1]--; // cat can't go to 0
            }
        }

        while (q.Count > 0) {
            var (mouse, cat, turn) = q.Dequeue();
            var cur = mem[mouse, cat, turn];

            if (turn == 0) {
                foreach (int c in graph[cat]) {
                    if (c == 0) {
                        continue;
                    }
                    ref GameResult res = ref mem[mouse, c, 1];
                    if (res != GameResult.Draw) {
                        continue;
                    } else if (cur == GameResult.CatWin) {
                        res = GameResult.CatWin;
                        q.Enqueue((mouse, c, 1));
                    } else { // `cur` cannot be Draw
                        if (--degrees[mouse, c, 1] == 0) {
                            res = GameResult.MouseWin;
                            q.Enqueue((mouse, c, 1));
                        }
                    }
                }
            } else {
                foreach (int m in graph[mouse]) {
                    ref GameResult res = ref mem[m, cat, 0];
                    if (res != GameResult.Draw) {
                        continue;
                    } else if (cur == GameResult.MouseWin) {
                        res = GameResult.MouseWin;
                        q.Enqueue((m, cat, 0));
                    } else { // `cur` cannot be Draw
                        if (--degrees[m, cat, 0] == 0) {
                            res = GameResult.CatWin;
                            q.Enqueue((m, cat, 0));
                        }
                    }
                }
            }
        }

        return (int)mem[1, 2, 0];
    }
}
