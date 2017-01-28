using static System.Console;

namespace LeetCode
{
    public class Program
    {
        public static void Main(string[] args)
        {
            MinStack minStack = new MinStack();
            minStack.Push(-2);
            minStack.Push(0);
            minStack.Push(-3);
            WriteLine($"Min = {minStack.GetMin()}");
            minStack.Pop();
            WriteLine($"Min = {minStack.Top()}");
            WriteLine($"Min = {minStack.GetMin()}");
        }
    }
}
