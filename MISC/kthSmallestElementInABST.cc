/*

# Kth Smallest Element in a BST [^1]

Solves the notorious interview question of "k-th smallest/largest element in a BST". According to
_The Horrifically Dystopian World of Software Engineering Interviews_ [^2], anyone fails to solve
it gets rejected by the "Giant Search and Advertising Company" [^3].

[^1]: https://leetcode.com/problems/kth-smallest-element-in-a-bst/
[^2]: https://www.jarednelsen.dev/posts/The-horrifically-dystopian-world-of-software-engineering-interviews
[^3]: It must be Baidu.

*/

class Solution {
public:
    int kthSmallest(TreeNode* root, int k) {
        auto node = this->kthSmallestR(root, k);
        return node ? node->val : 0;
    }
private:
    TreeNode* kthSmallestR(TreeNode* node, int& k) {
        if (node->left) {
            if (auto res = kthSmallestR(node->left, k); res) {
                return res;
            }
        }

        if (--k == 0) { // (!) k is 1-based
            return node;
        }

        if (node->right) {
            if (auto res = kthSmallestR(node->right, k); res) {
                return res;
            }
        }

        return nullptr;
    }
};
