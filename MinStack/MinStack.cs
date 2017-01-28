using System.Collections.Generic;

public class MinStack
{
    List<int> proxy;
    Stack<int> minIndexSoFar;
    int currMin;

    public MinStack()
    {
        proxy = new List<int>();
        minIndexSoFar = new Stack<int>();

        proxy.Add(int.MaxValue);
        minIndexSoFar.Push(0);
    }

    public void Push(int x)
    {
        proxy.Add(x);

        int currMinIndex = minIndexSoFar.Peek();
        int currMin = proxy[currMinIndex];
        if (x < currMin) {
            minIndexSoFar.Push(currentIndex);
        } else {
            minIndexSoFar.Push(currMinIndex);
        }
    }

    public void Pop()
    {
        if (isEmpty) {
            throw new System.InvalidOperationException();
        }

        proxy.RemoveAt(currentIndex);
        minIndexSoFar.Pop();
    }

    public int Top()
    {
        if (isEmpty) {
            throw new System.InvalidOperationException();
        }

        return proxy[currentIndex];
    }

    public int GetMin()
    {
        if (isEmpty) {
            throw new System.InvalidOperationException();
        }

        return proxy[minIndexSoFar.Peek()];
    }

    public bool isEmpty
    {
        get
        {
            return proxy.Count == 1;
        }
    }

    private int currentIndex
    {
        get
        {
            return proxy.Count - 1;
        }
    }
}
