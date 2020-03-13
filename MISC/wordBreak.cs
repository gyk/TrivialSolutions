using System.Collections.Generic;

public class Solution
{
    public IList<string> WordBreak(string s, IList<string> wordDict)
    {
        var cache = new Dictionary<string, List<string>> { [""] = new List<string> { "" } };
        IEnumerable<string> wordBreakImpl(string s)
        {
            if (cache.TryGetValue(s, out List<string> xsCached)) {
                foreach (string x in xsCached) {
                    yield return x;
                }
            } else {
                foreach (string w in wordDict) {
                    if (s.StartsWith(w)) {
                        string newS = s[w.Length..];
                        var xs = new List<string>(wordBreakImpl(newS));
                        cache[newS] = xs;
                        foreach (string x in xs) {
                            yield return x == "" ? w : w + " " + x;
                        }
                    }
                }
            }
        }
        return new List<string>(wordBreakImpl(s));
    }
}
