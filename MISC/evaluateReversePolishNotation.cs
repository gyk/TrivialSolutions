// Evaluate Reverse Polish Notation (https://leetcode.com/problems/evaluate-reverse-polish-notation/)

using System;
using System.Collections.Generic;

public class Solution {
    public int EvalRPN(string[] tokens) {
        var s = new Stack<int>();
        Func<int, int, int> div = (a, b) => b / a;
        foreach (string t in tokens) {
            int res = t switch {
                "+" => s.Pop() + s.Pop(),
                "-" => -s.Pop() + s.Pop(),
                "*" => s.Pop() * s.Pop(),
                "/" => div(s.Pop(), s.Pop()),
                _ => int.Parse(t),
            };
            s.Push(res);
        }
        return s.Pop();
    }
}
