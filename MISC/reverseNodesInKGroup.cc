// Reverse Nodes in k-Group (https://leetcode.com/problems/reverse-nodes-in-k-group/)

#include <iostream>

using std::cin, std::cout, std::endl;

// Definition for singly-linked list.
struct ListNode {
    int val;
    ListNode *next;
    ListNode() : val(0), next(nullptr) {}
    ListNode(int x) : val(x), next(nullptr) {}
    ListNode(int x, ListNode *next) : val(x), next(next) {}
};


/******** Begin ********/

// At first I misread the description and thought we also need to reverse the last partial group.
class Solution_ReversePartial {
public:
    ListNode* reverseKGroup(ListNode* head, int k) {
        ListNode** g_last_p = &head;
        ListNode *curr = head, *last;
        while (curr) {
            last = nullptr;
            for (int i = k; i > 0 && curr; i--) {
                ListNode* t = curr->next;
                curr->next = last;
                last = curr;
                curr = t;
            }
            (*g_last_p)->next = curr;
            ListNode** t = &(*g_last_p)->next;
            *g_last_p = last;
            g_last_p = t;
        }
        return head;
    }
};

class Solution {
public:
    ListNode* reverseKGroup(ListNode* head, int k) {
        ListNode** g_last_p = &head;
        ListNode *curr = head, *last;
        while (curr) {
    rollback:
            last = nullptr;
            for (int i = k; i > 0; i--) {
                if (!curr) {
                    curr = last;
                    k -= i;
                    goto rollback;
                }
                ListNode* t = curr->next;
                curr->next = last;
                last = curr;
                curr = t;
            }
            if (curr) (*g_last_p)->next = curr;
            ListNode** t = &(*g_last_p)->next;
            *g_last_p = last;
            g_last_p = t;
        }
        return head;
    }
};

// A recursive solution.
class Solution_LookAhead {
public:
    ListNode* reverseKGroup(ListNode* curr, int k) {
        auto end = curr;
        for (int i=0; i<k; i++) {
            if (!end) {
                return curr;
            }
            end = end->next;
        }

        auto last = Solution_LookAhead::reverseOneGroup(curr, end);
        curr->next = this->reverseKGroup(end, k);;
        return last;
    }

    static ListNode* reverseOneGroup(ListNode* begin, ListNode* end) {
        ListNode* last = nullptr;
        while (begin != end) {
            auto t = begin->next;
            begin->next = last;
            last = begin;
            begin = t;
        }
        return last;
    }
};

/******** End ********/

ListNode* makeList(int n) {
    ListNode* last = nullptr;
    for (int i=n; i>0; i--) {
        last = new ListNode(i, last);
    }
    return last;
}

void printList(ListNode* l) {
    while (l) {
        cout << l->val << ' ';
        l = l->next;
    }
    cout << endl;
}


int main()
{
    int n, k;
    cin >> n >> k;

    auto list = makeList(n);
    printList(list);
    cout << "--------" << endl;

    {
        auto sol = new Solution();
        auto new_list = sol->reverseKGroup(list, k);
        printList(new_list);
    }

    {
        auto list = makeList(n);
        auto sol = new Solution_ReversePartial();
        auto new_list = sol->reverseKGroup(list, k);
        printList(new_list);
    }

    {
        auto list = makeList(n);
        auto sol = new Solution_LookAhead();
        auto new_list = sol->reverseKGroup(list, k);
        printList(new_list);
    }

    cout << endl;
    return 0;
}
