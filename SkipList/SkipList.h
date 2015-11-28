#pragma once

#include <cstdlib>
#include <ctime>
#include <vector>
#include <string>

template <typename T>
struct SkNode
{
    SkNode(size_t maxNLayers)
    : item(T())
    , next(std::vector<SkNode<T>*>(maxNLayers, nullptr))
    {
    }

    SkNode(size_t maxNLayers, T value) : item(value)
    {
        // The node has the probability of 1/b^n to contain (n+1) layers.
        size_t i, b;
        for (i=1, b=2; i<=maxNLayers; i++, b+=b) {
            if (std::rand() * b > RAND_MAX) {
                break;
            }
        }
        next = std::move(std::vector<SkNode<T>*>(i, nullptr));
    };

    ~SkNode() = default;

    size_t getNumLayers()
    {
        return this->next.size();
    }

    std::vector<SkNode<T>*> next;
    T item;
};

// Forward declarations
template <typename T>
class SkipList;
template <typename T>
void printSkipList(SkipList<T>* that);
template <typename T>
std::vector<int> numLayersStat(SkipList<T>* that);

template <typename T>
class SkipList
{
public:
    explicit SkipList(size_t maxNLayers = 10);
    SkipList(const SkipList<T>& sk) = delete;
    ~SkipList();

    void insert(T value);
    void remove(T value);
    SkNode<T>* search(T value);

    friend void printSkipList <>(SkipList<T>* that);
    friend std::vector<int> numLayersStat <>(SkipList<T>* that);

private:
    void insertR(SkNode<T>* node, SkNode<T>* n, size_t k);
    void removeR(SkNode<T>* node, T value, size_t k);
    SkNode<T>* searchR(SkNode<T>* node, T value, size_t k);
    size_t maxNLayers;
    SkNode<T>* head;
};

template <typename T>
SkipList<T>::SkipList(size_t maxNLayers)
    : maxNLayers(maxNLayers)
    , head(new SkNode<T>(this->maxNLayers))
{
    std::srand(static_cast<unsigned int>(std::time(nullptr)));
}

template <typename T>
SkipList<T>::~SkipList()
{
    for (SkNode<T>* n = head; n;) {
        SkNode<T>* t = n;
        n = n->next[0];
        delete t;
    }
}

// Insert
template <typename T>
void SkipList<T>::insert(T value)
{
    auto x = new SkNode<T>(this->maxNLayers, value);
    insertR(head, x, maxNLayers - 1);
}

template <typename T>
void SkipList<T>::insertR(SkNode<T>* node, SkNode<T>* n, size_t k)
{
    auto x = node->next[k];
    if (!x || n->item < x->item) {
        if (k < n->getNumLayers()) {
            n->next[k] = x;
            node->next[k] = n;
        }
        if (k > 0) {
            insertR(node, n, k - 1);
        }
    } else if (n->item == x->item) {  // duplicate
        return;
    } else {
        insertR(x, n, k);
    }
}

// Remove
template <typename T>
void SkipList<T>::remove(T value)
{
    removeR(head, value, maxNLayers - 1);
}

template <typename T>
void SkipList<T>::removeR(SkNode<T>* node, T value, size_t k)
{
    auto x = node->next[k];
    if (!x || value < x->item) {
        if (k == 0) {
            return;
        }
        return removeR(node, value, k - 1);
    } else if (value == x->item) {
        node->next[k] = x->next[k];
        if (k == 0) {
            delete x;
        } else {
            removeR(node, value, k - 1);
        }
    } else {
        return removeR(x, value, k);
    }
}

// Search
template <typename T>
SkNode<T>* SkipList<T>::search(T value)
{
    return searchR(head, value, maxNLayers - 1);
}

template <typename T>
SkNode<T>* SkipList<T>::searchR(SkNode<T>* node, T value, size_t k)
{
    auto x = node->next[k];
    if (!x || value < x->item) {
        if (k == 0) {
            return nullptr;
        }
        return searchR(node, value, k - 1);
    } else if (value == x->item) {
        return x;
    } else {
        return searchR(x, value, k);
    }
}
