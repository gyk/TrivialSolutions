// Linked List Cycle
//
// - https://leetcode.com/problems/linked-list-cycle/
// - https://leetcode.com/problems/linked-list-cycle-ii/

using System;
using System.Collections.Generic;

public class ListNode
{
    public int val;
    public ListNode next;
    public ListNode(int x)
    {
        val = x;
        next = null;
    }

    public static ListNode MakeList(IList<int> list, int pos)
    {
        ListNode node = pos == -1 ? null : new ListNode(0);
        ListNode loop = node;
        for (int i = list.Count - 1; i >= 0; i--) {
            ListNode newNode;
            if (i == pos) {
                loop.val = list[i];
                newNode = loop;
            } else {
                newNode = new ListNode(list[i]);
            }

            newNode.next = node;
            node = newNode;
        }
        return node;
    }

    public void PrintDot()
    {
        var dict = new Dictionary<ListNode, int>();
        Console.WriteLine(
@"digraph g {
  rankdir=LR;
");
        var curr = this;
        for (int i = 0; curr != null; i++) {
            if (dict.TryGetValue(curr, out int iOld)) {
                Console.WriteLine($"  {i - 1} -> {iOld}");
                break;
            }
            if (i > 0) {
                Console.WriteLine($"  {i - 1} -> {i}");
            }
            Console.WriteLine($"  {i} [label={curr.val}]");
            dict[curr] = i;
            curr = curr.next;
        }
        Console.WriteLine(@"}");
    }
}

public class Solution
{
    static bool run(ref ListNode node)
    {
        if (node == null || node.next == null) {
            return false;
        }
        node = node.next;
        return true;
    }

    public bool HasCycle(ListNode head)
    {
        var tortoise = head;
        var hare = head;
        while (run(ref tortoise) && run(ref hare) && run(ref hare)) {
            if (tortoise == hare) {
                return true;
            }
        }
        return false;
    }

    public ListNode DetectCycle(ListNode head)
    {
        var tortoise = head;
        var hare = head;
        while (run(ref tortoise) && run(ref hare) && run(ref hare)) {
            if (tortoise == hare) {
                // Let `n` be position of the node where the cycle begins, `m` be the length of the
                // circle. Set the node where the cycle begins as the origin. Tortoise and hare
                // start at `-n` and meet at `m - n % m`. The strategy here makes sure tortoise and
                // fox finally meet at `0 % m`.
                var fox = head;
                while (fox != tortoise) {
                    run(ref tortoise);
                    run(ref fox);
                }
                return fox;
            }
        }
        return null;
    }
}
