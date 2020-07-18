// House Robber

using System;
using System.Linq; // Sum

// https://leetcode.com/problems/house-robber/
public class SolutionLine {
    public int Rob(int[] nums) {
        var (no, yes) = (0, 0);
        for (int i = 0; i < nums.Length; i++) {
            (no, yes) = (Math.Max(no, yes), no + nums[i]);
        }
        return Math.Max(no, yes);
    }
}


// https://leetcode.com/problems/house-robber-ii/
public class SolutionCircle {
    public int Rob(int[] nums) {
        if (nums.Length <= 1) {
            return nums.Sum();
        }

        var no = new int[2];
        var yes = new int[2] { 0, nums[0] };
        for (int i = 1; i < nums.Length; i++) {
            for (int k = 0; k < 2; k++) {
                (no[k], yes[k]) = (Math.Max(no[k], yes[k]), no[k] + nums[i]);
            }
        }
        return Math.Max(no[1], yes[0]);
    }
}


// https://leetcode.com/problems/house-robber-iii/
public class TreeNode {
    public int val;
    public TreeNode left;
    public TreeNode right;
    public TreeNode(int val=0, TreeNode left=null, TreeNode right=null) {
        this.val = val;
        this.left = left;
        this.right = right;
    }
}

public class SolutionTree {
    public int Rob(TreeNode root) {
        return this.robR(root).Max();
    }

    int[] robR(TreeNode node) { // 0: no, 1: yes
        if (node == null) {
            return new int[2];
        }

        var l = this.robR(node.left);
        var r = this.robR(node.right);
        return new [] { l.Max() + r.Max(), node.val + l[0] + r[0] };
    }
}

// A simpler yet slower solution
public class SolutionTree2 {
    public int Rob(TreeNode node) {
        if (node == null) {
            return 0;
        }
        return Math.Max(node.val + robX(node.left) + robX(node.right), robX(node));
    }

    int robX(TreeNode node) {
        if (node == null) {
            return 0;
        }
        return Rob(node.left) + Rob(node.right);
    }
}
