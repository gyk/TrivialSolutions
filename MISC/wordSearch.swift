// Word Search II (https://leetcode.com/problems/word-search-ii/)

class Trie {
    var s: String?
    var children: [Character : Trie]

    init(_ word: String? = nil) {
        self.s = word
        self.children = [:]
    }

    func insert(_ word: String) {
        var curr = self
        for c in word {
            curr.children[c] = curr.children[c, default: Trie()]
            curr = curr.children[c]!
        }
        curr.s = word
    }
}

class Solution {
    func findWords(_ board: [[Character]], _ words: [String]) -> [String] {
        let (nr, nc) = (board.count, board[0].count)
        var wordTrie = Trie()
        for w in words {
            wordTrie.insert(w)
        }

        var visited = (0 ..< nr).map { _ in (0 ..< nc).map { _ in false } }
        var trie = wordTrie
        var found = Set<String>()

        func go(_ r: Int, _ c: Int) {
            guard !visited[r][c] else { return }

            visited[r][c] = true
            defer { visited[r][c] = false }

            let oldTrie = trie
            guard let newTrie = trie.children[board[r][c]] else { return }
            trie = newTrie
            defer { trie = oldTrie }

            if let s = trie.s {
                found.insert(s)
            }

            guard !trie.children.isEmpty else { return }
            [(r - 1, c), (r, c + 1), (r + 1, c), (r, c - 1)]
                .filter { (r, c) in 0 ..< nr ~= r && 0 ..< nc ~= c }
                .forEach { (r, c) in go(r, c) }
        }

        for r in 0 ..< nr {
            for c in 0 ..< nc {
                go(r, c)
            }
        }

        return Array(found)
    }
}
