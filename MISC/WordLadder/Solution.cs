using System.Collections.Generic;
using System.Linq;
using StringBuilder = System.Text.StringBuilder;

// https://leetcode.com/problems/word-ladder/

// (!) Failed attempt (Time Limit Exceeded)
public class SolutionTLE {
    private List<string> words;
    private HashSet<int>[] graph;

    private const int SOURCE = 0;
    private int? dest = null;

    int nWords => this.words.Count;

    public int LadderLength(string beginWord, string endWord, IList<string> wordList) {
        buildGraph(beginWord, endWord, wordList);
        return computeLength();
    }

    void buildGraph(string beginWord, string endWord, IList<string> wordList) {
        bool isConnected(int i, int j) {
            int diff = 0;
            foreach (bool b in this.words[i].Zip(this.words[j], (fst, snd) => fst != snd)) {
                diff += b ? 1 : 0;
                if (diff > 1) {
                    return false;
                }
            }
            return diff == 1;
        }

        this.words = new List<string> { beginWord };
        this.words.AddRange(wordList); // `IList` may be of fixed size
        this.graph = Enumerable.Range(0, nWords).Select(_ => new HashSet<int>()).ToArray();
        for (int i = 0; i < nWords; i++) {
            if (this.words[i] == endWord) {
                this.dest = i;
            }
            for (int j = i + 1; j < nWords; j++) {
                if (isConnected(i, j)) {
                    this.graph[i].Add(j);
                    this.graph[j].Add(i);
                }
            }
        }
    }

    int computeLength() {
        int len = 0;
        if (!this.dest.HasValue) {
            return len;
        }

        var qDe = new Queue<int>();
        var qEn = new Queue<int>();
        qDe.Enqueue(SOURCE);

        var visited = new bool[nWords];
        visited[SOURCE] = true;
        while (true) {
            if (qDe.Count == 0) {
                if (qEn.Count == 0) {
                    break;
                }
                (qDe, qEn) = (qEn, qDe);
                len++;
            }

            var head = qDe.Dequeue();
            if (head == this.dest) {
                len++;
                break;
            }

            foreach (var x in this.graph[head]) {
                if (!visited[x]) {
                    qEn.Enqueue(x);
                    visited[head] = true;
                }
            }
        }
        return len;
    }
}

public static class StringExtension {
    public static string SetWildcard(this string s, int i) {
        return new StringBuilder(s) { [i] = '*' }.ToString();
    }
}

public class Solution {
    private Dictionary<string, List<string>> dict;

    public int LadderLength(string beginWord, string endWord, IList<string> wordList) {
        buildGraph(wordList);
        return computeLength(beginWord, endWord);
    }

    void buildGraph(IList<string> wordList) {
        this.dict = new Dictionary<string, List<string>>();
        foreach (string w in wordList) {
            for (int i = 0; i < w.Length; i++) {
                var key = w.SetWildcard(i);
                var stringList = this.dict.GetValueOrDefault(key, new List<string>());
                stringList.Add(w);
                this.dict[key] = stringList;
            }
        }
    }

    int computeLength(string beginWord, string endWord) {
        var q = new Queue<(string, int)>();
        q.Enqueue((beginWord, 1));
        var visited = new HashSet<string> { beginWord };
        while (q.Count > 0) {
            var (h, l) = q.Dequeue();
            if (h.Equals(endWord)) {
                return l;
            }

            for (int i = 0; i < h.Length; i++) {
                List<string> list;
                if (this.dict.TryGetValue(h.SetWildcard(i), out list)) {
                    foreach (var x in list) {
                        if (!visited.Contains(x)) {
                            q.Enqueue((x, l + 1));
                            visited.Add(x);
                        }
                    }
                }
            }
        }
        return 0;
    }
}
