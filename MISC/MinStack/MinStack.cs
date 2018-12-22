using System.Collections.Generic;

public class MinStack
{
    Stack<int> s;
    Stack<int> minStack;

    public MinStack()
    {
        s = new Stack<int>();
        minStack = new Stack<int>();
    }

    public void Push(int x)
    {
        s.Push(x);

        if (minStack.Count == 0 || x <= minStack.Peek()) {
            minStack.Push(x);
        }
    }

    public void Pop()
    {
        if (minStack.Peek() == s.Peek()) {
            minStack.Pop();
        }
        s.Pop();
    }

    public int Top()
    {
        return s.Peek();
    }

    public int GetMin()
    {
        return minStack.Peek();
    }
}
