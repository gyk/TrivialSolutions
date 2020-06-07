// Binary Tree Zigzag Level Order Traversal
// (https://leetcode.com/problems/binary-tree-zigzag-level-order-traversal)

using System.Collections.Generic;
using System.Linq;

public class TreeNode {
    public int val;
    public TreeNode left;
    public TreeNode right;
    public TreeNode(int x) { val = x; }
}

public class Solution {
    public IList<IList<int>> ZigzagLevelOrder(TreeNode root) {
        var res = new List<IList<int>>();
        var s = Enumerable.Range(0, 2).Select(_ => new Stack<TreeNode>()).ToArray();
        if (root != null) {
            s[0].Push(root);
        }

        for (int i = 0; s[i].Count > 0; i = 1 - i) {
            var level = new List<int>();
            res.Add(level);
            do {
                var node = s[i].Pop();
                level.Add(node.val);

                var (fst, snd) = i == 0 ? (node.left, node.right) : (node.right, node.left);
                if (fst != null) {
                    s[1 - i].Push(fst);
                }
                if (snd != null) {
                    s[1 - i].Push(snd);
                }
            } while (s[i].Count > 0);
        }
        return res;
    }
}
