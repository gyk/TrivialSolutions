#include <unordered_map>
#include <string>

struct RandomListNode {
    int label;
    RandomListNode *next, *random;
    RandomListNode(int x) : label(x), next(NULL), random(NULL) {}
};

class Solution {
public:
    RandomListNode *copyRandomList(RandomListNode *header) {
        if (!header) { return nullptr; }

        // two lists chained together
        for (auto *src=header; src; ) {
            auto node = new RandomListNode(src->label);
            node->random = src->random;

            node->next = src->next;
            src->next = node;
            src = node->next;
        }

        // resets the random link of the new list
        for (auto p=header; p; ) {
            p = p->next;
            if (p->random) {
                p->random = p->random->next;
            }
            p = p->next;
        }

        // separates two lists
        RandomListNode* ret = nullptr;
        auto p_dst = &ret;
        for (auto src=header; src; src=src->next) {
            *p_dst = src->next;
            p_dst = &src->next->next;
            src->next = *p_dst;
        }

        return ret;
    }

    // Another implementation, based on `map`
    RandomListNode *copyRandomList_map(RandomListNode *header) {
        RandomListNode *src = header;
        RandomListNode* dst = nullptr;
        auto p_dst = &dst;
        std::unordered_map<RandomListNode*, RandomListNode*> src_to_dst;
        src_to_dst[nullptr] = nullptr;
        while (src) {
            auto node = new RandomListNode(src->label);
            node->random = src->random;
            src_to_dst[src] = node;
            *p_dst = node;
            p_dst = &node->next;
            src = src->next;
        }

        auto ret = dst;
        while (dst) {
            dst->random = src_to_dst[dst->random];
            dst = dst->next;
        }
        return ret;
    }
};

int main(int argc, char const *argv[])
{
    // smoke testing
    Solution sol;
    RandomListNode* arena[10 + 1] = { nullptr };
    for (int i=0; i<10; i++) {
        arena[i] = new RandomListNode(i);
    }

    // link
    for (
        auto p = arena;
        *(++p);
        p[-1]->next = *p
    );

    arena[0]->random = arena[2];
    arena[2]->random = arena[3];
    arena[4]->random = arena[9];
    arena[5]->random = arena[7];
    arena[7]->random = arena[8];


    RandomListNode* dst = sol.copyRandomList(arena[0]);
    RandomListNode* dst_map = sol.copyRandomList_map(arena[0]);

    // print
    auto print_list = [](RandomListNode* q) {
        for (; q; q=q->next) {
            printf("node %d, next = %s, random = %s\n",
                q->label,
                q->next ? std::to_string(q->next->label).c_str() : "N/A",
                q->random ? std::to_string(q->random->label).c_str() : "N/A");
        }
    };

    print_list(dst);
    puts("");
    print_list(dst_map);

    return 0;
}
