// String Compression (https://leetcode.com/problems/string-compression/)

class Solution {
    func compress(_ chars: inout [Character]) -> Int {
        var last: Character = chars[0]
        var i = 0
        var cnt = 0

        func push(_ c: Character) {
            chars[i] = c
            i += 1
        }

        for ch in [chars, ["\0"]].joined() {
            if ch == last {
                cnt += 1
            } else {
                push(last)
                if cnt > 1 {
                    String(cnt).forEach { push($0) }
                }
                last = ch
                cnt = 1
            }
        }

        return i
    }
}
