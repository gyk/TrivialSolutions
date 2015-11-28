#include <cstdlib>
#include <cstdio>

#include <map>
#include <vector>

#include "SkipList.h"

using std::map;
using std::vector;
using std::printf;

template <>
void printSkipList(SkipList<int>* that)
{
    map<SkNode<int>*, int> nodeMap;
    size_t nColumns = 0;
    for (
        SkNode<int>* n = that->head;
        n;
        n = n->next[0], nColumns++
    ) {
        nodeMap[n] = nColumns;
    }

    vector<vector<SkNode<int>*>> skArr(that->maxNLayers, vector<SkNode<int>*>(nColumns, nullptr));

    for (size_t i=0; i<that->maxNLayers; i++) {
        SkNode<int>* n = that->head;
        if (!n->next[i]) {
            // removes all the empty lines: i, i+1, ..., end
            skArr.resize(i);
            break;
        }

        for ( ; n; n=n->next[i]) {
            skArr[i][nodeMap[n]] = n;
        }
    }

    for (size_t i=skArr.size(); i-->0; ) {  // Be aware of size_t
        printf("*----");  // prints header
        for (size_t j=1; j<nColumns; j++) {
            SkNode<int>* n = skArr[i][j];
            if (n) {
                printf("%4d----", n->item);
            } else {
                printf("--------");
            }
        }
        printf("\n");
    }
}

template <>
std::vector<int> numLayersStat(SkipList<int>* that)
{
    std::vector<int> histo(that->maxNLayers + 1, 0);
    for (SkNode<int>* node = that->head; node; node = node->next[0]) {
        histo[node->getNumLayers()]++;
    }
    return histo;
}
