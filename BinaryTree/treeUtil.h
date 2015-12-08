#include <cstdlib>
#include <ctime>
#include <cassert>

#include <string>
#include <iosfwd>
#include <vector>

#include "Tree.h"

using std::vector;
using std::function;

template <typename T>
void printTreeParentheses(std::ostream& ostr, const Tree<T>& tree)
{
    function<void (const TreeNode<T>*)> printTree =
        [&printTree, &ostr](const TreeNode<T>* node)
    {
        if (!node) {
            return;
        }
        ostr << "(";
        printTree(node->left);
        ostr << node->value;
        printTree(node->right);
        ostr << ")";
    };

    printTree(tree.getRoot());
    ostr << '\n';
}

template <typename T>
void printTreeDot(std::ostream& ostr, const Tree<T>& tree)
{
    int nullCount = 0;
    function<void (const T& val)> printNull =
        [&ostr, &nullCount](const T& val)
    {
        ostr << "  null" << nullCount << "[label=\"\\\\0\"];\n";
        ostr << "  " << val << " -> null" << nullCount << ";\n";
        nullCount++;
    };

    function<void (const TreeNode<T>*)> printTree =
        [&](const TreeNode<T>* node)
    {
        if (!node->left && !node->right) {
            return;
        }

        if (node->left) {
            ostr << "  " << node->value << " -> " << node->left->value << ";\n";
            printTree(node->left);
        } else {
            printNull(node->value);
        }

        if (node->right) {
            ostr << "  " << node->value << " -> " << node->right->value << ";\n";
            printTree(node->right);
        } else {
            printNull(node->value);
        }
    };

    nullCount = 0;
    ostr << "digraph BST {\n";
    ostr << "node [fontname=\"Arial\"];\n";
    printTree(tree.getRoot());
    ostr << "}\n";
}

template <typename T>
Tree<T> buildFromTraversals(vector<T>& preOrderSeq, vector<T>& inOrderSeq)
{
    assert(preOrderSeq.size() == inOrderSeq.size());
    int preInd = 0;
    function<TreeNode<T>* (int, int)> parse =
        [&](int inL, int inR) -> TreeNode<T>*
    {
        if (inL > inR) {
            return nullptr;
        }

        T rootVal = preOrderSeq[preInd++];
        TreeNode<T>* node = new TreeNode<T>(rootVal);
        int rootInd;
        for (rootInd=inL; rootInd<=inR; rootInd++) {
            if (inOrderSeq[rootInd] == rootVal) {
                break;
            }
        }
        node->left = parse(inL, rootInd - 1);
        node->right = parse(rootInd + 1, inR);
        return node;
    };

    Tree<T> tree;
    tree.root = parse(0, inOrderSeq.size() - 1);
    int treeSize = 0;
    tree.layerwise([&treeSize](const T&) { treeSize++; });
    tree.nNodes = treeSize;
    return tree;
}
