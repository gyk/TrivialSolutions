#include <cstdlib>
#include <ctime>
#include <cassert>

#include <algorithm>
#include <vector>
#include <iostream>
#include <sstream>

#include "Tree.h"
#include "treeUtil.h"

using std::swap;
using std::vector;
using std::cout;
using std::ostringstream;

vector<int> randomInts(size_t n)
{
    static bool initialized = false;
    if (!initialized) {
        std::srand(static_cast<unsigned>(std::time(nullptr)));
        initialized = true;
    }

    vector<int> data;
    while (n--) {
        data.push_back(std::rand() % 500);
    }

    return data;
}

template <typename C>
void printContainer(const C& c)
{
    for (auto& v : c) {
        cout << v << ' ';
    }
    cout << '\n';
}

int main()
{
    Tree<int> tree;
    cout << "Insert into the tree:\n";
    auto rndVec = randomInts(15);
    printContainer(rndVec);
    for (auto& v : rndVec) {
        tree.insert(v);
    }

    // Test removal of tree nodes
    printTreeParentheses(cout, tree);
    cout << "Remove random items from the tree:\n";
    std::random_shuffle(rndVec.begin(), rndVec.end());
    for (auto& v : rndVec) {
        tree.remove(v);
        printTreeParentheses(cout, tree);
    }
    assert(tree.size() == 0 && tree.getRoot() == nullptr);

    cout << "Insert into the empty tree:\n";
    rndVec = randomInts(20);
    printContainer(rndVec);
    for (auto& v : rndVec) {
        tree.insert(v);
    }

    cout << "#nodes = " << tree.size() << "\n";
    cout << "Print tree:\n";
    printTreeParentheses(cout, tree);
    cout << "\n";

    cout << "Insert more nodes into the tree:\n";
    rndVec = randomInts(5);
    for (auto& v : rndVec) {
        tree.insert(v);
    }
    printContainer(rndVec);
    cout << "#nodes = " << tree.size() << "\n";
    cout << "After insertion:\n";
    cout << "----\n";
    printTreeDot(cout, tree);
    cout << "----\n";
    assert(tree.search(rndVec[0])->value == rndVec[0]);

    int accum = 0;
    auto sumFunc = [&accum](int& v)
        {
            accum += v;
        };

    tree.inOrder(sumFunc);
    cout << "Sum of nodes: " << accum << "\n";
    cout << "\n================\n";

    // Test tree traversal
    vector<int> preOrderSeq, inOrderSeq, postOrderSeq, layerSeq;
    vector<int> tempSeq;
    auto visitor = [&tempSeq](int& v) { tempSeq.push_back(v); };

    cout << "Pre-order traversal:\n";
    tree.preOrder(visitor);
    swap(tempSeq, preOrderSeq);
    printContainer(preOrderSeq);

    cout << "In-order traversal:\n";
    tree.inOrder(visitor);
    swap(tempSeq, inOrderSeq);
    printContainer(inOrderSeq);

    cout << "Post-order traversal:\n";
    tree.postOrder(visitor);
    swap(tempSeq, postOrderSeq);
    printContainer(postOrderSeq);

    cout << "Layerwise traversal:\n";
    tree.layerwise(visitor);
    swap(tempSeq, layerSeq);
    printContainer(layerSeq);

    // Test reconstructing tree
    auto tree2 = buildFromTraversals(preOrderSeq, inOrderSeq);
    ostringstream oss;
    printTreeParentheses(oss, tree);
    ostringstream oss2;
    printTreeParentheses(oss2, tree2);
    assert(oss.str() == oss2.str());
    cout << "DONE\n";

    return 0;
}
