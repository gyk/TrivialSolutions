#pragma once

#include <cstdlib>
#include <cassert>

#include <stack>
#include <queue>
#include <vector>
#include <functional>

template <typename T>
struct TreeNode
{
    explicit TreeNode(T val) : value(val), left(nullptr), right(nullptr)
    {
    }

    TreeNode(const TreeNode&) = default;

    ~TreeNode()
    {
        delete this->left;
        delete this->right;
    }

    T value;
    TreeNode<T> *left, *right;
};

// Forward declarations
template <typename T>
class Tree;
template <typename T>
Tree<T> buildFromTraversals(std::vector<T>& preOrderSeq, std::vector<T>& inOrderSeq);

template <typename T>
class Tree
{
public:
    Tree();

    ~Tree()
    {
        delete root;
    }

    void insert(const T val);
    const TreeNode<T>* search(const T& val) const;
    void remove(const T& val);
    const TreeNode<T>* getRoot() const;
    size_t size() const;
    void preOrder(std::function<void (T& val)> visitor);
    void inOrder(std::function<void (T& val)> visitor);
    void postOrder(std::function<void (T& val)> visitor);
    void levelOrder(std::function<void (T& val)> visitor);

    friend Tree<T> buildFromTraversals<>
        (std::vector<T>& preOrderSeq, std::vector<T>& inOrderSeq);

private:
    TreeNode<T>* root;
    int nNodes;
};

template <typename T>
Tree<T>::Tree() : root(nullptr), nNodes(0)
{
}

template <typename T>
void Tree<T>::insert(const T val)
{
    auto t = new TreeNode<T>(val);
    TreeNode<T>** pCur = &(this->root);
    for (;;) {
        if (*pCur == nullptr) {
            *pCur = t;
            this->nNodes++;
            return;
        }
        if (val < (*pCur)->value) {
            pCur = &((*pCur)->left);
        } else if (val > (*pCur)->value) {
            pCur = &((*pCur)->right);
        } else {
            return;
        }
    }
}

template <typename T>
const TreeNode<T>* Tree<T>::search(const T& val) const
{
    TreeNode<T>* cur = this->root;
    for (;;) {
        if (cur == nullptr) {
            return nullptr;
        }
        if (val < cur->value) {
            cur = cur->left;
        } else if (val > cur->value) {
            cur = cur->right;
        } else {
            return cur;
        }
    }
}

template <typename T>
void Tree<T>::remove(const T& val)
{
    TreeNode<T>** pCur = &this->root;
    for (;;) {
        auto cur = *pCur;
        if (cur == nullptr) {
            return;
        }

        if (val < cur->value) {
            pCur = &cur->left;
        } else if (val > cur->value) {
            pCur = &cur->right;
        } else {  // target found
            this->nNodes--;
            if (!cur->left && !cur->right) {  // leaf
                delete cur;
                *pCur = nullptr;
                return;
            }

            if (cur->left)  {
                TreeNode<T>** pMid = &cur->left;
                while ((*pMid)->right) {
                    pMid = &(*pMid)->right;
                }
                cur->value = (*pMid)->value;
                auto t = (*pMid)->left;
                // due to TreeNode's recursive destructor
                (*pMid)->left = nullptr;
                assert((*pMid)->right == nullptr);
                delete *pMid;
                *pMid = t;
                return;
            } else {  // cur->right != nullptr
                TreeNode<T>** pMid = &cur->right;
                while ((*pMid)->left) {
                    pMid = &(*pMid)->left;
                }
                cur->value = (*pMid)->value;
                auto t = (*pMid)->right;
                // due to TreeNode's recursive destructor
                (*pMid)->right = nullptr;
                assert((*pMid)->left == nullptr);
                delete *pMid;
                *pMid = t;
                return;
            }
        }
    }
}

template <typename T>
const TreeNode<T>* Tree<T>::getRoot() const
{
    return this->root;
}

template <typename T>
size_t Tree<T>::size() const
{
    return this->nNodes;
}

template <typename T>
void Tree<T>::preOrder(std::function<void (T& val)> visitor)
{
    TreeNode<T>* node = this->root;
    if (!node) {
        return;
    }
    assert(visitor);

    std::stack<TreeNode<T>*> s;
    s.push(node);
    while (!s.empty()) {
        node = s.top();
        s.pop();
        visitor(node->value);

        if (node->right) {
            s.push(node->right);
        }
        if (node->left) {
            s.push(node->left);
        }
    }
}

template <typename T>
void Tree<T>::inOrder(std::function<void (T& val)> visitor)
{
    assert(visitor);
    TreeNode<T>* node = this->root;
    std::stack<TreeNode<T>*> s;
    for (;;) {
        if (node) {  // ignores nullptr by not pushing it
            s.push(node);
            node = node->left;
            continue;
        }

        if (s.empty()) {
            break;
        }
        node = s.top();
        s.pop();
        visitor(node->value);
        node = node->right;
    }
}

// My first attempt to write Tree<T>::postOrder. It involves some 
// cumbersome control flow but is easier to read:

/*
template <typename T>
void Tree<T>::postOrder(std::function<void (T& val)> visitor)
{
    assert(visitor);
    TreeNode<T>* node = this->root;
    std::stack<TreeNode<T>*> s;
    for (;;) {
        if (node) {
            s.push(node);
            node = node->left;
            continue;
        }

        if (s.empty()) {
            break;
        }
    POP:;
        // right should come first to handle leaves
        if (s.top()->right == node) {
            node = s.top();
            s.pop();
            visitor(node->value);
            if (s.empty()) {
                break;
            }
            if (s.top()->right == node) {
                goto POP;
            } else {
                node = s.top()->right;
            }
        } else if (s.top()->left == node) {
            node = s.top()->right;
        }
    }
}

*/

// Here comes the simplified version:
template <typename T>
void Tree<T>::postOrder(std::function<void (T& val)> visitor)
{
    assert(visitor);
    TreeNode<T>* node = this->root;
    std::stack<TreeNode<T>*> s;
    for (;;) {
        while (node) {
            s.push(node);
            node = node->left;
        }

        goto EMPTY;
        while (s.top()->right == node) {
            node = s.top();
            s.pop();
            visitor(node->value);
    EMPTY:
            if (s.empty()) return;
        }
        node = s.top()->right;
    }
}

template <typename T>
void Tree<T>::levelOrder(std::function<void (T& val)> visitor)
{
    TreeNode<T>* root = this->root;
    if (!root) {
        return;
    }
    assert(visitor);

    std::queue<TreeNode<T>*> q;
    q.push(root);
    while (!q.empty()) {
        TreeNode<T>* node = q.front();
        q.pop();
        visitor(node->value);
        if (node->left) {
            q.push(node->left);
        }

        if (node->right) {
            q.push(node->right);
        }
    }
}
