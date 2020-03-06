using System;
using System.Collections.Generic;

namespace WordLadder
{
    class Program
    {
        static void Main(string[] args)
        {
            {
                var beginWord = "hit";
                var endWord = "cog";
                var wordList = new List<string> { "hot","dot","dog","lot","log","cog" };
                var sol1 = new SolutionTLE();
                var sol2 = new Solution();
                Console.WriteLine(sol1.LadderLength(beginWord, endWord, wordList));
                Console.WriteLine(sol2.LadderLength(beginWord, endWord, wordList));
            }

            {
                var beginWord = "hit";
                var endWord = "cog";
                var wordList = new List<string> { "hot","dot","dog","lot","log" };
                var sol1 = new SolutionTLE();
                var sol2 = new Solution();
                Console.WriteLine(sol1.LadderLength(beginWord, endWord, wordList));
                Console.WriteLine(sol2.LadderLength(beginWord, endWord, wordList));
            }
        }
    }
}
