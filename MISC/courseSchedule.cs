// Course Schedule II (https://leetcode.com/problems/course-schedule-ii/)

using System.Collections.Generic;
using System.Linq;

using Graph = System.Collections.Generic.Dictionary<int, System.Collections.Generic.HashSet<int>>;

public class Solution_DFS {
    enum Color
    {
        White,
        Gray,
        Black,
    }

    public int[] FindOrder(int numCourses, int[][] prerequisites) {
        var graph = Enumerable.Range(0, numCourses).Select(_ => new List<int>()).ToArray();
        foreach (var fromTo in prerequisites) {
            graph[fromTo[0]].Add(fromTo[1]);
        }

        var topoOrder = new List<int>();
        bool cycleDetected = false;
        var visited = new Color[numCourses];
        for (int i = 0; i < numCourses; i++) {
            dfs(i);
        }

        void dfs(int fromV) {
            if (cycleDetected || visited[fromV] == Color.Black) {
                return;
            } else if (visited[fromV] == Color.Gray) {
                cycleDetected = true;
                return;
            }

            visited[fromV] = Color.Gray;
            foreach (var toV in graph[fromV]) {
                dfs(toV);
            }
            visited[fromV] = Color.Black;
            topoOrder.Add(fromV);
        }

        return cycleDetected ? new int[] {} : topoOrder.ToArray();
    }
}

public class Solution_Kahn {
    public int[] FindOrder(int numCourses, int[][] prerequisites) {
        var g = new Graph();
        var gR = new Graph();

        static void insert(Graph graph, int fromV, int toV) {
            HashSet<int> edges;
            if (!graph.TryGetValue(fromV, out edges)) {
                edges = new HashSet<int>();
                graph[fromV] = edges;
            }
            edges.Add(toV);
        }

        var roots = new HashSet<int>(Enumerable.Range(0, numCourses)); // vertices with no in-edges
        foreach (var fromTo in prerequisites) {
            var fromV = fromTo[0];
            var toV = fromTo[1];
            insert(g, fromV, toV);
            insert(gR, toV, fromV);
            roots.Remove(toV);
        }

        var topoOrder = new List<int>(roots);
        while (roots.Count > 0) {
            var x = roots.First();
            roots.Remove(x);
            if (!g.ContainsKey(x)) {
                continue;
            }
            foreach (var y in g[x]) {
                if (gR.ContainsKey(y)) {
                    gR[y].Remove(x);
                    if (gR[y].Count == 0) {
                        topoOrder.Add(y);
                        roots.Add(y);
                    }
                }
            }
            g.Remove(x);
        }

        if (g.Count != 0) {
            return new int[] {}; // Cycle detected
        } else {
            topoOrder.Reverse();
            return topoOrder.ToArray();
        }
    }
}
